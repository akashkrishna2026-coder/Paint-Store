// lib/product/explore/other_products_page.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../model/product_model.dart';
import '../product_detail_page.dart';

class OtherProductsPage extends StatelessWidget {
  const OtherProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // This query specifically looks for products where the 'category' is 'Others'
    final Query productsQuery = FirebaseDatabase.instance
        .ref('products')
        .orderByChild('category')
        .equalTo('Others');

    return Scaffold(
      appBar: AppBar(
        title: Text("Other Products", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: productsQuery.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No 'Other' products found."));
          }

          final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final List<Product> products = [];
          productsMap.forEach((key, value) {
            products.add(Product.fromMap(key, Map<String, dynamic>.from(value)));
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: Image.network(product.imageUrl, width: 70, height: 70, fit: BoxFit.cover),
                  title: Text(product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis),
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