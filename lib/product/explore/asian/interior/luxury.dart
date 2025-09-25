import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/product/product_detail_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoyaleGlitzPage extends StatelessWidget {
  const RoyaleGlitzPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Query by sub-category for "Luxury" and specifically by brand if needed
    // For this specific product, querying by subCategory 'Luxury' is sufficient
    final Query productsQuery = FirebaseDatabase.instance
        .ref('products')
        .orderByChild('subCategory')
        .equalTo('Luxury');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Luxury Paints", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: productsQuery.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "No 'Luxury' products found.\nPlease ensure they are assigned the correct sub-category in the manager panel.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          List<Product> luxuryProducts = [];
          productsMap.forEach((key, value) {
            final product = Product.fromMap(key, Map<String, dynamic>.from(value));
            // Filter specifically for "Royale Glitz" if you want only this product
            if (product.name.toLowerCase() == "royale glitz") {
              luxuryProducts.add(product);
            }
          });

          if (luxuryProducts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "Royale Glitz not found.\nPlease add it from the manager panel or Firebase console.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: luxuryProducts.length,
            itemBuilder: (context, index) {
              final product = luxuryProducts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Image.network(product.imageUrl, width: 70, height: 70, fit: BoxFit.cover),
                  title: Text(product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text('Stock: ${product.stock}', style: GoogleFonts.poppins()),
                  trailing: Text('₹${product.price}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}