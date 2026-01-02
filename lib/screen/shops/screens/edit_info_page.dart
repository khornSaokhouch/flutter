import 'package:flutter/material.dart';
import 'package:frontend/models/shop.dart';
import 'package:frontend/server/shop_service.dart';

class EditInfoPage extends StatefulWidget {
  final int shopId;
  const EditInfoPage({super.key, required this.shopId});

  @override
  State<EditInfoPage> createState() => _EditInfoPageState();
}

class _EditInfoPageState extends State<EditInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _imageUrlController;
  late TextEditingController _googleMapUrlController;
  late TextEditingController _openTimeController;
  late TextEditingController _closeTimeController;

  late Future<Shop?> _shopFuture;
  bool _initialized = false;

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
      _imageUrlController.dispose();
      _googleMapUrlController.dispose();
      _openTimeController.dispose();
      _closeTimeController.dispose();
    }
    super.dispose();
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameController.text,
        'location': _locationController.text,
        'image_url': _imageUrlController.text,
        'google_map_url': _googleMapUrlController.text,
        'open_time': _openTimeController.text,
        'close_time': _closeTimeController.text,
      };

      final updatedShop = await ShopService.updateShop(widget.shopId, data);

      if (updatedShop != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop information updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update shop information.')),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Shop Info'),
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.save_alt_outlined),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            ),
          ),
        ],
      ),
      body: FutureBuilder<Shop?>(
        future: _shopFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Failed to load shop data: ${snapshot.error}', textAlign: TextAlign.center,),
            ));
          } else if (snapshot.hasData) {
            final shop = snapshot.data!;
            if (!_initialized) {
              _nameController = TextEditingController(text: shop.name);
              _locationController = TextEditingController(text: shop.location);
              _imageUrlController = TextEditingController(text: shop.imageUrl);
              _googleMapUrlController = TextEditingController(text: shop.googleMapUrl);
              _openTimeController = TextEditingController(text: shop.openTime ?? '');
              _closeTimeController = TextEditingController(text: shop.closeTime ?? '');
              _initialized = true;
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text("CORE INFORMATION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Shop Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.storefront),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a shop name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text("營業時間 (BUSINESS HOURS)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _openTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Opening Time',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              readOnly: true,
                              onTap: () => _selectTime(context, _openTimeController),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _closeTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Closing Time',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.timer_off_outlined),
                              ),
                              readOnly: true,
                              onTap: () => _selectTime(context, _closeTimeController),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text("LINKS & MEDIA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _googleMapUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Google Map URL',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const Center(child: Text('Shop not found.'));
          }
        },
      ),
    );
  }
}
