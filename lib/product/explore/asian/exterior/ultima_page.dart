import 'package:cached_network_image/cached_network_image.dart';
import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/product/product_detail_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:c_h_p/pages/core/cart_page.dart';

class UltimaPage extends StatefulWidget {
  const UltimaPage({super.key});

  @override
  State<UltimaPage> createState() => _UltimaPageState();
}

class _UltimaPageState extends State<UltimaPage> {
  // Use a Future for a more efficient, one-time data fetch.
  Future<List<Product>> _fetchProducts() async {
    final query = FirebaseDatabase.instance
        .ref('products')
        .orderByChild('subCategory')
        .equalTo('Ultima Exterior Emulsions');

    final snapshot = await query.get();

    if (snapshot.exists && snapshot.value != null) {
      final productsMap = Map<String, dynamic>.from(snapshot.value as Map);
      List<Product> products = [];
      productsMap.forEach((key, value) {
        try {
          products.add(Product.fromMap(key, Map<String, dynamic>.from(value)));
        } catch (e) {
          debugPrint("Error parsing Ultima product: $e");
        }
      });
      // Sort products, e.g., alphabetically by name
      products.sort((a, b) => a.name.compareTo(b.name));
      return products.where((p) => p.stock > 0).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Slightly lighter background for a softer feel
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Ultima Emulsions",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        // ⭐ Makeover: Removed elevation for a flatter look
        elevation: 0,
        scrolledUnderElevation: 1, // Add subtle elevation back on scroll
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
        // Optional: Add a subtle bottom border instead of elevation
        // bottom: PreferredSize(
        //   preferredSize: Size.fromHeight(1.0),
        //   child: Container(color: Colors.grey.shade200, height: 1.0),
        // ),
      ),
      body: FutureBuilder<List<Product>>(
        future: _fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer();
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text("No products found in this category."));
          }

          final ultimaProducts = snapshot.data!;

          // GridView remains the layout structure
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ultimaProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              // ⭐ Makeover: Adjusted aspect ratio slightly for better text fit
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final product = ultimaProducts[index];
              return _buildProductCard(context, product)
                  .animate()
                  .fadeIn(duration: 500.ms, delay: (100 * index).ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut);
            },
          );
        },
      ),
    );
  }

  // ⭐ MAKEOVER: Updated card with more rounding and softer shadow
  Widget _buildProductCard(BuildContext context, Product product) {
    final priceToShow =
        product.packSizes.isNotEmpty ? product.packSizes.first.price : 'N/A';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailPage(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          // ⭐ Makeover: Increased corner radius
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            // ⭐ Makeover: Softer shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ClipRRect(
          // ⭐ Makeover: Match the increased radius
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with Hero Animation
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Hero(
                  tag: 'product_image_${product.key}',
                  child: CachedNetworkImage(
                    imageUrl: product.mainImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey.shade200),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Iconsax.gallery_slash,
                          size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              // Product Details
              Padding(
                // ⭐ Makeover: Slightly adjusted padding
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight:
                              FontWeight.w600), // Slightly adjusted font size
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8), // Increased spacing
                    Text(
                      'MRP ₹$priceToShow',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated shimmer to match the new rounded card style
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.68, // Match the card aspect ratio
        ),
        itemBuilder: (context, index) {
          // ⭐ Makeover: Shimmer matches the increased radius
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          );
        },
      ),
    );
  }
}
