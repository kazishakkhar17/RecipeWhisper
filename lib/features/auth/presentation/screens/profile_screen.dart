// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bli_flutter_recipewhisper/core/localization/app_localizations.dart';

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
    return user?.displayName ?? context.tr('user');
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
      appBar: AppBar(title: Text(context.tr('profile'))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => setState(() {
                  _showProfileDetails = !_showProfileDetails;
                  if (_showProfileDetails) _showDietDetails = false;
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          _getInitials(),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getDisplayName(),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(user?.email ?? context.tr('no_email'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_showProfileDetails ? context.tr('hide_details') : context.tr('view_profile'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(width: 6),
                            Icon(
                              _showProfileDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 18,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('personal_information'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: context.tr('first_name'), 
                            prefixIcon: const Icon(Icons.person_outline, size: 20), 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          onChanged: (_) => _saveProfileData(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: context.tr('last_name'), 
                            prefixIcon: const Icon(Icons.person_outline, size: 20), 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          onChanged: (_) => _saveProfileData(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          enabled: false,
                          controller: TextEditingController(text: user?.email ?? context.tr('no_email')),
                          decoration: InputDecoration(
                            labelText: context.tr('email'), 
                            prefixIcon: const Icon(Icons.email_outlined, size: 20), 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Diet Widget Preview
// Diet Widget Preview
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: GestureDetector(
    onTap: () => setState(() {
      _showDietDetails = !_showDietDetails;
      if (_showDietDetails) _showProfileDetails = false;
    }),
    child: Container(
      height: 100,
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: Container(
          constraints: const BoxConstraints(minWidth: 250), // Minimum width
          child: const DietWidget(),
        ),
      ),
    ),
  ),
),

            const SizedBox(height: 16),

            // Settings
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SettingsWidget()),

            const SizedBox(height: 16),
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