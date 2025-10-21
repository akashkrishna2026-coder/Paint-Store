import 'package:cached_network_image/cached_network_image.dart';
import 'package:c_h_p/model/product_model.dart'; // Ensure correct import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedBenefitIndex = 0;

  // Function to add the default (1L) size product to the user's cart
  Future<void> _addToCart(Product product) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to add items.")),
      );
      return;
    }

    // --- Find the 1L pack size data ---
    PackSize? defaultPackSize;

    // Handle empty list case explicitly before using firstWhere
    if (product.packSizes.isNotEmpty) {
      try {
        // Find the pack size where the size string starts with "1 "
        defaultPackSize = product.packSizes.firstWhere(
                (pack) => pack.size.trim().startsWith('1 '),
            // Now, orElse only runs if '1 L' isn't found, but the list is NOT empty.
            // So, we can safely return the first element (smallest size).
            orElse: () => product.packSizes.first
        );
      } catch (e) {
        // This catch block might not be strictly necessary anymore
        // but is kept for safety if firstWhere throws unexpected errors.
        debugPrint("Error finding default 1L pack size (should not happen often): $e");
        defaultPackSize = product.packSizes.first; // Fallback just in case
      }
    }
    // --- End finding 1L pack size ---


    // Check if a valid default size was found (handles empty packSizes list case)
    if (defaultPackSize == null || defaultPackSize.price.isEmpty || defaultPackSize.price == '0' || defaultPackSize.price == 'N/A') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot add product: Default size/price unavailable."), backgroundColor: Colors.red),
      );
      return;
    }

    final cartRef = FirebaseDatabase.instance.ref('users/${user.uid}/cart/${product.key}');
    try {
      final snapshot = await cartRef.get();

      // --- Logic for adding/updating ---
      if (snapshot.exists && snapshot.value is Map) {
        final cartItemData = Map<String, dynamic>.from(snapshot.value as Map);
        if (cartItemData['selectedSize'] == defaultPackSize.size) {
          int currentQuantity = cartItemData['quantity'] ?? 0;
          await cartRef.update({'quantity': currentQuantity + 1});
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${product.name} (${defaultPackSize.size}) quantity updated!"), backgroundColor: Colors.orange.shade700));
        } else {
          await cartRef.set({
            'name': product.name,
            'mainImageUrl': product.mainImageUrl,
            'selectedSize': defaultPackSize.size,
            'selectedPrice': defaultPackSize.price,
            'quantity': 1,
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${product.name} (${defaultPackSize.size}) added to cart (replaced other size)."), backgroundColor: Colors.green.shade600));
        }

      } else {
        await cartRef.set({
          'name': product.name,
          'mainImageUrl': product.mainImageUrl,
          'selectedSize': defaultPackSize.size,
          'selectedPrice': defaultPackSize.price,
          'quantity': 1,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${product.name} (${defaultPackSize.size}) added to cart!"), backgroundColor: Colors.green.shade600));
      }
      // --- End logic ---

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add to cart: $e")));
    }
  }


  // Function to launch a URL (for the brochure)
  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the brochure.')));
      }
    }
  }

  // Sorting is handled in product_model.dart

  @override
  Widget build(BuildContext context) {
    // packSizes list is already sorted by the Product.fromMap constructor
    final packSizesToDisplay = widget.product.packSizes;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // --- Parallax Header ---
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  CachedNetworkImage(
                    imageUrl: widget.product.backgroundImageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (c,u,e) => Container(color: Colors.grey.shade200), // Placeholder on error
                  ),
                  // Dark overlay for contrast
                  Container(color: Colors.black.withOpacity(0.2)),
                  // Main Product Image with Hero Transition
                  Positioned(
                    bottom: -1, // Slight overlap
                    left: 0, right: 0,
                    child: Center(
                      child: Hero(
                        tag: 'product_image_${widget.product.key}', // Must match the tag from the list page
                        child: CachedNetworkImage(
                          imageUrl: widget.product.mainImageUrl,
                          height: 200,
                          errorWidget: (c,u,e) => const SizedBox(height: 200, child: Icon(Iconsax.gallery_slash, color: Colors.white70)), // Placeholder on error
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Main Content Area ---
          SliverPadding( // Added padding around the main content
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Product Name and Description
                Text(widget.product.name, style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(widget.product.description, style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54, height: 1.6)),
                const SizedBox(height: 24), // Increased spacing

                // Interactive Benefits Section
                if (widget.product.benefits.isNotEmpty && widget.product.benefits.length == 3) ...[
                  const Divider(height: 1, thickness: 0.5), // Subtle separator
                  _buildSectionTitle('Benefits'),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    child: ClipRRect(
                      key: ValueKey<int>(_selectedBenefitIndex),
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: widget.product.benefits[_selectedBenefitIndex].image,
                        height: 250,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(height: 250, color: Colors.grey.shade200),
                        errorWidget: (c, u, e) => Container(height: 250, color: Colors.grey.shade200, child: const Icon(Iconsax.gallery_slash)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(3, (index) {
                      return _buildBenefitSelector(
                        text: widget.product.benefits[index].text,
                        isSelected: _selectedBenefitIndex == index,
                        onTap: () => setState(() => _selectedBenefitIndex = index),
                      );
                    }),
                  ),
                  const SizedBox(height: 24), // Spacing after benefits
                ],

                // Pack Sizes Section
                if (packSizesToDisplay.isNotEmpty) ...[
                  const Divider(height: 1, thickness: 0.5),
                  _buildSectionTitle('Pack Sizes Available'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: packSizesToDisplay.map((pack) => _buildPackSizeItem(pack.size, pack.price)).toList(),
                  ),
                  Padding( // Disclaimer text
                    padding: const EdgeInsets.only(top: 12.0), // Added padding above disclaimer
                    child: Text(
                      '*Please note that the final cost may vary depending on the chosen shade and finish.',
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 30), // Spacing after pack sizes
                ],


                // Brochure Download Button
                if (widget.product.brochureUrl.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _launchURL(widget.product.brochureUrl),
                    icon: const Icon(Iconsax.document_download),
                    label: Text('Download Brochure', style: GoogleFonts.poppins()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      side: BorderSide(color: Colors.deepOrange.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),


                const SizedBox(height: 40), // Adjusted bottom padding before button
              ]),
            ),
          ),
        ],
      ),
      // --- Floating Add to Cart Button ---
      bottomNavigationBar: Container( // Wrap button for padding and potential background/shadow
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
            color: Colors.white, // Ensure button background contrasts if needed
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,-5))
            ]
        ),
        child: ElevatedButton.icon(
          onPressed: () => _addToCart(widget.product),
          icon: const Icon(Iconsax.shopping_bag),
          label: const Text('Add to Cart (1L)'), // Indicate default size
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  // Builds a styled section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0), // Consistent padding
      child: Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
    );
  }

  // Builds one of the clickable benefit selectors
  Widget _buildBenefitSelector({required String text, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer( // Animates the underline
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // Adjusted padding
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? Colors.deepOrange : Colors.transparent, width: 3)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.deepOrange : Colors.grey.shade600,
            ),
            maxLines: 3, // Allow text to wrap if long
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // Builds the display for a single pack size with correct image fitting
  Widget _buildPackSizeItem(String size, String price) {
    // Don't display if price is missing or zero
    if (price.isEmpty || price == '0') return const Expanded(child: SizedBox());

    // Construct the image path dynamically based on size
    String imageFileName = size.toLowerCase().replaceAll(' ', '') + '.jpeg';
    String imagePath = 'assets/pack_sizes/$imageFileName';

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Container to constrain the image size and center it
          Container(
            height: 80, // Set height for the image area
            width: 70, // Set width for the image area
            alignment: Alignment.center,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain, // Ensures the whole image fits
              errorBuilder: (context, error, stackTrace) {
                // Consistent fallback placeholder
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Iconsax.box_1, color: Colors.grey.shade400, size: 30)),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(size, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('MRP ₹$price', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            '(Inclusive of all taxes)',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}