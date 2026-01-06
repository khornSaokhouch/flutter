import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/models/shop.dart';
import '../../../server/shops_server/shop_service.dart';
import 'package:frontend/response/shops_response/shop_response.dart';
import 'package:frontend/server/shop_service.dart' as fetchService;
import 'maps/location_picker_page.dart';

class EditInfoPage extends StatefulWidget {
  final int shopId;
  const EditInfoPage({super.key, required this.shopId});

  @override
  State<EditInfoPage> createState() => _EditInfoPageState();
}

class _EditInfoPageState extends State<EditInfoPage> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _openTimeController;
  late TextEditingController _closeTimeController;

  double? _lat;
  double? _lng;

  late Future<Shop?> _shopFuture;
  bool _initialized = false;
  bool _saving = false;

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color bgGrey = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _shopFuture = fetchService.ShopService.fetchShopById(widget.shopId);
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _addressController.dispose();
      _openTimeController.dispose();
      _closeTimeController.dispose();
    }
    super.dispose();
  }

  // Helper to parse "HH:mm" string to TimeOfDay
  TimeOfDay _parseTime(String timeStr) {
    try {
      if (timeStr.isEmpty) return TimeOfDay.now();
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
  }

  Future<void> _openMapPicker() async {
    LatLng initial = LatLng(_lat ?? 11.5564, _lng ?? 104.9282);

    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationPickerPage(initialCenter: initial)),
    );

    if (result != null) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("GPS Coordinates Updated!"), backgroundColor: primaryGreen),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pin a location on the map"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _saving = true);

    final payload = {
      'name': _nameController.text.trim(),
      'location': _addressController.text.trim(),
      'latitude': _lat.toString(),
      'longitude': _lng.toString(),
      'open_time': _openTimeController.text.trim(),
      'close_time': _closeTimeController.text.trim(),
    };

    try {
      final ShopResponse response = await ShopsService.updateShop(
        shopId: widget.shopId,
        payload: payload,
        imageFile: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: primaryGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Branch Profile', 
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Shop?>(
        future: _shopFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          
          final shop = snapshot.data;
          if (shop == null) return const Center(child: Text("Shop not found"));

          if (!_initialized) {
            _nameController = TextEditingController(text: shop.name);
            _addressController = TextEditingController(text: shop.location);
            _openTimeController = TextEditingController(text: shop.openTime ?? '');
            _closeTimeController = TextEditingController(text: shop.closeTime ?? '');
            _lat = shop.latitude;
            _lng = shop.longitude;
            _initialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  
                  // IMAGE SECTION
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 130, height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15)],
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: _selectedImage != null
                                  ? FileImage(_selectedImage!) as ImageProvider
                                  : NetworkImage(shop.imageUrl ?? 'https://via.placeholder.com/150'),
                            ),
                          ),
                        ),
                        Positioned(bottom: 0, right: 0, child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            backgroundColor: primaryGreen, 
                            radius: 18, 
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16)
                          ),
                        )),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  _buildSectionTitle('General Information'),

                  _buildTextField(
                    controller: _nameController, 
                    label: 'Shop Name', 
                    icon: Icons.store_rounded
                  ),
                  const SizedBox(height: 20),

                  // MANUAL ADDRESS INPUT
                  _buildTextField(
                    controller: _addressController,
                    label: 'Physical Address (Street/Building)',
                    icon: Icons.location_city_rounded,
                  ),

                  const SizedBox(height: 20),

                  // MAP PICKER BUTTON
                  _buildSectionTitle('Map Location'),
                  InkWell(
                    onTap: _openMapPicker,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: bgGrey,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.map_rounded, color: primaryGreen),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lat != null ? "Location Pinned" : "Select Location",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (_lat != null)
                                  Text(
                                    "${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}",
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.edit_location_alt_rounded, color: primaryGreen, size: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  _buildSectionTitle('Operating Hours'),
                  Row(
                    children: [
                      Expanded(child: _buildTimeField(_openTimeController, 'Opens')),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTimeField(_closeTimeController, 'Closes')),
                    ],
                  ),

                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: _saving 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Text(title.toUpperCase(), 
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey[400], letterSpacing: 1.5)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextFormField(
      controller: controller,
      readOnly: false,
      enabled: true,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen, size: 20),
        filled: true, fillColor: bgGrey,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryGreen)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildTimeField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(fontWeight: FontWeight.bold),
      onTap: () async {
        FocusScope.of(context).unfocus();

        final TimeOfDay initial = _parseTime(controller.text);

        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: initial,
          useRootNavigator: false,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: Colors.white,

                  // Hour / minute box
                  hourMinuteColor: primaryGreen.withOpacity(0.15),
                  hourMinuteTextColor: primaryGreen,

                  // AM / PM
                  dayPeriodColor: primaryGreen.withOpacity(0.15),
                  dayPeriodTextColor: primaryGreen,
                  dayPeriodBorderSide:
                  BorderSide(color: primaryGreen),

                  // Dial
                  dialHandColor: primaryGreen,
                  dialBackgroundColor:
                  primaryGreen.withOpacity(0.08),
                  dialTextColor: Colors.black,

                  // Buttons
                  confirmButtonStyle: TextButton.styleFrom(
                    foregroundColor: primaryGreen,
                    textStyle:
                    const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  cancelButtonStyle: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
                colorScheme: ColorScheme.light(
                  primary: primaryGreen,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          setState(() {
            controller.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          });
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          Icons.access_time_filled_rounded,
          color: primaryGreen,
          size: 20,
        ),
        filled: true,
        fillColor: bgGrey,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primaryGreen),
        ),
      ),
    );
  }

}