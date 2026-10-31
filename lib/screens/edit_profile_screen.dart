import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_bottom_nav_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  String? _errorMessage;
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? true;
    });
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _nameController.text = doc.data()?['name']?.toString() ?? '';
            _numberController.text = doc.data()?['number']?.toString() ?? '';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error loading profile: $e';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'number': _numberController.text.trim(),
        }, SetOptions(merge: true));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          context.go('/profile');
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error saving profile: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkMode ? const Color(0xFF1E3A8A) : Colors.white,
      appBar: AppBar(
        backgroundColor: _darkMode ? const Color(0xFF1E3A8A) : Colors.blue,
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _darkMode ? Colors.white70 : Colors.black54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _darkMode ? Colors.white : Colors.blue),
                ),
              ),
              style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numberController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _darkMode ? Colors.white70 : Colors.black54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _darkMode ? Colors.white : Colors.blue),
                ),
              ),
              style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
              keyboardType: TextInputType.phone,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkMode ? const Color(0xFF1E3A8A) : Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 4),
    );
  }
}