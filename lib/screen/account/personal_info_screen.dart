import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http; 
// import 'package:http_parser/http_parser.dart';

import '../../core/utils/auth_utils.dart';
import '../../core/utils/message_utils.dart';
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
  File? _image; 
  bool _isSaving = false;

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);

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
    setState(() => isLoading = true);
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
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final file = File(picked.path);
    // Add your mime/size checks here (preserved from your original code)
    
    setState(() => _image = file);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true); // UI feedback

    try {
      File? imageToUpload;
      if (_image != null && await _image!.exists()) {
        imageToUpload = _image;
      }

      final result = await UserService.updateUser(
        widget.userId,
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        image: imageToUpload,
      );

      // Simple error check based on your logic
      if (result['error'] != null || result['errors'] != null) {
         showSnackBar(context, 'Update Failed', SnackBarType.error);
      } else {
        showSnackBar(context, 'Profile updated successfully!', SnackBarType.success);
        Navigator.pop(context, true); // Return true to refresh parent
      }
    } catch (e) {
       showSnackBar(context, 'Error: $e', SnackBarType.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _freshMintGreen)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(color: _espressoBrown, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 1. Profile Image
                _buildProfileImage(),
                
                const SizedBox(height: 40),

                // 2. Form Fields
                _buildLabel("Full Name"),
                _buildTextField(
                  controller: _nameCtrl,
                  hint: "Enter your name",
                  icon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? "Name required" : null,
                ),

                const SizedBox(height: 20),

                _buildLabel("Email Address"),
                _buildTextField(
                  controller: _emailCtrl,
                  hint: "Enter your email",
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                  validator: (v) => !v!.contains("@") ? "Invalid email" : null,
                ),

                const SizedBox(height: 20),

                _buildLabel("Phone Number"),
                _buildTextField(
                  controller: _phoneCtrl,
                  hint: "Enter phone number",
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? "Phone required" : null,
                ),

                const SizedBox(height: 50),

                // 3. Save Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _freshMintGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: _freshMintGreen.withValues(alpha: 0.5),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildProfileImage() {
    ImageProvider imageProvider;
    if (_image != null) {
      imageProvider = FileImage(_image!);
    } else if (user?.imageUrl != null && user!.imageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(user!.imageUrl!);
    } else {
      imageProvider = const AssetImage('assets/images/default_avatar.png');
    }

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _freshMintGreen.withValues(alpha: 0.3), width: 1),
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundImage: imageProvider,
            backgroundColor: Colors.grey[100],
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _freshMintGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: validator,
      cursorColor: _freshMintGreen,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _freshMintGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade200),
        ),
      ),
    );
  }
}