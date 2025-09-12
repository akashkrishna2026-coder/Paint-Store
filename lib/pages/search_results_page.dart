import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../product/product_detail_page.dart'; // Import the detail page

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;
  const SearchResultsPage({super.key, required this.searchQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('products');
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _suggestedProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndFilterProducts();
  }

  // ⭐ THIS FUNCTION HAS BEEN CORRECTED TO FIX THE TYPE ERROR ⭐
  Future<void> _fetchAndFilterProducts() async {
    try {
      final snapshot = await _dbRef.get();
      if (snapshot.exists) {
        final productsMap = Map<String, dynamic>.from(snapshot.value as Map);
        final allProducts = productsMap.values.toList();

        // Ensure each item in the list is correctly cast to the expected type.
        final typedAllProducts = allProducts.map((product) => Map<String, dynamic>.from(product as Map)).toList();

        final filteredProducts = typedAllProducts.where((product) {
          final productName = (product['name'] as String?)?.toLowerCase() ?? '';
          return productName.contains(widget.searchQuery.toLowerCase());
        }).toList();

        if (mounted) {
          setState(() {
            _searchResults = filteredProducts;
            if (_searchResults.isEmpty) {
              _suggestedProducts = typedAllProducts.take(4).toList();
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error searching products: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ⭐ THEME UPDATED HERE ⭐
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Results for "${widget.searchQuery}"', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : _searchResults.isNotEmpty
          ? _buildResultsGridView(_searchResults)
          : _buildNoResultsView(),
    );
  }

  Widget _buildResultsGridView(List<Map<String, dynamic>> products) {
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
        final product = products[index];
        return _buildProductCard(context, product);
      },
    );
  }

  Widget _buildNoResultsView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Icon(Iconsax.search_status_1, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          'No Results Found',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 8),
        Text(
          'We couldn\'t find any products matching your search for "${widget.searchQuery}".',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
        ),
        if (_suggestedProducts.isNotEmpty) ...[
          const SizedBox(height: 40),
          Text(
            'You Might Also Like',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
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
              final product = _suggestedProducts[index];
              return _buildProductCard(context, product);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final String title = product['name'] ?? 'No Title';
    final String description = product['description'] ?? '';
    final String imageUrl = product['imageUrl'] ?? '';
    final String price = '₹${product['price'] ?? '0.00'}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Iconsax.gallery_slash, size: 40, color: Colors.grey)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            price,
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                          ),
                          SizedBox(
                            height: 36,
                            width: 36,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("$title added to cart")),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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

