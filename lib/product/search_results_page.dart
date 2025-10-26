import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../model/product_model.dart';
import '../product/product_detail_page.dart';
import 'package:c_h_p/pages/core/cart_page.dart';

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;
  const SearchResultsPage({super.key, required this.searchQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  List<Product> _searchResults = [];
  List<Product> _suggestedProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndFilterProducts();
  }

  Future<void> _fetchAndFilterProducts() async {
    try {
      final snapshot = await _dbRef.child('products').get();
      if (snapshot.exists && snapshot.value is Map) {
        final productsMap = Map<String, dynamic>.from(snapshot.value as Map);
        final List<Product> allProducts = [];

        productsMap.forEach((key, value) {
          try {
            allProducts.add(Product.fromMap(key, Map<String, dynamic>.from(value)));
          } catch (e) {
            debugPrint('Error parsing product with key $key: $e');
          }
        });

        final filteredProducts = allProducts.where((product) {
          final query = widget.searchQuery.toLowerCase();
          // Safely check nullable fields
          final nameMatch = product.name.toLowerCase().contains(query);
          final categoryMatch = (product.category ?? '').toLowerCase().contains(query);
          final subCategoryMatch = (product.subCategory ?? '').toLowerCase().contains(query);

          return nameMatch || categoryMatch || subCategoryMatch;
        }).toList();

        if (mounted) {
          setState(() {
            _searchResults = filteredProducts;
            if (_searchResults.isEmpty) {
              // Suggest some other products if no results are found
              _suggestedProducts = allProducts..shuffle();
              _suggestedProducts = _suggestedProducts.take(4).toList();
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error searching products: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addToCart(Product product) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to add items to your cart.")),
      );
      return;
    }

    final cartRef = _dbRef.child('users/${user.uid}/cart/${product.key}');
    final messenger = ScaffoldMessenger.of(context);

    try {
      final snapshot = await cartRef.get();
      if (snapshot.exists && snapshot.value is Map) {
        final cartData = Map<String, dynamic>.from(snapshot.value as Map);
        int currentQuantity = cartData['quantity'] ?? 0;
        await cartRef.update({'quantity': currentQuantity + 1});
      } else {
        // ⭐ FIX: Save cart item using the correct new data structure
        await cartRef.set({
          'name': product.name,
          'mainImageUrl': product.mainImageUrl,
          'packSizes': product.packSizes.asMap().map((_, p) => MapEntry(p.size.replaceAll(RegExp(r'\s+L'), 'L'), p.price)),
          'quantity': 1,
        });
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text("${product.name} added to cart!"),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Failed to add to cart: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Results for "${widget.searchQuery}"', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.shopping_cart),
            tooltip: 'Cart',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : _searchResults.isNotEmpty
          ? _buildResultsGridView(_searchResults)
          : _buildNoResultsView(),
    );
  }

  Widget _buildResultsGridView(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        return _buildProductCard(context, products[index])
            .animate()
            .fade(duration: 500.ms, delay: (100 * index).ms)
            .slideY(begin: 0.2, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildNoResultsView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Icon(Iconsax.search_status_1, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        Text('No Results Found', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('We couldn\'t find any products matching "${widget.searchQuery}".', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
        if (_suggestedProducts.isNotEmpty) ...[
          const SizedBox(height: 40),
          Text('You Might Also Like', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suggestedProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemBuilder: (context, index) {
              return _buildProductCard(context, _suggestedProducts[index]);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    // Safely get the price of the first pack size to display
    final priceToShow = product.packSizes.isNotEmpty ? product.packSizes.first.price : 'N/A';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)));
      },
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: Hero(
                  tag: 'product_image_${product.key}',
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CachedNetworkImage(
                          imageUrl: product.mainImageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 160),
                          memCacheWidth: 400,
                          placeholder: (context, url) => Container(color: Colors.grey.shade200),
                          errorWidget: (c, e, s) => const Center(child: Icon(Iconsax.gallery_slash, size: 36, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ⭐ FIX: Display the starting price
                          Text('MRP ₹$priceToShow', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                          SizedBox(
                            height: 36,
                            width: 36,
                            child: ElevatedButton(
                              onPressed: () => _addToCart(product),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Icon(Iconsax.shopping_bag, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}