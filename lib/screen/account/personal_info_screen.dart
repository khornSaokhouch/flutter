import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Make sure this is still needed for your UserService
import 'package:http_parser/http_parser.dart'; // Make sure this is still needed for your UserService

// Assuming these imports are correct based on your project structure
import '../../config/constants/api_constants.dart';
import '../../core/utils/auth_utils.dart';
import '../../core/utils/message_utils.dart';
import '../../core/utils/utils.dart';
import '../../models/user.dart';
import '../../server/user_service.dart';

class UpdateProfileScreen extends StatefulWidget {
  final int userId;
  const UpdateProfileScreen({super.key, required this.userId});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  User? user;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool isLoading = true;
  File? _image; // Holds the newly picked image
  bool _isSaving = false; // To manage button state during save

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    setState(() => isLoading = true); // Ensure loading state is true when fetching
    try {
      user = await AuthUtils.checkAuthAndGetUser(
        context: context,
        userId: widget.userId,
      );

      if (user != null) {
        _nameCtrl.text = user!.name ?? '';
        _emailCtrl.text = user!.email ?? '';
        _phoneCtrl.text = user!.phone ?? '';
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) {
      // User canceled the picker
      return;
    }

    final file = File(picked.path);

    // Check MIME type
    final mimeType = getMimeType(file.path).toLowerCase();
    const allowedTypes = ['png', 'jpg', 'jpeg', 'gif'];
    if (!allowedTypes.contains(mimeType)) {
      showSnackBar(context, 'Unsupported file type: $mimeType', SnackBarType.warning);
      return;
    }

    // Check file size (max 2MB = 2048 KB)
    final fileSize = await file.length(); // in bytes
    if (fileSize > 2048 * 1024) {
      showSnackBar(
        context,
        'Selected image is too large (${(fileSize / 1024).toStringAsFixed(0)} KB). Maximum allowed is 2048 KB.',
        SnackBarType.warning,
      );
      return;
    }

    // All checks passed, set the image
    setState(() => _image = file);
    showSnackBar(context, 'Image selected successfully!', SnackBarType.success);
  }


  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      File? imageToUpload;
      String? mimeType;

      if (_image != null && await _image!.exists()) {
        imageToUpload = _image;
        mimeType = getMimeType(_image!.path);

        // Check file size: max 2MB
        final fileSize = await _image!.length();
        if (fileSize > 2048 * 1024) {
          showSnackBar(
            context,
            'Selected image is too large (${(fileSize / 1024).toStringAsFixed(0)} KB). Maximum 2048 KB.',
            SnackBarType.warning,
          );
          return;
        }
      }

      // Call your UserService update
      final result = await UserService.updateUser(
        widget.userId,
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        image: imageToUpload, // Only send if selected
      );

      if (result['error'] != null) {
        showSnackBar(
          context,
          'Error: ${result['error']}${mimeType != null ? ', File type: $mimeType' : ''}',
          SnackBarType.error,
        );
      } else if (result['errors'] != null) {
        final errors = result['errors'] as Map<String, dynamic>;
        showSnackBar(
          context,
          '${errors.values.first[0] ?? 'Update failed'}${mimeType != null ? ', File type: $mimeType' : ''}',
          SnackBarType.error,
        );
      } else {
        showSnackBar(context, 'Profile updated successfully!', SnackBarType.success);
        _initPage(); // refresh profile
      }
    } catch (e) {
      showSnackBar(
        context,
        'Upload failed: $e${_image != null ? ', File type: ${getMimeType(_image!.path)}' : ''}',
        SnackBarType.error,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }



  // Helper to build the current profile image
  Widget _buildProfileImage() {
    ImageProvider imageProvider;
    if (_image != null) {
      // New image picked
      imageProvider = FileImage(_image!);
    } else if (user?.profileImage != null && user!.profileImage!.isNotEmpty) {
      // Existing network image
      imageProvider = NetworkImage('${ApiConstants.baseStorageUrl}/${user!.profileImage!}');
    } else {
      // Default placeholder
      imageProvider = const AssetImage('assets/images/default_avatar.png');
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: CircleAvatar(
              radius: 56, // Slightly smaller to show a border
              backgroundImage: imageProvider,
              backgroundColor: Colors.grey.shade200, // Placeholder background
              onBackgroundImageError: (exception, stackTrace) {
                // Fallback for network image loading errors
                debugPrint('Error loading image: $exception');
                setState(() {
                  // Optionally set a fallback image or show an error icon
                  // For now, it will just show the grey background.
                });
              },
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Update Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent, // Make app bar transparent
        foregroundColor: Theme.of(context).colorScheme.onBackground, // Adjust color
      ),
      extendBodyBehindAppBar: true, // Extend body behind app bar
      body: Container(
        // Background gradient or solid color
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20), // Space from top
                    Center(
                      child: _buildProfileImage(),
                    ),
                    const SizedBox(height: 30),
                    // Profile Info Card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: _buildInputDecoration(
                                labelText: 'Name',
                                icon: Icons.person,
                              ),
                              validator: (value) =>
                              value == null || value.isEmpty ? 'Name is required' : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: _buildInputDecoration(
                                labelText: 'Email',
                                icon: Icons.email,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Email is required';
                                if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _phoneCtrl,
                              decoration: _buildInputDecoration(
                                labelText: 'Phone Number',
                                icon: Icons.phone,
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) =>
                              value == null || value.isEmpty ? 'Phone number is required' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Save Changes Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges, // Disable if saving
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 5,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      )
                          : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper for consistent input decoration
  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // No border for cleaner look
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.transparent, // No border when enabled
        ),
      ),
    );
  }
}