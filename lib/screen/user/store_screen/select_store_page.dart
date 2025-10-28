import 'package:flutter/material.dart';
import 'store_page_screen.dart';

// 🏪 Store model
class Store {
  final String id;
  final String name;
  final String address;
  final String image;
  final String openHours;
  final double distanceKm;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.image,
    required this.openHours,
    required this.distanceKm,
  });
}

// 🏬 SelectStorePage
class SelectStorePage extends StatelessWidget {
  const SelectStorePage({Key? key, required List stores}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Store data
    final stores = [
      Store(
        id: '1',
        name: 'THE VILLA BOENG KENG KANG',
        address: '2B Street 288, Boeng Keng Kang Ti Muoy, Phnom Penh',
        image: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c',
        openHours: '06:30 AM - 06:00 PM',
        distanceKm: 0.12,
      ),
      Store(
        id: '2',
        name: 'INSTITUTE FRANCAIS',
        address: '103C12 Street 184, Boeung Rang, Phnom Penh',
        image: 'https://images.unsplash.com/photo-1570129477492-45c003edd2be',
        openHours: '06:30 AM - 08:00 PM',
        distanceKm: 0.94,
      ),

    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'SELECT STORE',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.amber)),
        ),
        actions: const [
          Icon(Icons.search, color: Colors.amber),
          SizedBox(width: 12),
          Icon(Icons.map_outlined, color: Colors.amber),
          SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StorePageScreen(store: store),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16)),
                    child: Image.network(
                      store.image,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  store.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "${store.distanceKm.toStringAsFixed(2)} km",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  store.address,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time_outlined,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                store.openHours,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StorePageScreen(store: store),
                                  ),
                                );
                              },
                              child: const Text(
                                "View >",
                                style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
      backgroundColor: const Color(0xfff7f7f7),
    );
  }
}
