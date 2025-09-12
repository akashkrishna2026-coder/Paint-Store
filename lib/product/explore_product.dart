import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ExploreProductPage extends StatefulWidget {
  const ExploreProductPage({super.key});

  @override
  State<ExploreProductPage> createState() => _ExploreProductPageState();
}

class _ExploreProductPageState extends State<ExploreProductPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- NEW: Add to Cart Logic ---
  Future<void> _addToCart(String productKey, Map<String, dynamic> product) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to add items to your cart.")),
      );
      return;
    }

    final cartRef = _dbRef.child('users/${user.uid}/cart/$productKey');

    try {
      final snapshot = await cartRef.get();
      if (snapshot.exists) {
        // If item exists, increment quantity
        int currentQuantity = (snapshot.value as Map)['quantity'] ?? 0;
        await cartRef.update({'quantity': currentQuantity + 1});
      } else {
        // If item doesn't exist, add it with quantity 1
        await cartRef.set({
          'name': product['name'],
          'price': product['price'],
          'imageUrl': product['imageUrl'],
          'quantity': 1,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${product['name']} added to cart!")),
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Explore Products", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: StreamBuilder(
        stream: _dbRef.child('products').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(child: Text("No products available.", style: GoogleFonts.poppins()));
          }

          final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          // MODIFIED: We now use .entries to get both the key and the value
          final productsList = productsMap.entries.toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: productsList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemBuilder: (context, index) {
              final productEntry = productsList[index];
              final productKey = productEntry.key;
              final productData = Map<String, dynamic>.from(productEntry.value);
              return _buildProductCard(context, productKey, productData);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, String productKey, Map<String, dynamic> product) {
    final String title = product['name'] ?? 'No Title';
    final String description = product['description'] ?? 'No description';
    final String imageUrl = product['imageUrl'] ?? '';
    final String price = '₹${product['price'] ?? '0.00'}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
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
                        Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(description, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(price, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        SizedBox(
                          height: 36,
                          width: 36,
                          child: ElevatedButton(
                            onPressed: () => _addToCart(productKey, product), // Use the new function
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
    );
  }
}
