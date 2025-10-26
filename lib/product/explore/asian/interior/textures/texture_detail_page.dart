import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
// Import ProductDetailPage to navigate to product details
import '/../product/product_detail_page.dart'; // Adjust path if needed
// Import Product model for type casting when navigating
import '/../model/product_model.dart'; // Adjust path if needed

// --- Color Helper ---
// Converts hex color strings (#RRGGBB or #AARRGGBB) to Flutter Color.
Color hexToColor(String code) {
  try {
    final hex = code.replaceAll('#', '');
    if (hex.length == 6) { // RGB
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) { // ARGB
      return Color(int.parse(hex, radix: 16));
    }
    return Colors.grey.shade300; // Fallback
  } catch (e) {
    debugPrint("Error converting hex '$code': $e");
    return Colors.grey.shade300; // Fallback on error
  }
}

class TextureDetailPage extends StatefulWidget {
  final Map<String, dynamic> textureData; // Data passed from the list page
  final String textureKey; // Firebase key for this texture

  const TextureDetailPage({
    super.key,
    required this.textureKey, // Key is useful if needed later
    required this.textureData,
  });

  @override
  State<TextureDetailPage> createState() => _TextureDetailPageState();
}

class _TextureDetailPageState extends State<TextureDetailPage> {
  // State for fetched combination details (name, hex) corresponding to codes
  List<Map<String, dynamic>> _combinationColorDetails = []; // Stores {code, name, hex}

  // State for fetched product details (name, image, key) for "Products Used"
  List<Map<String, dynamic>> _productsUsedDetails = [];
  bool _isLoadingProductsUsed = true;

  // State for currently displayed image, name, and color list
  late String _currentDisplayImageUrl;
  late List<Map<String, dynamic>> _currentDisplayColors; // List of {"role": "...", "code": "..."}
  late String _currentDisplayName;

  @override
  void initState() {
    super.initState();
    // Initialize display with the main texture data from widget
    _currentDisplayImageUrl = widget.textureData['imageUrl'] ?? '';
    _currentDisplayName = widget.textureData['name'] ?? 'Texture';
    _currentDisplayColors = []; // Main texture view doesn't show specific colors here

    // Start fetching details for combinations and products used
    _fetchCombinationColorDetails();
    _fetchProductsUsedDetails();
  }

  // Fetches details (name, hex) for each color code listed in ALL combinations
  // Stores result in _combinationColorDetails for quick lookup when displaying
  Future<void> _fetchCombinationColorDetails() async {
    if (!mounted) return;
    setState(() {});

    // Get all unique color codes from all combinations
    final Set<String> allColorCodes = {};
    if (widget.textureData['combinations'] is List) {
      final combinationsList = (widget.textureData['combinations'] as List).whereType<Map>();
      for (var combo in combinationsList) {
        if (combo['colors'] is List) {
          final colorsList = (combo['colors'] as List).whereType<Map>();
          for (var colorMap in colorsList) {
            if (colorMap['code'] is String && (colorMap['code'] as String).isNotEmpty) {
              allColorCodes.add(colorMap['code']);
            }
          }
        }
      }
    }

    if (allColorCodes.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    List<Map<String, dynamic>> details = [];
    try {
      final colorRef = FirebaseDatabase.instance.ref('colorCategories');
      final categoriesSnapshot = await colorRef.get(); // Get all color categories once

      if (!mounted) return; // Check after await

      if (categoriesSnapshot.exists && categoriesSnapshot.value is Map) {
        final categoriesMap = Map<String, dynamic>.from(categoriesSnapshot.value as Map);

        for (String code in allColorCodes) {
          bool found = false;
          // Search for the code within the fetched categories data
          categoriesMap.forEach((catKey, shadesMap) {
            if (!found && shadesMap is Map && shadesMap.containsKey(code)) {
              final colorData = shadesMap[code];
              if (colorData is Map) {
                details.add({
                  'code': code,
                  'name': colorData['name'] ?? 'Unknown',
                  'hex': colorData['hex'] ?? '#FFFFFF',
                });
                found = true; // Stop searching categories for this code
              }
            }
          });
          if (!found) {
            details.add({'code': code, 'name': 'Not Found', 'hex': '#CCCCCC'});
          }
        }
      } else {
        // Handle case where colorCategories node is empty or not found
        for (var code in allColorCodes) {
          details.add({'code': code, 'name': 'Error Loading', 'hex': '#FF0000'});
        }
      }

      setState(() { _combinationColorDetails = details; });

    } catch (e) {
      debugPrint("Error fetching combination color details: $e");
      if (mounted) setState(() {});
    }
  }


  // Fetches details for the products listed in 'productsUsed'
  Future<void> _fetchProductsUsedDetails() async {
    final List<String> productKeys = widget.textureData['productsUsed'] is List
        ? List<String>.from((widget.textureData['productsUsed'] as List).whereType<String>()) // Ensure strings
        : [];

    if (productKeys.isEmpty) {
      if (mounted) setState(() => _isLoadingProductsUsed = false);
      return;
    }
    if (!mounted) return;
    setState(() => _isLoadingProductsUsed = true);

    List<Map<String, dynamic>> details = [];
    try {
      final productRef = FirebaseDatabase.instance.ref('products');
      for (String key in productKeys) {
        final snapshot = await productRef.child(key).get();
        if (!mounted) return; // Check mount status after await
        if (snapshot.exists && snapshot.value is Map) {
          final productData = Map<String, dynamic>.from(snapshot.value as Map);
          // Store key along with data for navigation and display
          details.add({'key': key, ...productData});
        } else {
          details.add({'key': key, 'name': 'Product Not Found'}); // Placeholder if product was deleted
        }
      }
      // Sort products used alphabetically by name
      details.sort((a,b) => (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase()));
      setState(() { _productsUsedDetails = details; _isLoadingProductsUsed = false; });
    } catch (e) {
      debugPrint("Error fetching products used details: $e");
      if (mounted) setState(() => _isLoadingProductsUsed = false);
    }
  }

  // Updates the main display area when a combination thumbnail is tapped
  void _selectCombination(Map<String, dynamic> combination) {
    setState(() {
      _currentDisplayImageUrl = combination['imageUrl'] ?? widget.textureData['imageUrl'] ?? ''; // Fallback
      // Ensure 'colors' is treated as List<Map<String, dynamic>>
      _currentDisplayColors = (combination['colors'] as List<dynamic>?)
          ?.whereType<Map>()
          .map((c) => Map<String, dynamic>.from(c.cast<String, dynamic>())) // Cast inner map
          .toList() ??
          [];
      _currentDisplayName = combination['name'] ?? widget.textureData['name'] ?? 'Texture';
    });
  }

  // Resets the main display area to show the original texture
  void _selectMainTexture() {
    setState(() {
      _currentDisplayImageUrl = widget.textureData['imageUrl'] ?? '';
      _currentDisplayColors = []; // Main view doesn't list specific colors this way
      _currentDisplayName = widget.textureData['name'] ?? 'Texture';
    });
  }

  // Helper to get color details (name, hex) from the pre-fetched list
  Map<String, dynamic> _getColorDetailsFromCache(String code) {
    try {
      return _combinationColorDetails.firstWhere((cd) => cd['code'] == code);
    } catch (e) {
      // Return a default if code not found in cache (shouldn't happen often)
      return {'code': code, 'name': 'Unknown', 'hex': '#CCCCCC'};
    }
  }


  @override
  Widget build(BuildContext context) {
    // Basic details from the passed data
    final name = widget.textureData['name'] ?? 'Texture';
    final description = widget.textureData['description'] ?? '';
    final category = widget.textureData['category'] ?? '';

    // Get combinations list safely for thumbnails
    final List<Map<String, dynamic>> combinations = widget.textureData['combinations'] is List
        ? (widget.textureData['combinations'] as List).map((c) {
      // Ensure inner map is correctly typed
      return c is Map ? Map<String, dynamic>.from(c.cast<String, dynamic>()) : <String, dynamic>{};
    }).toList()
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentDisplayName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)), // Show current view's name
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: SingleChildScrollView( // Changed to SingleChildScrollView for simpler layout
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Main Image Area ---
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: CachedNetworkImage(
                key: ValueKey(_currentDisplayImageUrl), // Key ensures animation runs on change
                imageUrl: _currentDisplayImageUrl,
                height: 350,
                width: double.infinity, // Ensure it takes full width
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(height: 350, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                errorWidget: (c, u, e) => Container(height: 350, color: Colors.grey.shade100, child: const Center(child: Icon(Iconsax.gallery_slash))),
              ),
            ),

            // --- Content Padding ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Display Colors for Current View ---
                  if (_currentDisplayColors.isNotEmpty) ...[
                    Text("Colors in this combination:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey.shade700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: _currentDisplayColors.map((colorMap) {
                        final colorDetails = _getColorDetailsFromCache(colorMap['code'] ?? '');
                        return Chip(
                          avatar: CircleAvatar(backgroundColor: hexToColor(colorDetails['hex'] ?? '#ccc'), radius: 10),
                          label: Text("${colorMap['role']}: ${colorDetails['name'] ?? colorMap['code']}", style: const TextStyle(fontSize: 12)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Divider(thickness: 0.5),
                    const SizedBox(height: 16),
                  ],

                  // --- Basic Texture Details ---
                  Text(name, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)), // Original texture name
                  const SizedBox(height: 4),
                  Text("Category: $category", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14)),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text("Description", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(description, style: GoogleFonts.poppins(height: 1.5, fontSize: 14)),
                  ],

                  // --- Try Other Combinations Section ---
                  if (combinations.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(thickness: 0.5),
                    const SizedBox(height: 16),
                    Text("Try Other Combinations", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 95, // Increased height slightly for better text fit
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Thumbnail for the Main/Original Texture
                          _buildCombinationThumbnail(
                            imageUrl: widget.textureData['imageUrl'] ?? '',
                            name: 'Original',
                            isSelected: _currentDisplayImageUrl == (widget.textureData['imageUrl'] ?? ''), // Check against main URL
                            onTap: _selectMainTexture, // Action to reset view
                          ),
                          const SizedBox(width: 10),
                          // Thumbnails for each Combination
                          ...combinations.map((combo) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: _buildCombinationThumbnail(
                                imageUrl: combo['imageUrl'] ?? '',
                                name: combo['name'] ?? '',
                                isSelected: _currentDisplayImageUrl == combo['imageUrl'], // Check against combo URL
                                onTap: () => _selectCombination(combo), // Action to select combo
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  // --- Product Used Section ---
                  const SizedBox(height: 24),
                  const Divider(thickness: 0.5),
                  const SizedBox(height: 16),
                  Text("Products Used", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  _isLoadingProductsUsed
                      ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
                      : (_productsUsedDetails.isEmpty
                      ? Text("No specific product information available.", style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic))
                      : Column( // Display products used in a vertical list
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Make cards take full width
                    children: _productsUsedDetails.map((productInfo) {
                      // Attempt to create a Product object for navigation
                      Product? productForNav;
                      try {
                        productForNav = Product.fromMap(productInfo['key'], productInfo);
                      } catch (e) {
                        debugPrint("Could not parse product for nav: ${productInfo['name']} - $e");
                      }

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          dense: true,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: productInfo['mainImageUrl'] ?? productInfo['imageUrl'] ?? '', // Use mainImageUrl
                              width: 40, height: 40, fit: BoxFit.cover,
                              errorWidget: (c, u, e) => Container(width: 40, height: 40, color: Colors.grey.shade100, child: Icon(Iconsax.box_1, size: 20, color: Colors.grey)),
                              placeholder: (c,u) => Container(width: 40, height: 40, color: Colors.grey.shade200),
                            ),
                          ),
                          title: Text(productInfo['name'] ?? 'Unknown Product', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                          trailing: productForNav != null ? Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey) : null, // Show arrow only if navigable
                          onTap: productForNav == null
                              ? null // Disable tap if parsing failed
                              : () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: productForNav!)));
                          },
                        ),
                      );
                    }).toList(),
                  )),
                  const SizedBox(height: 20), // Bottom padding
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper widget for building combination thumbnails
  Widget _buildCombinationThumbnail({
    required String imageUrl,
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take minimum vertical space
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                width: isSelected ? 2.5 : 1, // Make selection more prominent
              ),
              // Add inner shadow or subtle background change for selection
              color: isSelected ? Colors.deepOrange.shade50 : Colors.white,
              boxShadow: isSelected ? [BoxShadow(color: Colors.deepOrange.withValues(alpha: 0.2), blurRadius: 4, spreadRadius: 1)] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10), // Inner radius slightly smaller
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(color: Colors.grey.shade200),
                errorWidget: (c, u, e) => Center(child: Icon(Iconsax.gallery_slash, size: 20, color: Colors.grey)),
              ),
            ),
          ),
          const SizedBox(height: 5), // Adjust spacing
          SizedBox(
            width: 70, // Slightly wider width for text
            child: Text(
              name.isEmpty ? '(Default)' : name, // Handle empty name
              style: GoogleFonts.poppins(
                  fontSize: 11, // Slightly larger font
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.deepOrange : Colors.black87 // More contrast for unselected
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }

} // End of _TextureDetailPageState class