import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          title: Text('Hello, ${user?.email?.split('@')[0] ?? 'User'}!'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => context.go('/profile'),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => context.go('/edit-profile'),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Complaint Summary',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            StreamBuilder(
              stream: FirebaseFirestore.instance.collection('grievances').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading data', style: TextStyle(color: Colors.white)));
                }
                var total = snapshot.data!.docs.length;
                var pending = snapshot.data!.docs.where((doc) => doc['status'] == 'Pending').length;
                var resolved = snapshot.data!.docs.where((doc) => doc['status'] == 'Resolved').length;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SummaryCard(label: 'Total', value: total.toString()),
                    SummaryCard(label: 'Pending', value: pending.toString()),
                    SummaryCard(label: 'Resolved', value: resolved.toString()),
                  ],
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Categories',
                style: TextStyle(fontSize: 18, color: Colors.white),
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
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  }

                  final complaints = snapshot.data?.docs ?? [];
                  final waterComplaints = complaints.where((doc) => doc['category'].toString().toLowerCase() == 'water').toList();
                  final electricityComplaints = complaints.where((doc) => doc['category'].toString().toLowerCase() == 'electrical').toList();
                  final roadsComplaints = complaints.where((doc) => doc['category'].toString().toLowerCase() == 'roads').toList();
                  final sanitationComplaints = complaints.where((doc) => doc['category'].toString().toLowerCase() == 'sanitation').toList();

                  print('Water: ${waterComplaints.length}, Electricity: ${electricityComplaints.length}, Roads: ${roadsComplaints.length}, Sanitation: ${sanitationComplaints.length}');

                  return GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(16),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      CategoryCard(label: 'Water', icon: Icons.water_drop, complaints: waterComplaints),
                      CategoryCard(label: 'Electricity', icon: Icons.electrical_services, complaints: electricityComplaints),
                      CategoryCard(label: 'Roads', icon: Icons.directions_car, complaints: roadsComplaints),
                      CategoryCard(label: 'Sanitation', icon: Icons.cleaning_services, complaints: sanitationComplaints),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0, // Set to 0 for Home as default
          onTap: (index) {
            if (index == 0) context.go('/home');
            if (index == 1) context.go('/complaint');
            if (index == 2) context.go('/add-complaint');
            if (index == 3) context.go('/emergency');
            if (index == 4) context.go('/profile');
          },
          backgroundColor: const Color(0xFFF1E6F5), // Corrected color
          selectedItemColor: const Color(0xFF1E3A8A), // Blue for selected
          unselectedItemColor: Colors.grey[600], // Grey for unselected
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
              backgroundColor: Color(0xFF4CAF50),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Complaints',
              backgroundColor: Color(0xFF2196F3),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'New',
              backgroundColor: Color(0xFFFF9800),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning),
              label: 'Emergency',
              backgroundColor: Color(0xFFF44336),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
              backgroundColor: Color(0xFF9C27B0),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const SummaryCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<QueryDocumentSnapshot> complaints;

  const CategoryCard({super.key, required this.label, required this.icon, required this.complaints});

  @override
  Widget build(BuildContext context) {
    print('Navigating to /category/${label.toLowerCase()}');
    return Card(
      color: const Color(0xFF2A2A2A),
      child: InkWell(
        onTap: () => context.go('/category/${label.toLowerCase()}'),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                '${complaints.length} Issues',
                style: const TextStyle(color: Colors.white70),
              ),
              if (complaints.isNotEmpty) const SizedBox(height: 8),
              if (complaints.isNotEmpty)
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: complaints.take(2).map((doc) {
                        try {
                          final address = doc['address']?.toString() ?? 'Unknown Address';
                          final description = doc['description']?.toString() ?? 'No description';
                          final preview = description.length > 15 ? '${description.substring(0, 15)}...' : description;
                          return Text(
                            '$address - $preview',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          );
                        } catch (e) {
                          print('Error rendering complaint for $label: $e');
                          return const Text('Error loading complaint', style: TextStyle(color: Colors.red, fontSize: 12));
                        }
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}