import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved')));
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
                        bool matchesStatus = _filter == 'All' || doc['status']?.toString() == _filter;
                        return matchesStatus;
                      }).toList();
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: complaints.length,
                        itemBuilder: (context, index) {
                          var doc = complaints[index];
                          return Card(
                            color: const Color(0xFF2A2A2A),
                            child: ListTile(
                              title: Text(
                                doc['title']?.toString() ?? 'No Title',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Category: ${doc['category']?.toString() ?? 'Unknown'}\nDate: ${(doc['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'Unknown'}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    doc['status']?.toString() ?? 'Pending',
                                    style: TextStyle(
                                      color: (doc['status']?.toString() ?? 'Pending') == 'Pending'
                                          ? Colors.orange
                                          : (doc['status']?.toString() == 'In Progress')
                                          ? Colors.yellow
                                          : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white70),
                                    onPressed: () => _updateStatus(doc.id, doc['status']?.toString() ?? 'Pending'),
                                  ),
                                ],
                              ),
                              onTap: () => context.go('/tracking', extra: doc.id),
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