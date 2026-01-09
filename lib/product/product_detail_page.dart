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
  bool _precached = false;
  PackSize? _selectedPack;

  Future<List<Product>> _loadSimilarProducts() async {
    return RecommendationService.fetchSimilarProducts(widget.product,
        limit: 10);
  }

  @override
  void initState() {
    super.initState();
    if (widget.product.packSizes.isNotEmpty) {
      try {
        _selectedPack = widget.product.packSizes.firstWhere(
          (p) => p.size.trim().startsWith('1 '),
          orElse: () => widget.product.packSizes.first,
        );
      } catch (_) {
        _selectedPack = widget.product.packSizes.first;
      }
    }
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

  // Function to add the selected size product to the user's cart via ViewModel
  Future<void> _addToCart() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to add items.")),
      );
      return;
    }
    final selected = _selectedPack;
    if (selected == null ||
        selected.price.isEmpty ||
        selected.price == '0' ||
        selected.price == 'N/A') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please select a valid pack size."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      await ref.read(cartVMProvider.notifier).addOrUpdateItem(
            productKey: widget.product.key,
            name: widget.product.name,
            mainImageUrl: widget.product.mainImageUrl,
            size: selected.size,
            price: selected.price,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text("${widget.product.name} (${selected.size}) added to cart!"),
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

                // Benefits section (banner image + bullet list)
                const Divider(height: 1, thickness: 0.5),
                _buildSectionTitle('Benefits'),
                if (widget.product.benefits.isNotEmpty &&
                    widget.product.benefits.first.image.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 160,
                      color: Colors.white,
                      child: CachedNetworkImage(
                        imageUrl: widget.product.benefits.first.image,
                        fit: BoxFit.cover,
                        placeholder: (c, u) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (c, e, s) => Container(
                          color: Colors.grey.shade200,
                          child:
                              const Center(child: Icon(Iconsax.gallery_slash)),
                        ),
                      ),
                    ),
                  ),
                if (widget.product.benefits.isNotEmpty)
                  const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: widget.product.benefits.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'No benefits listed',
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade600),
                          ),
                        )
                      : Column(
                          children: [
                            ...widget.product.benefits
                                .asMap()
                                .entries
                                .map((entry) {
                              final i = entry.key;
                              final b = entry.value;
                              return Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.green, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          b.text,
                                          style: GoogleFonts.poppins(
                                              color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (i < widget.product.benefits.length - 1)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10.0),
                                      child: Divider(
                                          height: 1,
                                          color: Colors.grey.shade200),
                                    ),
                                ],
                              );
                            })
                          ],
                        ),
                ),
                const SizedBox(height: 20),

                // Pack Sizes Section
                if (packSizesToDisplay.isNotEmpty) ...[
                  const Divider(height: 1, thickness: 0.5),
                  _buildSectionTitle('Pack Sizes Available'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: packSizesToDisplay.map((ps) {
                        final selected = _selectedPack?.size == ps.size;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _selectedPack = ps),
                            child:
                                _buildPackSizeCard(ps.size, ps.price, selected),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedPack != null && _selectedPack!.price.isNotEmpty)
                    Row(
                      children: [
                        Text('MRP  ',
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade700)),
                        Text('₹${_selectedPack!.price}',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Colors.deepOrange.shade700)),
                      ],
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
          onPressed: _addToCart,
          icon: const Icon(Iconsax.shopping_bag),
          label: Text(_selectedPack == null
              ? 'Add to Cart'
              : 'Add to Cart (${_selectedPack!.size})'),
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

  // Card-style pack size widget used in horizontal selector
  Widget _buildPackSizeCard(String size, String price, bool selected) {
    final showPrice = price.isNotEmpty && price != '0' && price != 'N/A';
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? Colors.deepOrange : Colors.grey.shade200,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: selected
                  ? Colors.deepOrange.withValues(alpha: 0.1)
                  : const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Iconsax.cup,
              size: 22,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            size,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            showPrice ? 'MRP ₹$price' : 'MRP —',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: selected ? Colors.deepOrange : Colors.grey.shade600,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
