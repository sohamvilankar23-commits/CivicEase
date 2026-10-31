import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_bottom_nav_bar.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _emergencyNumbers = {
    'Police': 'tel:100',
    'Ambulance': 'tel:108',
    'Fire': 'tel:101',
    'Women Helpline': 'tel:1091',
    'Child Helpline': 'tel:1098',
    'Senior Citizen Helpline': 'tel:14567',
    'Anti-Corruption': 'tel:1031',
    'Railway Enquiry': 'tel:139',
  };

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch the number')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
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
          const Text(
            'Emergency Contacts',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._emergencyNumbers.entries.map((entry) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.phone_in_talk, color: Colors.red),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(entry.value.replaceAll('tel:', '')),
                trailing: ElevatedButton.icon(
                  onPressed: () => _launchURL(entry.value),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Tips',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Stay calm and assess the situation'),
                  Text('• Call the appropriate emergency number'),
                  Text('• Follow instructions from emergency personnel'),
                  Text('• Keep emergency contacts saved in your phone'),
                  Text('• Know your current location'),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 3),
    );
  }
}