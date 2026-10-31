import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Admin Panel'),
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
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: 'Search complaints...'),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  hint: const Text('Filter by Category'),
                  items: ['Water', 'Electrical', 'Roads', 'Sanitation'].map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Start Date'))),
                const SizedBox(width: 8),
                const Text('to', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('End Date'))),
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
                  if (_filter == 'All') return true;
                  return doc['status'] == _filter;
                }).toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    var doc = complaints[index];
                    return Card(
                      child: ListTile(
                        title: Text(doc['title']),
                        subtitle: Text('Category: ${doc['category']}\nDate: ${doc['createdAt'].toDate().toString().split(' ')[0]}'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            String newStatus = doc['status'] == 'Pending' ? 'Resolved' : 'Pending';
                            await FirebaseFirestore.instance.collection('grievances').doc(doc.id).update({'status': newStatus});
                          },
                          child: Text(doc['status'] == 'Pending' ? 'Resolve' : 'Reopen'),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/complaint');
          if (index == 2) context.go('/add-complaint');
          if (index == 3) context.go('/emergency');
          if (index == 4) context.go('/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Complaints'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'New'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Emergency'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}