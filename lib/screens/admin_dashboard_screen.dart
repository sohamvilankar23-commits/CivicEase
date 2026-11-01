import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_bottom_nav_bar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _filter = 'All';
  bool _isAdmin = false;
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _resolvedCount = 0;
  bool _isLoading = true;
  String _adminNote = '';
  bool _isSavingNote = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadAdminNote();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _isAdmin = doc.data()?['isAdmin'] ?? false;
      });
      if (_isAdmin) {
        _loadComplaintStats();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadComplaintStats() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('grievances').get();
      int pending = 0;
      int inProgress = 0;
      int resolved = 0;

      for (var doc in snapshot.docs) {
        final status = doc['status']?.toString() ?? 'Pending';
        if (status == 'Pending') pending++;
        if (status == 'In Progress') inProgress++;
        if (status == 'Resolved') resolved++;
      }

      setState(() {
        _pendingCount = pending;
        _inProgressCount = inProgress;
        _resolvedCount = resolved;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String docId, String currentStatus) async {
    String newStatus;
    if (currentStatus == 'Pending') {
      newStatus = 'In Progress';
    } else if (currentStatus == 'In Progress') {
      newStatus = 'Resolved';
    } else {
      newStatus = 'Pending';
    }
    await FirebaseFirestore.instance.collection('grievances').doc(docId).update({'status': newStatus});
    _loadComplaintStats(); // Refresh stats after update
  }

  Future<void> _loadAdminNote() async {
    final doc = await FirebaseFirestore.instance.collection('admin_dashboard').doc('note').get();
    setState(() {
      _adminNote = doc.data()?['text'] ?? '';
    });
  }

  Future<void> _saveAdminNote() async {
    setState(() => _isSavingNote = true);
    await FirebaseFirestore.instance.collection('admin_dashboard').doc('note').set({'text': _adminNote});
    setState(() => _isSavingNote = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved')));
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
                      'Map Coordinates: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)} (Open Map)',
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
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          title: const Text('Admin Dashboard'),
        ),
        body: const Center(
          child: Text(
            'Access Denied: Admins Only',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        bottomNavigationBar: AppBottomNavBar(currentIndex: 4),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadComplaintStats();
              _loadAdminNote();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1E3A8A),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Complaint Statistics',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('Pending', _pendingCount, Colors.orange),
                      _buildStatCard('In Progress', _inProgressCount, Colors.yellow),
                      _buildStatCard('Resolved', _resolvedCount, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard('Unsolved', _pendingCount, Colors.red),
                ],
              ),
            ),
            Container(
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                  const SizedBox(height: 16),
                  StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('grievances').snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                      }
                      var complaints = snapshot.data!.docs.where((doc) {
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        bool matchesStatus = _filter == 'All' || data['status']?.toString() == _filter;
                        return matchesStatus;
                      }).toList();

                      if (complaints.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No complaints in this category.', style: TextStyle(color: Colors.white70)),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: complaints.length,
                        itemBuilder: (context, index) {
                          var doc = complaints[index];
                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                          return Card(
                            color: const Color(0xFF2A2A2A),
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
                                            data['category']?.toString() ?? 'General',
                                            style: const TextStyle(fontSize: 12, color: Colors.white),
                                          ),
                                          backgroundColor: const Color(0xFF1E3A8A),
                                          padding: EdgeInsets.zero,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              data['status']?.toString() ?? 'Pending',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: (data['status']?.toString() ?? 'Pending') == 'Pending'
                                                    ? Colors.orange
                                                    : (data['status']?.toString() == 'In Progress')
                                                    ? Colors.yellow
                                                    : Colors.green,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                                              tooltip: 'Cycle Status',
                                              onPressed: () => _updateStatus(doc.id, data['status']?.toString() ?? 'Pending'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      data['title']?.toString() ?? 'No Title',
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
                                    Text(
                                      'Date: ${(data['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'Unknown'}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
