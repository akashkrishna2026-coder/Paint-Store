import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../model/product_model.dart';
import '../product_detail_page.dart';

class OtherProductsPage extends StatelessWidget {
  const OtherProductsPage({super.key});

  // This function fetches only the products in the 'Others' category.
  Future<List<Product>> _fetchOtherProducts() async {
    final query = FirebaseDatabase.instance
        .ref('products')
        .orderByChild('category')
        .equalTo('Others');

    final snapshot = await query.get();

    if (snapshot.exists && snapshot.value != null) {
      final productsMap = Map<String, dynamic>.from(snapshot.value as Map);
      List<Product> products = [];
      productsMap.forEach((key, value) {
        try {
          products.add(Product.fromMap(key, Map<String, dynamic>.from(value)));
        } catch (e) {
          debugPrint("Error parsing 'Other' product: $e");
        }
      });
      return products;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Other Products", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      // ⭐ FIX: Switched to FutureBuilder for better performance
      body: FutureBuilder<List<Product>>(
        future: _fetchOtherProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer();
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading products."));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No 'Other' products found."));
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductListItem(context, product);
            },
          );
        },
      ),
    );
  }

  // ⭐ FIX: This widget is now updated to use the new Product model
  Widget _buildProductListItem(BuildContext context, Product product) {
    // Safely get the price of the first pack size to display
    final priceToShow = product.packSizes.isNotEmpty ? product.packSizes.first.price : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product))),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  // ⭐ FIX: Use mainImageUrl
                  imageUrl: product.mainImageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                  errorWidget: (context, url, error) => const Icon(Iconsax.gallery_slash),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // ⭐ FIX: Display starting price
              Text(
                'MRP \n₹$priceToShow',
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.deepOrange.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shimmer loading widget for a better UX
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 8, // Number of shimmer items
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const ListTile(
              leading: SizedBox(width: 70, height: 70, child: Card()),
              title: SizedBox(height: 20, child: Card()),
              subtitle: SizedBox(height: 30, child: Card()),
            ),
          );
        },
      ),
    );
  }
}