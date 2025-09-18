import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../model/product_model.dart';
import '../pages/color_catalogue_page.dart';
import 'product_detail_page.dart';

class ExploreProductPage extends StatefulWidget {
  const ExploreProductPage({super.key});

  @override
  State<ExploreProductPage> createState() => _ExploreProductPageState();
}

class _ExploreProductPageState extends State<ExploreProductPage> {
  final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('products');

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
        await cartRef.set({
          'name': product.name,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'quantity': 1,
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${product.name} added to cart!")),
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Explore Products", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildColorCatalogueBanner(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: StreamBuilder<DatabaseEvent>(
              stream: _productsRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
                  );
                }
                // ⭐ FIX: Add a more robust check for different empty/error states
                if (snapshot.hasError) {
                  return const SliverToBoxAdapter(child: Center(child: Text("Error loading products.")));
                }
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null || snapshot.data!.snapshot.value is! Map) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.box_search, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text("No products have been added yet.", style: GoogleFonts.poppins()),
                          Text("Admins can add products from the Admin Panel.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final List<Product> productsList = [];
                productsMap.forEach((key, value) {
                  try {
                    // The new Product.fromMap will safely handle bad data
                    productsList.add(Product.fromMap(key, Map<String, dynamic>.from(value)));
                  } catch (e) {
                    print('Could not parse product with key $key. Error: $e');
                  }
                });

                if (productsList.isEmpty) {
                  return const SliverToBoxAdapter(child: Center(child: Text("No products available.")));
                }

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return _buildProductCard(context, productsList[index])
                          .animate()
                          .fade(duration: 500.ms, delay: (100 * index).ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut);
                    },
                    childCount: productsList.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCatalogueBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ColorCataloguePage())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepOrange, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Iconsax.color_swatch, color: Colors.deepOrange, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Color Catalogue", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                  Text("Find the perfect shade for your space", style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87)),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: Colors.deepOrange),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                  errorWidget: (c, e, s) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Iconsax.gallery_slash, size: 40, color: Colors.grey)),
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
                      Text(
                        product.description,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                          ),
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