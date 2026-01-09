import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../model/product_model.dart';
import '../product/product_detail_page.dart';

// Helper to convert hex strings to Color objects
Color hexToColor(String code) {
  try {
    final hex = code.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.grey.shade300;
  } catch (e) {
    return Colors.grey.shade300;
  }
}

//==============================================================================
// Main Color Catalogue Page
//==============================================================================

class ColorCataloguePage extends StatefulWidget {
  const ColorCataloguePage({super.key});

  @override
  State<ColorCataloguePage> createState() => _ColorCataloguePageState();
}

class _ColorCataloguePageState extends State<ColorCataloguePage> {
  List<Map<String, String>> _allShades = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
  }

  // Data is provided by ColorCatalogueViewModel via Riverpod.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Color Catalogue",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: FutureBuilder<DataSnapshot>(
        future: FirebaseDatabase.instance.ref('colorCategories').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange));
          }
          if (!snapshot.hasData || snapshot.data!.value == null) {
            return const Center(child: Text("Color catalogue is empty."));
          }

          final data = Map<String, dynamic>.from(snapshot.data!.value as Map);

          // Build categories and shades from DB
          final Set<String> categoriesSet = {'All'};
          final List<Map<String, String>> allShades = [];
          data.forEach((categoryKey, shadesData) {
            final ck = categoryKey.toString();
            final categoryName =
                ck.isNotEmpty ? ck[0].toUpperCase() + ck.substring(1) : ck;
            categoriesSet.add(categoryName);
            if (shadesData is Map) {
              final familyShadesMap = Map<String, dynamic>.from(shadesData);
              familyShadesMap.forEach((shadeCode, shadeDetails) {
                if (shadeDetails is Map) {
                  final shade = Map<String, dynamic>.from(shadeDetails);
                  allShades.add({
                    'category': categoryName,
                    'code': shadeCode.toString(),
                    'name': shade['name']?.toString() ?? 'Unnamed',
                    'hex': shade['hex']?.toString() ?? '#FFFFFF',
                  });
                }
              });
            }
          });

          _categories = categoriesSet.toList()
            ..sort((a, b) {
              if (a == 'All') return -1;
              if (b == 'All') return 1;
              return a.compareTo(b);
            });
          _allShades = allShades;

          final filtered = _selectedCategory == 'All'
              ? _allShades
              : _allShades
                  .where((shade) => shade['category'] == _selectedCategory)
                  .toList();

          return Column(
            children: [
              _buildFilterBar(),
              Expanded(child: _buildShadesGrid(filtered)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    if (_categories.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final bool isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                }
              },
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.deepOrange,
              ),
              selectedColor: Colors.deepOrange,
              backgroundColor: Colors.deepOrange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.deepOrange.shade100),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildShadesGrid(List<Map<String, String>> shades) {
    if (shades.isEmpty && _selectedCategory != 'All') {
      return const Center(child: Text("No shades found in this category."));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: shades.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final shade = shades[index];
        return _buildColorSwatch(context, shade);
      },
    ).animate().fade(duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildColorSwatch(BuildContext context, Map<String, String> shade) {
    final hexCode = shade['hex'] ?? '#FFFFFF';
    final color = hexToColor(hexCode);
    final shadeName = shade['name'] ?? 'Unnamed';
    final shadeCode = shade['code'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShadeDetailPage(shade: shade)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            shadeName,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            shadeCode,
            style:
                GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

//==============================================================================
// Shade Detail Page (Unchanged)
//==============================================================================
class ShadeDetailPage extends StatelessWidget {
  final Map<String, String> shade;
  const ShadeDetailPage({super.key, required this.shade});

  @override
  Widget build(BuildContext context) {
    final String shadeName = shade['name'] ?? 'Unnamed';
    final String shadeCode = shade['code'] ?? 'N/A';
    final Color color = hexToColor(shade['hex'] ?? '#FFFFFF');

    return Scaffold(
      appBar: AppBar(
        title: Text(shadeName,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(color: color),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDetailRow('Shade Name', shadeName),
                const SizedBox(height: 16),
                _buildDetailRow('Shade Code', shadeCode),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    // If a manager has linked this shade to a specific product, go directly there.
                    try {
                      final code = shade['code']?.toString() ?? '';
                      if (code.isNotEmpty) {
                        final linkSnap = await FirebaseDatabase.instance
                            .ref('shadeLinks/$code')
                            .get();
                        if (linkSnap.exists && linkSnap.value is Map) {
                          final link =
                              Map<String, dynamic>.from(linkSnap.value as Map);
                          final String? productId =
                              link['productId']?.toString();
                          if (productId != null && productId.isNotEmpty) {
                            final prodSnap = await FirebaseDatabase.instance
                                .ref('products/$productId')
                                .get();
                            if (prodSnap.exists && prodSnap.value is Map) {
                              final product = Product.fromMap(
                                  productId,
                                  Map<String, dynamic>.from(
                                      prodSnap.value as Map));
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailPage(product: product)),
                              );
                              return;
                            }
                          }
                        }
                      }
                    } catch (e) {
                      // Ignore and fallback
                    }
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProductListForShadePage(shadeName: shadeName)),
                    );
                  },
                  child: Text('Find Products in this Shade',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800)),
      ],
    );
  }
}

//==============================================================================
// Product List for Shade Page (THIS IS WHERE THE FIXES ARE)
//==============================================================================
class ProductListForShadePage extends StatefulWidget {
  final String shadeName;
  const ProductListForShadePage({super.key, required this.shadeName});

  @override
  State<ProductListForShadePage> createState() =>
      _ProductListForShadePageState();
}

class _ProductListForShadePageState extends State<ProductListForShadePage> {
  final DatabaseReference _productsRef =
      FirebaseDatabase.instance.ref('products');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Products in ${widget.shadeName}",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: FutureBuilder<DataSnapshot>(
        future: _productsRef
            .orderByChild('shadeName')
            .equalTo(widget.shadeName)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange));
          }
          if (!snapshot.hasData || snapshot.data!.value == null) {
            return _buildEmptyState();
          }

          final productsMap =
              Map<String, dynamic>.from(snapshot.data!.value as Map);
          final List<Product> products = [];
          productsMap.forEach((key, value) {
            try {
              products
                  .add(Product.fromMap(key, Map<String, dynamic>.from(value)));
            } catch (e) {
              debugPrint(
                  "Error parsing product for shade list: $e. This might be an old data format.");
            }
          });

          if (products.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductListItem(context, products[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.box_search, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No products found for this shade.',
            style:
                GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  // ⭐ THIS WIDGET HAS BEEN FIXED
  Widget _buildProductListItem(BuildContext context, Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProductDetailPage(product: product)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  // ⭐ FIX: Use mainImageUrl from the new Product model
                  imageUrl: product.mainImageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: (c, e, s) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Iconsax.gallery_slash)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: GoogleFonts.poppins(
                          color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // ⭐ FIX: Price has been removed as per your request to simplify the UI
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
}
