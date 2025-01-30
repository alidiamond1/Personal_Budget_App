import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

// Screen for updating user profile information including profile picture
class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Firebase including profile image, name, and phone
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        _emailController.text = user.email ?? '';

        DocumentSnapshot userData =
            await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists && mounted) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
          setState(() {
            _fullNameController.text = data['fullName'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _imageUrl = data['profileImage'];
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Select and upload profile picture from device gallery
  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() => _imageFile = File(image.path));
        await _uploadImage();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error picking image: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Take and upload profile picture using device camera
  Future<void> _pickImageFromCamera() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() => _imageFile = File(image.path));
        await _uploadImage();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error taking photo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Upload profile image to Firebase Storage and update user profile
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      User? user = _auth.currentUser;
      if (user != null) {
        String fileName =
            'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = _storage.ref().child('profile_images/$fileName');

        // Upload the file
        await ref.putFile(_imageFile!);

        // Get the download URL
        String downloadUrl = await ref.getDownloadURL();

        // Update Firestore with new image URL
        await _firestore.collection('users').doc(user.uid).update({
          'profileImage': downloadUrl,
          'updatedAt': Timestamp.now(),
        });

        setState(() => _imageUrl = downloadUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                // English: Success message for profile picture update
                content: Text(
                    'Sawirka profile-ka waa la update-gareeyay')), // Profile picture updated successfully
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error uploading image: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),

            // Profile Image
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade900, width: 2),
                  ),
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade900),
                          ),
                        )
                      : CircleAvatar(
                          radius: 58,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_imageUrl != null
                                  ? NetworkImage(_imageUrl!) as ImageProvider
                                  : null),
                          child: (_imageFile == null && _imageUrl == null)
                              ? Icon(Icons.person,
                                  size: 50, color: Colors.blue.shade900)
                              : null,
                        ),
                ),
                if (!_isLoading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: PopupMenuButton<String>(
                        icon:
                            Icon(Icons.camera_alt, color: Colors.blue.shade900),
                        onSelected: (String choice) {
                          if (choice == 'gallery') {
                            _pickImageFromGallery();
                          } else {
                            _pickImageFromCamera();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'gallery',
                            child: Row(
                              children: [
                                Icon(Icons.photo_library),
                                SizedBox(width: 8),
                                Text('Gallery'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'camera',
                            child: Row(
                              children: [
                                Icon(Icons.camera_alt),
                                SizedBox(width: 8),
                                Text('Camera'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Form fields...
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      // Validate that name field is not empty
                      if (value == null || value.isEmpty) {
                        return 'Fadlan geli magacaaga'; //Please enter your name
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    enabled: false,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  setState(() => _isLoading = true);
                                  User? user = _auth.currentUser;
                                  if (user != null) {
                                    await _firestore
                                        .collection('users')
                                        .doc(user.uid)
                                        .update({
                                      'fullName': _fullNameController.text,
                                      'phone': _phoneController.text,
                                      'updatedAt': Timestamp.now(),
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            // Success message for profile update
                                            content: Text(
                                                'Profile-ka waa la update-gareeyay')), // Profile updated successfully
                                      );
                                    }
                                  }
                                } catch (e) {
                                  // Error message when profile update fails
                                  setState(() => _errorMessage =
                                      'Khalad ayaa dhacay markii la update-gareynaayay profile-ka: $e'); // Error occurred while updating profile
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      //Button text showing current state
                      child: Text(_isLoading
                          ? 'La update-gareynaayaa...'
                          : 'Update Profile-ka'), //Updating... : Update Profile
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
