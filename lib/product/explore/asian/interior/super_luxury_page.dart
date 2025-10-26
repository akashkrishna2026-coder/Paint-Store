import 'package:cached_network_image/cached_network_image.dart';
import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/product/product_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

class SuperLuxuryPage extends StatefulWidget {
  const SuperLuxuryPage({super.key});

  @override
  State<SuperLuxuryPage> createState() => _SuperLuxuryPageState();
}

class _SuperLuxuryPageState extends State<SuperLuxuryPage> {

  // Use a Future for a more efficient, one-time data fetch.
  Future<List<Product>> _fetchProducts() async {
    final query = FirebaseDatabase.instance
        .ref('products')
        .orderByChild('subCategory')
        .equalTo('Super Luxury');

    final snapshot = await query.get();

    if (snapshot.exists && snapshot.value != null) {
      final productsMap = Map<String, dynamic>.from(snapshot.value as Map);
      List<Product> products = [];
      productsMap.forEach((key, value) {
        // This now uses your updated Product.fromMap constructor
        products.add(Product.fromMap(key, Map<String, dynamic>.from(value)));
      });
      // Filter out any products that might be out of stock
      return products.where((p) => p.stock > 0).toList();
    }
    return []; // Return an empty list if no products are found
  }

  Future<void> _addToCart(Product product) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to add items to your cart.")),
      );
      return;
    }

    final cartRef = FirebaseDatabase.instance.ref('users/${user.uid}/cart/${product.key}');
    try {
      final snapshot = await cartRef.get();
      if (snapshot.exists && snapshot.value is Map) {
        final cartItemData = Map<String, dynamic>.from(snapshot.value as Map);
        int currentQuantity = cartItemData['quantity'] ?? 0;
        await cartRef.update({'quantity': currentQuantity + 1});
      } else {
        // ⭐ FIX: Save cart item using the new data structure
        await cartRef.set({
          'name': product.name,
          'mainImageUrl': product.mainImageUrl,
          // Storing pack sizes in the cart might be useful later
          'packSizes': product.packSizes.asMap().map((_, p) => MapEntry(p.size.replaceAll(' ', ''), p.price)),
          'quantity': 1,
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${product.name} added to cart!"),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add to cart: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Super Luxury Paints",
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: FutureBuilder<List<Product>>(
        future: _fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer(); // Show a shimmer skeleton while loading
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final superLuxuryProducts = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: superLuxuryProducts.length,
            itemBuilder: (context, index) {
              final product = superLuxuryProducts[index];
              return _buildProductCard(context, product)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: (150 * index).ms)
                  .moveX(begin: -30, duration: 600.ms, curve: Curves.easeOutCubic);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    // Safely get the price of the first pack size to display, or show 'N/A' if none exist
    final priceToShow = product.packSizes.isNotEmpty ? product.packSizes.first.price : 'N/A';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              // ⭐ FIX: Use mainImageUrl from the updated product model
              child: CachedNetworkImage(
                imageUrl: product.mainImageUrl,
                fit: BoxFit.cover,
                width: 130,
                height: double.infinity,
                placeholder: (context, url) => Container(color: Colors.grey.shade100),
                errorWidget: (c, e, s) => Container(
                  color: Colors.grey.shade100,
                  child: Center(child: Icon(Iconsax.gallery_slash, size: 40, color: Colors.grey.shade400)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // ⭐ FIX: Show the starting price from the pack sizes
                        Text(
                          'MRP ₹$priceToShow',
                          style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF3A3A3A)),
                        ),
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: ElevatedButton(
                            onPressed: () => _addToCart(product),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Icon(Iconsax.shopping_bag, size: 20),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box_search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              "No Products Available",
              style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              "It seems there are no products in this category at the moment. Please check back later.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 20),
            Text(
              "Something Went Wrong",
              style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              "We couldn't load the products. Please check your connection and try again.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: 5, // Number of shimmer items to show
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}