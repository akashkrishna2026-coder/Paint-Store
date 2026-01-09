import 'package:cached_network_image/cached_network_image.dart';
import 'package:c_h_p/model/product_model.dart'; // Ensure correct import
import '../services/recommendation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:c_h_p/pages/core/cart_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/app/providers.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _selectedBenefitIndex = 0;
  bool _precached = false;

  Future<List<Product>> _loadSimilarProducts() async {
    return RecommendationService.fetchSimilarProducts(widget.product,
        limit: 10);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    final mainUrl = widget.product.mainImageUrl;
    final bgUrl = widget.product.backgroundImageUrl;
    if (mainUrl.isNotEmpty) {
      precacheImage(CachedNetworkImageProvider(mainUrl), context);
    }
    if (bgUrl.isNotEmpty) {
      precacheImage(CachedNetworkImageProvider(bgUrl), context);
    }
    _precached = true;
  }

  // Function to add the default (1L) size product to the user's cart via ViewModel
  Future<void> _addToCart(Product product) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to add items.")),
      );
      return;
    }

    // Find default size: prefer starting with "1 ", else first valid priced size
    PackSize? defaultPackSize;
    if (product.packSizes.isNotEmpty) {
      try {
        defaultPackSize = product.packSizes.firstWhere(
          (pack) => pack.size.trim().startsWith('1 '),
          orElse: () => product.packSizes.first,
        );
      } catch (_) {
        defaultPackSize = product.packSizes.first;
      }
    }
    if (defaultPackSize == null ||
        defaultPackSize.price.isEmpty ||
        defaultPackSize.price == '0' ||
        defaultPackSize.price == 'N/A') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Cannot add product: Default size/price unavailable."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      await ref.read(cartVMProvider.notifier).addOrUpdateItem(
            productKey: product.key,
            name: product.name,
            mainImageUrl: product.mainImageUrl,
            size: defaultPackSize.size,
            price: defaultPackSize.price,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text("${product.name} (${defaultPackSize.size}) added to cart!"),
        backgroundColor: Colors.green.shade600,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to add to cart: $e")));
    }
  }

  // Function to launch a URL (for the brochure)
  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the brochure.')));
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
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  CachedNetworkImage(
                    imageUrl: widget.product.backgroundImageUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 160),
                    memCacheWidth: 1200,
                    placeholder: (c, u) =>
                        Container(color: Colors.grey.shade200),
                    errorWidget: (c, u, e) =>
                        Container(color: Colors.grey.shade200),
                  ),
                  // Vignette overlay for contrast and readability
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66000000), // top vignette
                          Color(0x00000000), // transparent center
                          Color(0x22000000), // subtle bottom vignette
                        ],
                      ),
                    ),
                  ),
                  // Bottom fade into page background
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.white, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Main Product Image with Hero Transition
                  Positioned(
                    bottom: -1, // Slight overlap
                    left: 0, right: 0,
                    child: Center(
                      child: Hero(
                        tag:
                            'product_image_${widget.product.key}', // Must match the tag from the list page
                        child: CachedNetworkImage(
                          imageUrl: widget.product.mainImageUrl,
                          height: 200,
                          fit: BoxFit.contain,
                          fadeInDuration: const Duration(milliseconds: 160),
                          memCacheWidth: 600,
                          placeholder: (c, u) => SizedBox(
                              height: 200,
                              child: Container(color: Colors.black12)),
                          errorWidget: (c, u, e) => const SizedBox(
                              height: 200,
                              child: Icon(Iconsax.gallery_slash,
                                  color: Colors.white70)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Main Content Area ---
          SliverPadding(
            // Added padding around the main content
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Product Name and Description
                Text(widget.product.name,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(widget.product.description,
                    style: GoogleFonts.poppins(
                        fontSize: 15, color: Colors.black54, height: 1.6)),
                const SizedBox(height: 20),

                // Interactive Benefits Section (any count, image/text fallback)
                if (widget.product.benefits.isNotEmpty) ...[
                  const Divider(height: 1, thickness: 0.5), // Subtle separator
                  _buildSectionTitle('Benefits'),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Builder(
                      key: ValueKey<int>(_selectedBenefitIndex),
                      builder: (context) {
                        final benefits = widget.product.benefits;
                        final count = benefits.length;
                        final selIdx = count == 0
                            ? 0
                            : (_selectedBenefitIndex.clamp(0, count - 1));
                        final imageUrl = benefits[selIdx].image;
                        final text = benefits[selIdx].text;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: Colors.white,
                            height: 250,
                            alignment: Alignment.center,
                            child: (imageUrl.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.contain,
                                    fadeInDuration:
                                        const Duration(milliseconds: 160),
                                    placeholder: (context, url) =>
                                        Container(color: Colors.grey.shade200),
                                    errorWidget: (c, u, e) => const Center(
                                        child: Icon(Iconsax.gallery_slash)),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      text,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                          fontSize: 14, color: Colors.black87),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children:
                        List.generate(widget.product.benefits.length, (index) {
                      return _buildBenefitSelector(
                        text: widget.product.benefits[index].text,
                        isSelected: _selectedBenefitIndex == index,
                        onTap: () =>
                            setState(() => _selectedBenefitIndex = index),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                ],

                // Pack Sizes Section
                if (packSizesToDisplay.isNotEmpty) ...[
                  const Divider(height: 1, thickness: 0.5),
                  _buildSectionTitle('Pack Sizes Available'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: packSizesToDisplay
                        .map(
                            (pack) => _buildPackSizeItem(pack.size, pack.price))
                        .toList(),
                  ),
                  Padding(
                    // Disclaimer text
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      '*Please note that the final cost may vary depending on the chosen shade and finish.',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Similar Products Section (KNN-based)
                const Divider(height: 1, thickness: 0.5),
                _buildSectionTitle('Similar products'),
                FutureBuilder<List<Product>>(
                  future: _loadSimilarProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final items = snapshot.data!;
                    return SizedBox(
                      height: 210,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final p = items[index];
                          return GestureDetector(
                            onTap: () {
                              final brand = (p.brand ?? '').toLowerCase();
                              if (brand.startsWith('indigo')) {
                                // Navigate to specialized Indigo detail if needed
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            ProductDetailPage(product: p)));
                              } else {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            ProductDetailPage(product: p)));
                              }
                            },
                            child: SizedBox(
                              width: 150,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: CachedNetworkImage(
                                        imageUrl: p.mainImageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (c, u) => Container(
                                            color: Colors.grey.shade200),
                                        errorWidget: (c, u, e) =>
                                            const Icon(Iconsax.gallery_slash),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                // Brochure Download Button
                if (widget.product.brochureUrl.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _launchURL(widget.product.brochureUrl),
                    icon: const Icon(Iconsax.document_download),
                    label:
                        Text('Download Brochure', style: GoogleFonts.poppins()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      side: BorderSide(color: Colors.deepOrange.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                const SizedBox(
                    height: 40), // Adjusted bottom padding before button
              ]),
            ),
          ),
        ],
      ),
      // --- Floating Add to Cart Button ---
      bottomNavigationBar: Container(
        // Wrap button for padding and potential background/shadow
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
            color: Colors.white, // Ensure button background contrasts if needed
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ]),
        child: ElevatedButton.icon(
          onPressed: () => _addToCart(widget.product),
          icon: const Icon(Iconsax.shopping_bag),
          label: const Text('Add to Cart (1L)'), // Indicate default size
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            textStyle:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  // Builds a styled section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 24.0, bottom: 16.0), // Consistent padding
      child: Text(title,
          style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800)),
    );
  }

  // Builds one of the clickable benefit selectors
  Widget _buildBenefitSelector(
      {required String text,
      required bool isSelected,
      required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          // Animates the underline
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 8), // Adjusted padding
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: isSelected ? Colors.deepOrange : Colors.transparent,
                    width: 3)),
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
    String imageFileName = '${size.toLowerCase().replaceAll(' ', '')}.jpeg';
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
                  child: Center(
                      child: Icon(Iconsax.box_1,
                          color: Colors.grey.shade400, size: 30)),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(size,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('MRP ₹$price',
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            '(Inclusive of all taxes)',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.poppins(fontSize: 9, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
