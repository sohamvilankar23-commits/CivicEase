import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Complaint deleted successfully')),
    );
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
                  hint: const Text('Filter by Category'),
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
                  bool matchesStatus = _filter == 'All' || doc['status'] == _filter;
                  bool matchesCategory = _categoryFilter == null || doc['category'] == _categoryFilter;
                  bool matchesSearch = _searchController.text.isEmpty ||
                      doc['description'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
                  bool matchesDate = true;
                  if (_startDate != null || _endDate != null) {
                    // Safely handle createdAt as Timestamp or fallback to a default DateTime
                    DateTime docDate = (doc['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.fromMillisecondsSinceEpoch(0); // Fallback to epoch if not a Timestamp
                    if (_startDate != null) {
                      matchesDate = docDate.isAfter(_startDate!);
                    }
                    if (_endDate != null) {
                      matchesDate = matchesDate && docDate.isBefore(_endDate!.add(const Duration(days: 1)));
                    }
                  }
                  return matchesStatus && matchesCategory && matchesSearch && matchesDate;
                }).toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    var doc = complaints[index];
                    return Card(
                      child: ListTile(
                        title: Text(doc['title']),
                        subtitle: Text(
                          'Category: ${doc['category']}\nDate: ${(doc['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'Unknown'}',
                        ),
                        trailing: _isAdmin
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () => _updateStatus(doc.id, doc['status']),
                              child: Text(doc['status'] == 'Pending' ? 'Resolve' : 'Reopen'),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteComplaint(doc.id),
                            ),
                          ],
                        )
                            : Text(
                          doc['status'],
                          style: TextStyle(
                            color: doc['status'] == 'Pending' ? Colors.orange : Colors.green,
                          ),
                        ),
                        onTap: () => context.go('/tracking', extra: doc.id),
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