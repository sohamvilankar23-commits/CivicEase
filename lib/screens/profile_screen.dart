import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name = 'User';
  String? _number = 'Not set';
  String? _email;
  bool _isLoading = true;
  bool _notifications = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _isAdmin = doc.data()?['isAdmin'] ?? false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _name = doc.data()?['name'] ?? 'User';
            _number = doc.data()?['number'] ?? 'Not set';
            _email = user.email ?? 'Not set';
            _isLoading = false;
          });
        } else {
          setState(() {
            _email = user.email ?? 'Not set';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _email = user.email ?? 'Not set';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => context.go('/edit-profile'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[700],
                          child: Text(
                            _name![0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _name!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          _email!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.person,
                            color: Colors.white70,
                          ),
                          title: const Text(
                            'Name',
                            style: TextStyle(color: Colors.white70),
                          ),
                          subtitle: Text(
                            _name!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.email,
                            color: Colors.white70,
                          ),
                          title: const Text(
                            'Email',
                            style: TextStyle(color: Colors.white70),
                          ),
                          subtitle: Text(
                            _email!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.phone,
                            color: Colors.white70,
                          ),
                          title: const Text(
                            'Phone',
                            style: TextStyle(color: Colors.white70),
                          ),
                          subtitle: Text(
                            _number!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preferences',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          secondary: const Icon(
                            Icons.notifications,
                            color: Colors.white70,
                          ),
                          title: const Text(
                            'Notifications',
                            style: TextStyle(color: Colors.white70),
                          ),
                          subtitle: Text(
                            _notifications ? 'Enabled' : 'Disabled',
                            style: const TextStyle(color: Colors.white),
                          ),
                          value: _notifications,
                          onChanged: (value) {
                            setState(() {
                              _notifications = value;
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isAdmin)
                          ListTile(
                            leading: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white70,
                            ),
                            title: const Text(
                              'Admin Dashboard',
                              style: TextStyle(color: Colors.white70),
                            ),
                            subtitle: const Text(
                              'Manage complaints',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () => context.go('/admin-dashboard'),
                          ),
                        ListTile(
                          leading: const Icon(
                            Icons.lock,
                            color: Colors.white70,
                          ),
                          title: const Text(
                            'Change Password',
                            style: TextStyle(color: Colors.white70),
                          ),
                          subtitle: const Text(
                            'Update your password',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () => context.go('/change-password'),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: Colors.white70,
                          ),
                          title: const Text(
                            'Sign Out',
                            style: TextStyle(color: Colors.white70),
                          ),
                          subtitle: const Text(
                            'Log out of your account',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () => _signOut(context),
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
}