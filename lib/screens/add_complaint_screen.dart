import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../utils/map_checker.dart';

class AddComplaintScreen extends StatefulWidget {
  const AddComplaintScreen({super.key});

  @override
  State<AddComplaintScreen> createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  String? _category;
  bool _isLoading = false;
  bool _isAnonymous = false;

  // Cloudinary Photo Attachment State
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Map & Location State
  LatLng? _selectedLocation;
  bool _isFetchingLocation = false;
  GoogleMapController? _mapController;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImageToCloudinary(XFile imageFile) async {
    try {
      const cloudName = 'civicease1';
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final bytes = await imageFile.readAsBytes();

      String format = 'jpeg';
      final lowerName = imageFile.name.toLowerCase();
      if (lowerName.endsWith('.webp')) format = 'webp';
      else if (lowerName.endsWith('.png')) format = 'png';
      else if (lowerName.endsWith('.gif')) format = 'gif';

      // Try unsigned Cloudinary presets
      final presets = ['civicease_preset', 'ml_default', 'unsigned_preset', 'unsigned'];
      for (final preset in presets) {
        try {
          final request = http.MultipartRequest('POST', uri);
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: imageFile.name.isNotEmpty ? imageFile.name : 'complaint_photo.$format',
          ));
          request.fields['upload_preset'] = preset;

          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200 || response.statusCode == 201) {
            final responseData = jsonDecode(response.body);
            final String? uploadedUrl = responseData['secure_url'] ?? responseData['url'];
            if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
              return uploadedUrl;
            }
          }
        } catch (_) {}
      }

      // Reliable Fallback: Encode as Base64 Data URI if Cloudinary presets are missing
      debugPrint('Cloudinary preset error: falling back to base64 Data URI');
      final base64Content = base64Encode(bytes);
      return 'data:image/$format;base64,$base64Content';
    } catch (e) {
      debugPrint('Photo upload exception: $e');
    }
    return null;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable GPS.')),
          );
        }
        setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied.')),
          );
        }
        setState(() => _isFetchingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLatLng;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));

      // Attempt reverse geocoding to auto-fill address if empty
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final String autoAddress = [
            p.name,
            p.street,
            p.subLocality,
            p.locality,
            p.postalCode
          ].where((e) => e != null && e.isNotEmpty && e != p.name).join(', ');

          if (_addressController.text.isEmpty && autoAddress.isNotEmpty) {
            _addressController.text = autoAddress;
          }
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current location acquired!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _submitComplaint() async {
    if (_category == null || 
        _titleController.text.isEmpty || 
        _descriptionController.text.isEmpty || 
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to submit a complaint')),
        );
        context.go('/login');
        return;
      }

      // Upload image to Cloudinary if selected
      String? photoUrl;
      if (_selectedImage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading photo to Cloudinary...')),
          );
        }
        photoUrl = await _uploadImageToCloudinary(_selectedImage!);
      }

      // Get user data for non-anonymous complaints
      String? userName;
      if (!_isAnonymous) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        userName = userDoc.data()?['name'];
      }

      Map<String, dynamic> complaintData = {
        'title': _titleController.text,
        'category': _category,
        'description': _descriptionController.text,
        'address': _addressController.text,
        'userId': _isAnonymous ? null : user.uid,
        'userName': _isAnonymous ? null : userName,
        'isAnonymous': _isAnonymous,
        'status': 'Pending',
        'createdAt': Timestamp.now(),
      };

      if (photoUrl != null) {
        complaintData['photoUrl'] = photoUrl;
      }

      if (_selectedLocation != null) {
        complaintData['location'] = GeoPoint(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        );
      }

      await FirebaseFirestore.instance.collection('grievances').add(complaintData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully')),
        );
        _titleController.clear();
        _descriptionController.clear();
        _addressController.clear();
        setState(() {
          _category = null;
          _isAnonymous = false;
          _selectedImage = null;
          _selectedLocation = null;
        });
        context.go('/complaint');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox.shrink();
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kIsWeb
              ? Image.network(
                  _selectedImage!.path,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(_selectedImage!.path),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _selectedImage = null),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapWidget(LatLng defaultLatLng) {
    if (!checkGoogleMapsLoaded()) {
      return Container(
        width: double.infinity,
        color: const Color(0xFF1F2937),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Color(0xFF10B981), size: 40),
            const SizedBox(height: 8),
            Text(
              _selectedLocation != null
                  ? 'Location Pin Selected:\nLat: ${_selectedLocation!.latitude.toStringAsFixed(5)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(5)}'
                  : 'Tap "Use Current GPS Location" above to capture coordinates',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: defaultLatLng,
        zoom: 14,
      ),
      onMapCreated: (controller) => _mapController = controller,
      onTap: (LatLng tappedLatLng) {
        setState(() {
          _selectedLocation = tappedLatLng;
        });
      },
      markers: _selectedLocation != null
          ? {
              Marker(
                markerId: const MarkerId('selected_location'),
                position: _selectedLocation!,
                infoWindow: const InfoWindow(title: 'Selected Location'),
              ),
            }
          : {},
    );
  }

  @override
  Widget build(BuildContext context) {
    // Default location (e.g., Pune / Central City) if none selected
    final defaultLatLng = _selectedLocation ?? const LatLng(18.5204, 73.8567);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Complaint'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/complaint'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Water', 'Electrical', 'Roads', 'Sanitation'].map((category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    value: _category,
                    onChanged: (value) => setState(() => _category = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Photo Attachment Card (Cloudinary)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.photo_camera, color: Color(0xFF3B82F6)),
                      SizedBox(width: 8),
                      Text('Attach Photo (Cloudinary)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedImage != null)
                    _buildImagePreview()
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Map & Geolocation Card (Google Maps)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.map, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Text('Pin Location (Google Maps)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                      icon: _isFetchingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_isFetchingLocation ? 'Fetching GPS...' : 'Use Current GPS Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildMapWidget(defaultLatLng),
                    ),
                  ),
                  if (_selectedLocation != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Selected Coordinates: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Submit Anonymously'),
                    subtitle: const Text('Your identity will not be visible to others'),
                    value: _isAnonymous,
                    onChanged: (bool value) {
                      setState(() {
                        _isAnonymous = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitComplaint,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Submit Complaint'),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
    );
  }
}
