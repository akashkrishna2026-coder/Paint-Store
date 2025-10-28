import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/product/product_detail_page.dart';
import 'package:c_h_p/product/indigo_product_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:c_h_p/pages/core/cart_page.dart';

class ProductDisplayPage extends StatefulWidget {
  final String title;
  final String? category;
  final String? subCategory;
  final String? brand; // Optional brand filter

  const ProductDisplayPage({
    super.key,
    required this.title,
    this.category,
    this.subCategory,
    this.brand,
  });

  @override
  State<ProductDisplayPage> createState() => _ProductDisplayPageState();
}

class _ProductDisplayPageState extends State<ProductDisplayPage> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  // This function fetches all products and filters them based on the provided category or sub-category.
  Future<List<Product>> _fetchProducts() async {
    Query query = FirebaseDatabase.instance.ref('products');
    // Prefer querying by category (more common) and filter others client-side
    if (widget.category != null) {
      query = query.orderByChild('category').equalTo(widget.category);
    } else if (widget.subCategory != null) {
      query = query.orderByChild('subCategory').equalTo(widget.subCategory);
    }

    final snapshot = await query.get();

    if (snapshot.exists && snapshot.value != null) {
      final productsMap = Map<String, dynamic>.from(snapshot.value as Map);
      List<Product> products = [];
      productsMap.forEach((key, value) {
        try {
          products.add(Product.fromMap(key, Map<String, dynamic>.from(value)));
        } catch (e) {
          debugPrint("Error parsing product in ProductDisplayPage: $e");
        }
      });

      var list = products.where((p) => p.stock > 0).toList();

      // If both category and subCategory are provided, also filter by subCategory here
      if (widget.category != null && widget.subCategory != null && widget.subCategory!.isNotEmpty) {
        list = list.where((p) => (p.subCategory ?? '') == widget.subCategory).toList();
      }

      // Apply optional brand filter client-side
      if (widget.brand != null && widget.brand!.isNotEmpty) {
        final b = widget.brand!.toLowerCase();
        list = list.where((p) {
          final pb = (p.brand ?? '').toLowerCase();
          return pb == b || pb.startsWith(b);
        }).toList();
      }

      list.sort((a, b) => a.name.compareTo(b.name));
      // Precache the first few images to reduce on-screen flicker
      final precacheCount = list.length > 6 ? 6 : list.length;
      for (int i = 0; i < precacheCount; i++) {
        final url = list[i].mainImageUrl;
        if (url.isNotEmpty && mounted) {
          final provider = CachedNetworkImageProvider(url);
          // ignore: use_build_context_synchronously
          precacheImage(provider, context);
        }
      }
      return list;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
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
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer();
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final inStockProducts = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            cacheExtent: 1200,
            itemCount: inStockProducts.length,
            itemBuilder: (context, index) {
              final product = inStockProducts[index];
              return KeyedSubtree(
                key: ValueKey('prod_${product.key}'),
                child: _buildProductListItem(context, product, index: index),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductListItem(BuildContext context, Product product, {int? index}) {
    // Determine a sensible starting price: use the minimum numeric price among pack sizes
    String priceToShow = 'N/A';
    String smallestSizeLabel = '';
    if (product.packSizes.isNotEmpty) {
      double? minPrice;
      for (final ps in product.packSizes) {
        final cleaned = ps.price.replaceAll(RegExp('[^0-9\\.]'), '');
        final val = double.tryParse(cleaned);
        if (val != null) {
          if (minPrice == null || val < minPrice) minPrice = val;
        }
      }
      if (minPrice != null) {
        // Format without trailing .0
        priceToShow = minPrice.toStringAsFixed(minPrice % 1 == 0 ? 0 : 2);
      }
      // Smallest size label using numericSize
      final sortedBySize = [...product.packSizes]..sort((a, b) => a.numericSize.compareTo(b.numericSize));
      smallestSizeLabel = sortedBySize.first.size;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                final brand = (product.brand ?? '').toLowerCase();
                if (brand.startsWith('indigo')) {
                  return IndigoProductDetailPage(product: product);
                }
                return ProductDetailPage(product: product);
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // ⭐ FIX: Added Hero widget for smooth image transition
              Hero(
                tag: 'product_image_${product.key}',
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.white,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CachedNetworkImage(
                          imageUrl: product.mainImageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 160),
                          memCacheWidth: 300,
                          memCacheHeight: 300,
                          placeholder: (context, url) => Container(color: Colors.grey.shade200),
                          errorWidget: (c, e, s) => const Center(child: Icon(Iconsax.gallery_slash)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Starting price and smallest pack size
                    Row(
                      children: [
                        if (smallestSizeLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.deepOrange.shade100),
                            ),
                            child: Text(smallestSizeLabel, style: GoogleFonts.poppins(fontSize: 12, color: Colors.deepOrange.shade700)),
                          ),
                        if (smallestSizeLabel.isNotEmpty) const SizedBox(width: 8),
                        Text(
                          'MRP  ₹$priceToShow',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.deepOrange.shade700),
                        ),
                      ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/empty.json', // Make sure you have this file in your assets
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 16),
            Text(
              "No Products Found",
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              "It seems there are no products available in this category at the moment. Please check back later!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5, // Show 5 skeleton items
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 20, width: double.infinity, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 14, width: double.infinity, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(height: 14, width: 150, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 18, width: 80, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}