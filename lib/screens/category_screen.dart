import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class CategoryScreen extends StatelessWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  String _normalizeCategory(String input) {
    switch (input.toLowerCase()) {
      case 'water':
        return 'Water'; // Match Firestore uppercase
      case 'electricity':
        return 'Electrical'; // Match Firestore uppercase
      case 'roads':
        return 'Roads'; // Match Firestore uppercase
      case 'sanitation':
        return 'Sanitation'; // Match Firestore uppercase
      default:
        return input; // Fallback to input as-is
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedCategory = _normalizeCategory(category);
    print('CategoryScreen: Received category = "$category", normalized to "$normalizedCategory"');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: Text('${category[0].toUpperCase()}${category.substring(1)} Complaints'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            print('Back button pressed, navigating to /home');
            context.go('/home');
          },
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('grievances')
            .where('category', isEqualTo: normalizedCategory)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Firestore error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final complaints = snapshot.data?.docs ?? [];
          print('Found ${complaints.length} complaints for category: "$normalizedCategory"');
          if (complaints.isEmpty) {
            print('No matching documents found. Checking all categories...');
            FirebaseFirestore.instance.collection('grievances').get().then((snapshot) {
              snapshot.docs.forEach((doc) {
                print('Firestore doc category: ${doc['category']}');
              });
            });
            return const Center(child: Text('No complaints found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final doc = complaints[index];
              return Card(
                color: const Color(0xFF2A2A2A),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(doc['address'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text(doc['description'], style: const TextStyle(color: Colors.white70)),
                  trailing: Text(doc['status'], style: const TextStyle(color: Colors.white70)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}