import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../model/product_model.dart';
import '../product_detail_page.dart';

class ProductDisplayPage extends StatelessWidget {
  final String title;
  final String? category;
  final String? subCategory;

  const ProductDisplayPage({
    super.key,
    required this.title,
    this.category,
    this.subCategory,
  });

  @override
  Widget build(BuildContext context) {
    // Build the query based on the provided filters
    Query query = FirebaseDatabase.instance.ref('products');
    if (category != null) {
      query = query.orderByChild('category').equalTo(category);
    } else if (subCategory != null) {
      query = query.orderByChild('subCategory').equalTo(subCategory);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: query.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading products."));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _buildEmptyState();
          }

          final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          List<Product> products = [];
          productsMap.forEach((key, value) {
            products.add(Product.fromMap(key, Map<String, dynamic>.from(value)));
          });

          // HIDE OUT OF STOCK: Filter the list to only show items with stock > 0
          final inStockProducts = products.where((p) => p.stock > 0).toList();

          if (inStockProducts.isEmpty) {
            return _buildEmptyState(isOutOfStock: true);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: inStockProducts.length,
            itemBuilder: (context, index) {
              final product = inStockProducts[index];
              return _buildProductListItem(context, product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductListItem(BuildContext context, Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                  errorWidget: (c, e, s) => const Icon(Iconsax.gallery_slash),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${product.price}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.deepOrange),
                    ),
                  ],
                ),
              ),
              const Icon(Iconsax.arrow_right_3, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isOutOfStock = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.box_search, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            isOutOfStock ? "Products Temporarily Unavailable" : "No Products Found",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 4),
          Text(
            isOutOfStock ? "Please check back later." : "There are no products listed in this category yet.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}