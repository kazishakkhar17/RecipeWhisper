// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../widgets/diet_widget.dart';
import '../widgets/settings_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Box _profileBox;
  bool _isInitialized = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  bool _showProfileDetails = false;
  bool _showDietDetails = false;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    _profileBox = await Hive.openBox('user_profile_box');

    _firstNameController.text = _profileBox.get('firstName', defaultValue: '');
    _lastNameController.text = _profileBox.get('lastName', defaultValue: '');

    setState(() => _isInitialized = true);
  }

  void _saveProfileData() {
    _profileBox.put('firstName', _firstNameController.text);
    _profileBox.put('lastName', _lastNameController.text);
    setState(() {});
  }

  String _getDisplayName() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isNotEmpty && lastName.isNotEmpty) return '$firstName $lastName';
    if (firstName.isNotEmpty) return firstName;
    if (lastName.isNotEmpty) return lastName;

    final user = _auth.currentUser;
    return user?.displayName ?? 'User';
  }

  String _getInitials() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isNotEmpty && lastName.isNotEmpty) return '${firstName[0]}${lastName[0]}'.toUpperCase();
    if (firstName.isNotEmpty) return firstName[0].toUpperCase();
    if (lastName.isNotEmpty) return lastName[0].toUpperCase();

    final user = _auth.currentUser;
    return user?.email?[0].toUpperCase() ?? '👤';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Card
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () => setState(() {
                  _showProfileDetails = !_showProfileDetails;
                  if (_showProfileDetails) _showDietDetails = false;
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          _getInitials(),
                          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getDisplayName(),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(user?.email ?? 'No email', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_showProfileDetails ? 'Hide Details' : 'View Profile',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Icon(
                              _showProfileDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Profile Details
            if (_showProfileDetails)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _firstNameController,
                          decoration: InputDecoration(labelText: 'First Name', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          onChanged: (_) => _saveProfileData(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(labelText: 'Last Name', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          onChanged: (_) => _saveProfileData(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          enabled: false,
                          controller: TextEditingController(text: user?.email ?? 'No email'),
                          decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Diet Widget Preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => setState(() {
                  _showDietDetails = !_showDietDetails;
                  if (_showDietDetails) _showProfileDetails = false;
                }),
                child: DietWidget(),
              ),
            ),

            const SizedBox(height: 20),

            // Settings
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SettingsWidget()),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}
