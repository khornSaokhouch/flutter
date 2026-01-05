import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/models/shop.dart';
import 'package:frontend/server/shop_service.dart';
import 'package:frontend/response/shops_response/shop_response.dart';
import '../../../server/shops_server/shop_service.dart';

class EditInfoPage extends StatefulWidget {
  final int shopId;
  const EditInfoPage({super.key, required this.shopId});

  @override
  State<EditInfoPage> createState() => _EditInfoPageState();
}

class _EditInfoPageState extends State<EditInfoPage> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage; // To store the newly picked image file

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _googleMapUrlController;
  late TextEditingController _openTimeController;
  late TextEditingController _closeTimeController;

  late Future<Shop?> _shopFuture;
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _shopFuture = ShopService.fetchShopById(widget.shopId);
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _locationController.dispose();
      _googleMapUrlController.dispose();
      _openTimeController.dispose();
      _closeTimeController.dispose();
    }
    super.dispose();
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    // Prepare text payload
    final payload = {
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'google_map_url': _googleMapUrlController.text.trim(),
      'open_time': _openTimeController.text.trim(),
      'close_time': _closeTimeController.text.trim(),
    };

    try {
      // NOTE: Ensure your ShopsService.updateShop accepts a File? imageFile parameter
      final ShopResponse response = await ShopsService.updateShop(
        shopId: widget.shopId,
        payload: payload,
        imageFile: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Shop updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Optional: return to previous page
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      // Format to HH:mm (24h) to match Laravel validation regex
      final String formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Shop Info', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Shop?>(
        future: _shopFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Shop details not found.'));
          }

          final shop = snapshot.data!;

          if (!_initialized) {
            _nameController = TextEditingController(text: shop.name);
            _locationController = TextEditingController(text: shop.location);
            _googleMapUrlController = TextEditingController(text: shop.googleMapUrl ?? '');
            _openTimeController = TextEditingController(text: shop.openTime ?? '');
            _closeTimeController = TextEditingController(text: shop.closeTime ?? '');
            _initialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // --- IMAGE SELECTOR SECTION ---
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue.shade100, width: 4),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: _selectedImage != null
                                  ? FileImage(_selectedImage!) as ImageProvider
                                  : NetworkImage(shop.imageUrl ?? 'https://via.placeholder.com/150'),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              radius: 20,
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildSectionTitle('General Information'),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Shop Name',
                    icon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _locationController,
                    label: 'Address / Location',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _googleMapUrlController,
                    label: 'Google Maps Link',
                    icon: Icons.map_outlined,
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Business Hours'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(_openTimeController, 'Opening Time'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeField(_closeTimeController, 'Closing Time'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- SAVE BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildTimeField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectTime(context, controller),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.access_time_rounded),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}