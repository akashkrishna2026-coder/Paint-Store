import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For animations
import 'package:shimmer/shimmer.dart'; // For loading shimmer
import 'package:c_h_p/pages/core/cart_page.dart';

// Import the Texture Detail Page
import 'texture_detail_page.dart'; // Ensure this path is correct

class TexturesPage extends StatefulWidget {
  final String category; // e.g., 'Interior' or 'Exterior'

  const TexturesPage({super.key, required this.category});

  @override
  State<TexturesPage> createState() => _TexturesPageState();
}

class _TexturesPageState extends State<TexturesPage> {
  final DatabaseReference _texturesRef =
      FirebaseDatabase.instance.ref('textures');

  // Use FutureBuilder for efficient data fetching
  late final Future<List<Map<String, dynamic>>> _fetchTexturesFuture;

  @override
  void initState() {
    super.initState();
    _fetchTexturesFuture = _fetchTextures();
  }

  // Fetch textures for the specified category
  Future<List<Map<String, dynamic>>> _fetchTextures() async {
    // Query Firebase for textures matching the widget's category
    final snapshot = await _texturesRef
        .orderByChild('category')
        .equalTo(widget.category)
        .get();
    List<Map<String, dynamic>> textures = [];

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        if (value is Map) {
          // Check if value is a map before casting
          final textureData = Map<String, dynamic>.from(value);
          textures.add({'key': key, ...textureData}); // Add key along with data
        }
      });
    }

    // Sort textures alphabetically by name after fetching
    textures.sort((a, b) => (a['name'] ?? '')
        .toLowerCase()
        .compareTo((b['name'] ?? '').toLowerCase()));
    return textures;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Lighter background
      appBar: _buildAppBar(), // Use a standard AppBar
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchTexturesFuture,
        builder: (context, snapshot) {
          // Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmerGrid(); // Shimmer grid for body
          }
          // Error State
          if (snapshot.hasError) {
            return Center(
                child: Text("Error loading textures: ${snapshot.error}",
                    style: TextStyle(color: Colors.red)));
          }
          // No Data State
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(
                    "No ${widget.category.toLowerCase()} textures found.",
                    style: TextStyle(color: Colors.grey.shade600)));
          }

          // Data Available: Display Grid
          final allTextures = snapshot.data!;

          // No filtering needed anymore, directly build the grid
          return _buildTexturesGrid(allTextures);
        },
      ),
    );
  }

  // Build AppBar (kept simple as it's not part of CustomScrollView anymore)
  AppBar _buildAppBar() {
    return AppBar(
      title: Text("${widget.category} Wall Textures",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
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
    );
  }

  // Grid for displaying textures (Now a regular Widget, not Sliver)
  Widget _buildTexturesGrid(List<Map<String, dynamic>> textures) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8, // Adjust ratio as needed
      ),
      itemCount: textures.length,
      itemBuilder: (context, index) {
        final texture = textures[index];
        // Animate each card
        return _buildTextureCard(texture)
            .animate()
            .fadeIn(delay: (index * 50).ms, duration: 300.ms);
      },
    );
  }

  // Build a single texture card (Navigates to Detail Page)
  Widget _buildTextureCard(Map<String, dynamic> texture) {
    return GestureDetector(
      // Make card tappable
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TextureDetailPage(
                  textureKey: texture['key'] ?? '', // Pass the key
                  textureData: texture // Pass the full data map
                  )),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Rounded corners
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand, // Make stack fill the container
            children: [
              // Background Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: texture['imageUrl'] ?? '', // Main image URL
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade200),
                  errorWidget: (context, url, error) => const Center(
                      child: Icon(Iconsax.gallery_slash, color: Colors.grey)),
                ),
              ),
              // Gradient Overlay and Name at the bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent
                        ], // Darker gradient
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [
                          0.0,
                          0.8
                        ] // Adjust stops for gradient spread
                        ),
                  ),
                  child: Text(
                    texture['name'] ?? 'Unnamed',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shimmer Loading Placeholder for the Grid
  Widget _buildLoadingShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8),
      itemCount: 6, // Show 6 shimmer items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
        );
      },
    );
  }
} // End _TexturesPageState

// **** REMOVED _FilterBarDelegate class ****
// The filter bar is no longer used as colorFamily was removed.
