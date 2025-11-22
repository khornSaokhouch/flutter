import 'package:flutter/material.dart';
import 'package:frontend/screen/shops/screens/shops_categories_page.dart';

import '../../../response/shops_response/shop_response.dart';
import '../../../server/shops_server/shop_service.dart';
import '../widgets/shop_card_widgets.dart';

class ShopsHomePage extends StatefulWidget {
  final String userId;

  const ShopsHomePage({super.key, required this.userId});

  @override
  State<ShopsHomePage> createState() => _ShopsHomePageState();
}

class _ShopsHomePageState extends State<ShopsHomePage> {
  late Future<ShopResponse> _futureShops;

  @override
  void initState() {
    super.initState();
    // ✅ Make sure the service name matches your actual class
    _futureShops = ShopsService.getShopsByOwner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Home')),
      body: FutureBuilder<ShopResponse>(
        future: _futureShops,
        builder: (context, snapshot) {
          // 🔄 Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Error state
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          // ⚠️ No data or empty list
          if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
            return const Center(child: Text("No shops found"));
          }

          final shops = snapshot.data!.data;

          // ✅ Success
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👇 Pass the shops list into the card widget
              Expanded(
                child:OwnerShopsCard(
                  shops: shops,
                  onTap: (shopId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopsCategoriesPage(shopId: shopId),
                      ),
                    );
                  },
                )

              ),
            ],
          );
        },
      ),
    );
  }
}
