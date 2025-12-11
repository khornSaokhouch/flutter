import 'package:flutter/material.dart';
import '../../../models/item_model.dart';
import '../../../server/item_service.dart';
import './detail_item.dart';


class SearchPage extends StatefulWidget {

  final int shopId;

  final int? userId;
  const SearchPage({super.key,required this.shopId,this.userId});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Item> _allItems = [];
  List<Item> _foundItems = [];

  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    ItemsResponse? response = await ItemService.fetchItemsByShop(widget.shopId);

    if (mounted) {
      setState(() {
        if (response != null) {
          _allItems = response.data.map((e) => e.item).toList();
          _foundItems = _allItems;
          _hasError = false;
        } else {
          _hasError = true;
        }
        _isLoading = false;
      });
    }
  }

  void _runFilter(String keyword) {
    List<Item> results = [];

    if (keyword.isEmpty) {
      results = _allItems;
    } else {
      results = _allItems
          .where((item) =>
          item.name.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _foundItems = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        onChanged: _runFilter,
                        decoration: const InputDecoration(
                          hintText: "Search items...",
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                  ? const Center(child: Text("Error loading items"))
                  : _foundItems.isEmpty
                  ? const Center(child: Text("No items found"))
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _foundItems.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildItemCard(_foundItems[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GuestDetailItem(shopId: widget.shopId, itemId: item.id, userId: widget.userId)),
        );
      },
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // TEXT
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Text(
                      "\$${(item.priceCents / 100).toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // IMAGE
            Container(
              width: 90,
              height: 90,
              padding: EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
