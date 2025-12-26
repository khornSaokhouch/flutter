import 'package:flutter/material.dart';
import '../../../models/item_model.dart';
import '../../../server/item_service.dart';
import './detail_item.dart';

class SearchPage extends StatefulWidget {
  final int shopId;
  final int? userId;

  const SearchPage({super.key, required this.shopId, this.userId});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Item> _allItems = [];
  List<Item> _foundItems = [];

  bool _isLoading = true;
  bool _hasError = false;

  // Modern Green Palette
  final Color _primaryGreen = const Color(0xFF2E7D32);
  final Color _accentGreen = const Color(0xFF4CAF50);
  final Color _bgGrey = const Color(0xFFF8F9FA);

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
          .where((item) => item.name.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }
    setState(() {
      _foundItems = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER & SEARCH BAR
            _buildHeader(),

            // 2. RESULTS LIST
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _primaryGreen))
                  : _hasError
                      ? _buildStatusMessage(Icons.error_outline, "Error loading items")
                      : _foundItems.isEmpty
                          ? _buildStatusMessage(Icons.search_off_rounded, "No items found")
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              itemCount: _foundItems.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) => _buildItemCard(_foundItems[index]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: _primaryGreen,
          ),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: _bgGrey,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _runFilter,
                decoration: InputDecoration(
                  hintText: "Search your favorite coffee...",
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: _primaryGreen, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _runFilter('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(IconData icon, String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildItemCard(Item item) {
    double price = item.priceCents / 100;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GuestDetailItem(
              shopId: widget.shopId,
              itemId: item.id,
              userId: widget.userId,
            ),
          ),
        );
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // IMAGE
            Padding(
              padding: const EdgeInsets.all(10),
              child: Hero(
                tag: 'item-image-${item.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: _bgGrey,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.coffee, color: _primaryGreen),
                    ),
                  ),
                ),
              ),
            ),
            
            // DETAILS
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Premium Brew", // Or item.description
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    Text(
                      "\$${price.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16,
                        color: _primaryGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ACTION BUTTON
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: _primaryGreen, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}