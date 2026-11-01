import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_bottom_nav_bar.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  String _filter = 'All';
  bool _isAdmin = false;
  String? _categoryFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchController = TextEditingController();

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

  Future<void> _updateStatus(String docId, String currentStatus) async {
    String newStatus = currentStatus == 'Pending' ? 'Resolved' : 'Pending';
    await FirebaseFirestore.instance.collection('grievances').doc(docId).update({'status': newStatus});
  }

  Future<void> _deleteComplaint(String docId) async {
    await FirebaseFirestore.instance.collection('grievances').doc(docId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint deleted successfully')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildComplaintPhoto(String? photoUrl) {
    if (photoUrl == null || photoUrl.trim().isEmpty) return const SizedBox.shrink();
    if (photoUrl.startsWith('data:image')) {
      try {
        final base64Data = photoUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 180,
            color: Colors.grey[800],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildComplaintLocation(Map<String, dynamic> data) {
    final address = data['address'] as String? ?? '';
    final GeoPoint? location = data['location'] as GeoPoint?;

    if (address.isEmpty && location == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (location != null) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}');
                if (await canLaunchUrl(mapsUrl)) {
                  await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      'Map Location: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)} (Open Map)',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'In Progress', 'Resolved'].map((filter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(hintText: 'Search complaints...'),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  hint: const Text('Filter Category'),
                  value: _categoryFilter,
                  items: ['Water', 'Electrical', 'Roads', 'Sanitation'].map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) => setState(() => _categoryFilter = value),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text(_startDate == null ? 'Start Date' : _startDate!.toString().split(' ')[0]),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('to'),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context, false),
                    child: Text(_endDate == null ? 'End Date' : _endDate!.toString().split(' ')[0]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('grievances').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var complaints = snapshot.data!.docs.where((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  bool matchesStatus = _filter == 'All' || data['status'] == _filter;
                  bool matchesCategory = _categoryFilter == null || data['category'] == _categoryFilter;
                  bool matchesSearch = _searchController.text.isEmpty ||
                      (data['description'] ?? '').toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
                      (data['title'] ?? '').toString().toLowerCase().contains(_searchController.text.toLowerCase());
                  bool matchesDate = true;
                  if (_startDate != null || _endDate != null) {
                    DateTime docDate = (data['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    if (_startDate != null) {
                      matchesDate = docDate.isAfter(_startDate!);
                    }
                    if (_endDate != null) {
                      matchesDate = matchesDate && docDate.isBefore(_endDate!.add(const Duration(days: 1)));
                    }
                  }
                  return matchesStatus && matchesCategory && matchesSearch && matchesDate;
                }).toList();

                if (complaints.isEmpty) {
                  return const Center(
                    child: Text('No complaints found.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    var doc = complaints[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => context.go('/tracking', extra: doc.id),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text(
                                      data['category'] ?? 'General',
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (data['status'] == 'Resolved'
                                              ? Colors.green
                                              : data['status'] == 'In Progress'
                                                  ? Colors.yellow[700]
                                                  : Colors.orange)
                                          ?.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: data['status'] == 'Resolved'
                                            ? Colors.green
                                            : data['status'] == 'In Progress'
                                                ? Colors.yellow
                                                : Colors.orange,
                                      ),
                                    ),
                                    child: Text(
                                      data['status'] ?? 'Pending',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: data['status'] == 'Resolved'
                                            ? Colors.green
                                            : data['status'] == 'In Progress'
                                                ? Colors.yellow
                                                : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['title'] ?? 'No Title',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              if (data['description'] != null && (data['description'] as String).isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  data['description'],
                                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (data['photoUrl'] != null)
                                _buildComplaintPhoto(data['photoUrl']),
                              _buildComplaintLocation(data),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Date: ${(data['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'Unknown'}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  if (_isAdmin)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _updateStatus(doc.id, data['status'] ?? 'Pending'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          child: Text(
                                            data['status'] == 'Pending' ? 'Resolve' : 'Reopen',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () => _deleteComplaint(doc.id),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 1),
    );
  }
}
