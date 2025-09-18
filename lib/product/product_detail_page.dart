// lib/product/product_detail_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../model/product_model.dart'; // ⭐ USE THE PRODUCT MODEL

class ProductDetailPage extends StatelessWidget {
  final Product product; // ⭐ USE THE PRODUCT MODEL

  const ProductDetailPage({super.key, required this.product});

  // ⭐ ADD TO CART LOGIC
  Future<void> _addToCart(BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to add items to your cart.")),
      );
      return;
    }

    final cartRef = FirebaseDatabase.instance.ref('users/${user.uid}/cart/${product.key}');

    try {
      final snapshot = await cartRef.get();
      if (snapshot.exists) {
        // If item exists, increment quantity
        int currentQuantity = (snapshot.value as Map)['quantity'] ?? 0;
        await cartRef.update({'quantity': currentQuantity + 1});
      } else {
        // If item doesn't exist, set it with quantity 1
        await cartRef.set({
          'name': product.name,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'quantity': 1,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${product.name} added to cart!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add to cart: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: Colors.deepOrange,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Iconsax.gallery_slash, size: 50, color: Colors.grey)),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${product.price}',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Description",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade600, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton.icon(
          onPressed: () => _addToCart(context), // ⭐ CALL THE FUNCTION
          icon: const Icon(Iconsax.shopping_bag, size: 20),
          label: Text("Add to Cart", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}