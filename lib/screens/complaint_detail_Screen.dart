import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/map_checker.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final String docId;

  const ComplaintDetailScreen({super.key, required this.docId});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  bool _isAdmin = false;
  GoogleMapController? _mapController;
  String _progressNote = '';
  bool _isSavingNote = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _isAdmin = doc.data()?['isAdmin'] ?? false;
      });
    }
  }

  Future<void> _loadProgressNote(DocumentSnapshot doc) async {
    setState(() {
      _progressNote = doc['progressNote'] ?? '';
    });
  }

  Future<void> _saveProgressNote() async {
    setState(() => _isSavingNote = true);
    await FirebaseFirestore.instance.collection('grievances').doc(widget.docId).update({'progressNote': _progressNote});
    setState(() => _isSavingNote = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress note saved')));
  }

  Widget _buildPhotoWidget(String photoUrl) {
    if (photoUrl.startsWith('data:image')) {
      try {
        final base64Data = photoUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[800],
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.white70),
                SizedBox(width: 8),
                Text('Image format error', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        );
      } catch (e) {
        return const Icon(Icons.broken_image, size: 48, color: Colors.red);
      }
    }

    return CachedNetworkImage(
      imageUrl: photoUrl,
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }

  Widget _buildDetailMapWidget(GeoPoint location) {
    final targetLatLng = LatLng(location.latitude, location.longitude);
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
              'Grievance Location Coordinates:\nLat: ${location.latitude.toStringAsFixed(5)}, Lng: ${location.longitude.toStringAsFixed(5)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: targetLatLng,
        zoom: 15,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('complaint_location'),
          position: targetLatLng,
        ),
      },
      onMapCreated: (controller) => _mapController = controller,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/complaint'),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('grievances').doc(widget.docId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Complaint not found'));
          }
          var complaint = snapshot.data!.data() as Map<String, dynamic>;
          bool isAnonymous = complaint['isAnonymous'] ?? false;
          // Load progress note
          _progressNote = complaint['progressNote'] ?? '';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Title: ${complaint['title']}', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Category: ${complaint['category']}', 
                          style: const TextStyle(fontSize: 16)),
                        Text('Date: ${(complaint['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'Unknown'}', 
                          style: const TextStyle(fontSize: 16)),
                        Text('Status: ${complaint['status']}', 
                          style: const TextStyle(fontSize: 16)),
                        if (_isAdmin || !isAnonymous)
                          Text('Submitted by: ${isAnonymous ? 'Anonymous User' : (complaint['userName'] ?? 'Unknown User')}',
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description:', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(complaint['description'] ?? 'No description provided', 
                          style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Address:', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(complaint['address'] ?? 'No address provided', 
                          style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                if (complaint['photoUrl'] != null && (complaint['photoUrl'] as String).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Photo Attachment:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildPhotoWidget(complaint['photoUrl']),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (complaint['location'] != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Location:',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.open_in_new, color: Color(0xFF10B981)),
                                tooltip: 'Open in Google Maps',
                                onPressed: () async {
                                  final lat = (complaint['location'] as GeoPoint).latitude;
                                  final lng = (complaint['location'] as GeoPoint).longitude;
                                  final mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                  if (await canLaunchUrl(mapsUrl)) {
                                    await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildDetailMapWidget(complaint['location'] as GeoPoint),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final lat = (complaint['location'] as GeoPoint).latitude;
                                final lng = (complaint['location'] as GeoPoint).longitude;
                                final mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                if (await canLaunchUrl(mapsUrl)) {
                                  await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Open in Google Maps App / Browser'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF10B981),
                                side: const BorderSide(color: Color(0xFF10B981)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_isAdmin) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: const Color(0xFF1A1A1A),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Admin Progress/Comments', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            minLines: 2,
                            maxLines: 5,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Write about progress, updates, or comments for this complaint...',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF232323),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            controller: TextEditingController(text: _progressNote)
                              ..selection = TextSelection.collapsed(offset: _progressNote.length),
                            onChanged: (val) => _progressNote = val,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSavingNote ? null : _saveProgressNote,
                              icon: _isSavingNote
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save),
                              label: const Text('Save Progress'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (complaint['progressNote'] != null && (complaint['progressNote'] as String).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: const Color(0xFF1A1A1A),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Admin Progress/Comments', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(complaint['progressNote'], style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}