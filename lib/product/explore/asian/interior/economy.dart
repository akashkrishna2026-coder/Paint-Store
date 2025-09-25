import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/product/product_detail_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EconomyPaintsPage extends StatelessWidget {
  const EconomyPaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Query productsQuery = FirebaseDatabase.instance
        .ref('products')
        .orderByChild('subCategory')
        .equalTo('Economy');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Economy Paints", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: productsQuery.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No 'Economy' products found."));
          }

          final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          List<Product> economyProducts = [];
          productsMap.forEach((key, value) {
            economyProducts.add(Product.fromMap(key, Map<String, dynamic>.from(value)));
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: economyProducts.length,
            itemBuilder: (context, index) {
              final product = economyProducts[index];
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