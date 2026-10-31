import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String complaintId = ModalRoute.of(context)?.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Track Complaint'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('grievances').doc(complaintId).snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          var doc = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['title'], style: const TextStyle(fontSize: 20, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Category: ${doc['category']}', style: const TextStyle(color: Colors.white70)),
                Text('Status: ${doc['status']}', style: TextStyle(color: doc['status'] == 'Pending' ? Colors.orange : Colors.green)),
                Text('Date: ${doc['createdAt'].toDate().toString().split(' ')[0]}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                const Text('Updates:', style: TextStyle(fontSize: 18, color: Colors.white)),
                const Text('No updates yet.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          );
        },
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