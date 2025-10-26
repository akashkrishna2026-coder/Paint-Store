import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:c_h_p/model/product_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class IndigoProductDetailPage extends StatefulWidget {
  const IndigoProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  State<IndigoProductDetailPage> createState() => _IndigoProductDetailPageState();
}

class _IndigoProductDetailPageState extends State<IndigoProductDetailPage> {
  late PackSize? _selectedPack;

  @override
  void initState() {
    super.initState();
    // Default to 1 L if available, else first
    _selectedPack = null;
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

  Widget _buildLeftImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: widget.product.mainImageUrl,
            fit: BoxFit.contain,
            memCacheWidth: 1200,
            memCacheHeight: 1200,
            placeholder: (c, u) => Container(color: Colors.grey.shade200),
            errorWidget: (c, e, s) => const Center(child: Icon(Iconsax.gallery_slash)),
          ),
        ),
      ),
    );
  }

  Widget _buildRightDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22)),
        const SizedBox(height: 8),
        Text(widget.product.description, style: GoogleFonts.poppins(color: Colors.grey.shade700)),
        const SizedBox(height: 16),

        // Pack Sizes
        Text('Available Pack Sizes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.product.packSizes.map((ps) {
            final selected = _selectedPack?.size == ps.size;
            return ChoiceChip(
              label: Text(ps.size, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              selected: selected,
              onSelected: (_) => setState(() => _selectedPack = ps),
              selectedColor: Colors.deepOrange.shade50,
              shape: StadiumBorder(side: BorderSide(color: selected ? Colors.deepOrange : const Color(0xFFE0E0E0))),
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.poppins(color: selected ? Colors.deepOrange : Colors.black87),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        if (_selectedPack != null && _selectedPack!.price.isNotEmpty)
          Row(
            children: [
              Text('MRP  ', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
              Text('₹${_selectedPack!.price}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.deepOrange.shade700)),
            ],
          ),
        const SizedBox(height: 20),

        // Advantages
        Text('Advantages', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (widget.product.benefits.isEmpty)
          Text('No advantages listed', style: GoogleFonts.poppins(color: Colors.grey.shade600))
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.product.benefits
                .map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(b.text, style: GoogleFonts.poppins())),
                        ],
                      ),
                    ))
                .toList(),
          ),
        const SizedBox(height: 20),

        // Warranty
        if (widget.product.warrantyYears != null && widget.product.warrantyYears! > 0)
          Row(
            children: [
              const Icon(Iconsax.shield_tick, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Text('Warranty: ${widget.product.warrantyYears} years', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ],
          ),
        const SizedBox(height: 16),
        if (widget.product.brochureUrl.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => _launchURL(widget.product.brochureUrl),
            icon: const Icon(Iconsax.document_download),
            label: Text('Download Datasheet', style: GoogleFonts.poppins()),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepOrange,
              side: BorderSide(color: Colors.deepOrange.shade200),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }

  // Add selected size to cart
  Future<void> _addToCart() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to add items.')));
      return;
    }
    final pack = _selectedPack;
    if (pack == null || pack.price.isEmpty || pack.price == '0' || pack.price == 'N/A') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a valid pack size.')));
      return;
    }
    final cartRef = FirebaseDatabase.instance.ref('users/${user.uid}/cart/${widget.product.key}');
    try {
      final snapshot = await cartRef.get();
      if (snapshot.exists && snapshot.value is Map) {
        final cartItemData = Map<String, dynamic>.from(snapshot.value as Map);
        if (cartItemData['selectedSize'] == pack.size) {
          int currentQuantity = cartItemData['quantity'] ?? 0;
          await cartRef.update({'quantity': currentQuantity + 1, 'selectedPrice': pack.price});
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${widget.product.name} (${pack.size}) quantity updated!"), backgroundColor: Colors.orange.shade700));
        } else {
          await cartRef.set({
            'name': widget.product.name,
            'mainImageUrl': widget.product.mainImageUrl,
            'selectedSize': pack.size,
            'selectedPrice': pack.price,
            'quantity': 1,
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${widget.product.name} (${pack.size}) added to cart."), backgroundColor: Colors.green.shade600));
        }
      } else {
        await cartRef.set({
          'name': widget.product.name,
          'mainImageUrl': widget.product.mainImageUrl,
          'selectedSize': pack.size,
          'selectedPrice': pack.price,
          'quantity': 1,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${widget.product.name} (${pack.size}) added to cart!"), backgroundColor: Colors.green.shade600));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add to cart: $e')));
    }
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: ListView(
        children: [
          if ((widget.product.backgroundImageUrl).isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.product.backgroundImageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    placeholder: (c, u) => Container(color: Colors.grey.shade300),
                    errorWidget: (c, e, s) => Container(color: Colors.grey.shade300, child: const Icon(Iconsax.gallery_slash)),
                  ),
                  // Subtle vignette for readability
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66000000), // top dark overlay
                          Color(0x00000000), // transparent middle
                          Color(0x22000000), // slight bottom dark
                        ],
                      ),
                    ),
                  ),
                  // Bottom fade to page background to avoid hard edge
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.grey.shade100, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final left = _buildLeftImage();
                final right = _buildRightDetails(context);
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: left),
                      const SizedBox(width: 24),
                      Expanded(flex: 7, child: right),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [left, const SizedBox(height: 20), right],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: ElevatedButton.icon(
          onPressed: _addToCart,
          icon: const Icon(Iconsax.shopping_bag),
          label: Text(_selectedPack == null ? 'Add to Cart' : 'Add to Cart (${_selectedPack!.size})'),
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
}
