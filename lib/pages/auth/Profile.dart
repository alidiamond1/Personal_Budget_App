import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_pudget/pages/auth/update_profile.dart';
import 'package:personal_pudget/pages/auth/change_password.dart';
import 'package:personal_pudget/pages/auth/sign_in_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late SharedPreferences _prefs;

  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';

  String _fullName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _initializePrefs().then((_) => _loadUserPreferences());
    _loadUserData();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = _prefs.getString('language') ?? 'English';
      _selectedCurrency = _prefs.getString('currency') ?? 'USD';
      _notificationsEnabled = _prefs.getBool('notifications') ?? true;
    });
  }

  void _loadUserPreferences() {
    setState(() {
      _selectedLanguage = _prefs.getString('language') ?? 'English';
      _selectedCurrency = _prefs.getString('currency') ?? 'USD';
      _notificationsEnabled = _prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _saveUserPreferences() async {
    await _prefs.setString('language', _selectedLanguage);
    await _prefs.setString('currency', _selectedCurrency);
    await _prefs.setBool('notifications', _notificationsEnabled);
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userData =
            await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
          setState(() {
            _fullName = data['fullName'] ?? 'No Name';
            _email = data['email'] ?? user.email ?? 'No Email';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: \$e');
    }
  }

  void _updateLanguage(String language) async {
    setState(() => _selectedLanguage = language);
    await _saveUserPreferences();

    // Update the UI with the new language
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(language == 'English'
              ? 'Language changed to English'
              : 'Luuqada waxaa loo badalay Soomaali'),
        ),
      );
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_selectedLanguage == 'English'
              ? 'Select Language'
              : 'Dooro Luuqada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('English'),
                selected: _selectedLanguage == 'English',
                onTap: () {
                  Navigator.pop(context);
                  _updateLanguage('English');
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Soomaali'),
                selected: _selectedLanguage == 'Somali',
                onTap: () {
                  Navigator.pop(context);
                  _updateLanguage('Somali');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSomali = _selectedLanguage == 'Somali';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isSomali ? 'Profile-kaaga' : 'Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _fullName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Security Section
            Text(
              isSomali ? 'Ammaanka' : 'Security',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              icon: Icons.lock,
              title: isSomali ? 'Badal Furaha Sirta' : 'Change Password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen()),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.person,
              title: isSomali ? 'Cusbooneysii Profile-ka' : 'Update Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UpdateProfileScreen()),
                );
              },
            ),
            const SizedBox(height: 32),

            // Account Settings Section
            Text(
              isSomali ? 'Hagaajinta Koontada' : 'Account Settings',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSettingItemWithSwitch(
              icon: Icons.notifications,
              title: isSomali ? 'Ogeysiisyada' : 'Notifications',
              value: _notificationsEnabled,
              onChanged: (bool value) async {
                setState(() => _notificationsEnabled = value);
                await _saveUserPreferences();
              },
            ),
            _buildSettingItemWithDropdown(
              icon: Icons.language,
              title: isSomali ? 'Luuqada' : 'Language',
              value: _selectedLanguage,
              onTap: _showLanguageDialog,
            ),
            const SizedBox(height: 32),

            // Sign Out Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.logout, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      isSomali ? 'Ka Bax' : 'Sign Out',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSettingItemWithSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSettingItemWithDropdown({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(value),
      ),
      onTap: onTap,
    );
  }
}
