import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_bottom_nav_bar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? true;
    });
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'New passwords do not match';
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters long';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Reauthenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(credential);
        
        // Change password
        await user.updatePassword(_newPasswordController.text);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully')),
          );
          context.go('/profile');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkMode ? const Color(0xFF1E3A8A) : Colors.white,
      appBar: AppBar(
        backgroundColor: _darkMode ? const Color(0xFF1E3A8A) : Colors.blue,
        title: const Text('Change Password'),
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
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _darkMode ? Colors.white70 : Colors.black54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _darkMode ? Colors.white : Colors.blue),
                ),
              ),
              style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _darkMode ? Colors.white70 : Colors.black54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _darkMode ? Colors.white : Colors.blue),
                ),
              ),
              style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _darkMode ? Colors.white70 : Colors.black54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _darkMode ? Colors.white : Colors.blue),
                ),
              ),
              style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
              obscureText: true,
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
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkMode ? const Color(0xFF1E3A8A) : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Change Password'),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 4),
    );
  }
} 