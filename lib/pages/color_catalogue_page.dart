// lib/pages/color_catalogue_page.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../model/product_model.dart';
import '../product/product_detail_page.dart';

// Helper to convert hex strings to Color objects (with error handling)
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
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('colorCatalogue');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Color Catalogue", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("Color catalogue is empty."));
          }

          if (snapshot.data!.snapshot.value is! Map) {
            return const Center(child: Text("Invalid data format from Firebase."));
          }

          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final familiesData = data['families'] is Map ? Map<String, dynamic>.from(data['families']) : <String, dynamic>{};
          final allShadesData = data['shades'] is Map ? Map<String, dynamic>.from(data['shades']) : <String, dynamic>{};

          final families = familiesData.entries.map((e) {
            final value = e.value is Map ? Map<String, dynamic>.from(e.value) : <String, dynamic>{};
            return {'key': e.key, ...value};
          }).toList();

          if (families.isEmpty) {
            return const Center(child: Text("No color families found."));
          }

          // ⭐ REMOVED the Column and Visualizer Banner. This ListView is now the main body.
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: families.length,
            itemBuilder: (context, index) {
              final family = families[index];
              final familyKey = family['key'] as String;
              final familyName = family['name'] as String? ?? 'Unnamed Family';

              final List<Map<String, String>> shades = [];
              if (allShadesData.containsKey(familyKey) && allShadesData[familyKey] is Map) {
                final familyShadesMap = Map<String, dynamic>.from(allShadesData[familyKey]);
                familyShadesMap.forEach((shadeKey, shadeValue) {
                  if (shadeValue is Map) {
                    shades.add(Map<String, String>.from(shadeValue.map((k, v) => MapEntry(k.toString(), v.toString()))));
                  }
                });
              }
              return _ColorFamilySection(
                familyName: familyName,
                shades: shades,
              );
            },
          );
        },
      ),
    );
  }
}

class _ColorFamilySection extends StatelessWidget {
  final String familyName;
  final List<Map<String, String>> shades;
  const _ColorFamilySection({required this.familyName, required this.shades});
  @override
  Widget build(BuildContext context) {
    if (shades.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(familyName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: shades.length,
              itemBuilder: (context, index) {
                final shade = shades[index];
                final shadeName = shade['name'] ?? 'Unnamed';
                final hexCode = shade['hexCode'] ?? '#FFFFFF';
                final color = hexToColor(hexCode);
                return GestureDetector(
                  onTap: () {
                    if (shade['name'] != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListForShadePage(shadeName: shadeName)));
                    }
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//==============================================================================
// ⭐ REMOVED: The entire ColorVisualizerPage class is gone.
//==============================================================================

//==============================================================================
// INTEGRATED: Product List for Shade Page
//==============================================================================

class ProductListForShadePage extends StatefulWidget {
  final String shadeName;
  const ProductListForShadePage({super.key, required this.shadeName});

  @override
  State<ProductListForShadePage> createState() => _ProductListForShadePageState();
}

class _ProductListForShadePageState extends State<ProductListForShadePage> {
  final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('products');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.shadeName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: FutureBuilder<DataSnapshot>(
        future: _productsRef.orderByChild('shadeName').equalTo(widget.shadeName).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          if (!snapshot.hasData || snapshot.data!.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.box_search, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No products found for this shade.',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
          }

          final productsMap = Map<String, dynamic>.from(snapshot.data!.value as Map);
          final List<Product> products = [];
          productsMap.forEach((key, value) {
            try {
              products.add(Product.fromMap(key, Map<String, dynamic>.from(value)));
            } catch(e) {
              print("Error parsing product for shade list: $e");
            }
          });

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.box_search, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No products found for this shade.',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
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
            MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Iconsax.gallery_slash)),
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
                    const SizedBox(height: 4),
                    Text(
                        '₹${product.price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)
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
}