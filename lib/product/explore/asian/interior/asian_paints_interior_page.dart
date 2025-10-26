import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:c_h_p/product/explore/product_display_page.dart';

// Corrected imports for all the product pages
import 'package:c_h_p/product/explore/asian/interior/super_luxury_page.dart';
import 'package:c_h_p/product/explore/asian/interior/luxury.dart';
import 'package:c_h_p/product/explore/asian/interior/premium.dart';
import 'package:c_h_p/product/explore/asian/interior/economy.dart';
// Import for the new textures page
import 'package:c_h_p/product/explore/asian/interior/textures/textures_page.dart';


class AsianPaintsInteriorPage extends StatelessWidget {
  const AsianPaintsInteriorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // A lighter, modern background
        appBar: AppBar(
          title: Text(
            "Asian Paints - Interior",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          backgroundColor: Colors.white,
          elevation: 0, // Cleaner look with no shadow
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)),
              ),
              child: TabBar(
                labelColor: Colors.deepOrange,
                unselectedLabelColor: Colors.grey.shade600,
                indicator: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.deepOrange, width: 3)),
                ),
                tabs: const [
                  Tab(text: "PAINTS"),
                  Tab(text: "TEXTURES"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildPaintsTab(context),
            const TexturesPage(category: "Interior"),
          ],
        ),
      ),
    );
  }

  Widget _buildPaintsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Header Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Interior Wall Paints", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text("Explore the versatile range of products", style: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 14)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDisplayPage(title: "All Interior Paints", category: "Interior"))),
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("View All"),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Grid of Product Categories
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
          children: [
            // ⭐ ADDED: Hero widget for smooth transition
            Hero(
              tag: "Super Luxury", // Unique tag for this card
              child: _AnimatedProductCard(
                title: "Super Luxury",
                subtitle: "lime based paints",
                assetImage: "assets/image_c505f5.png",
                warranty: "10",
                overlayColor: const Color(0xFF6A78D1),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperLuxuryPage())),
              ),
            ),
            Hero(
              tag: "Luxury", // Unique tag
              child: _AnimatedProductCard(
                title: "Luxury",
                subtitle: "emulsions",
                assetImage: "assets/image_b83903.png",
                warranty: "8",
                overlayColor: const Color(0xFF295362),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LuxuryPage())),
              ),
            ),
            Hero(
              tag: "Premium", // Unique tag
              child: _AnimatedProductCard(
                title: "Premium",
                subtitle: "emulsions",
                assetImage: "assets/image_b8b149.png",
                warranty: "6",
                overlayColor: const Color(0xFF2F6F5E),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage())),
              ),
            ),
            Hero(
              tag: "Economy", // Unique tag
              child: _AnimatedProductCard(
                title: "Economy",
                subtitle: "emulsions",
                assetImage: "assets/image_c55c29.png",
                warranty: "4",
                overlayColor: const Color(0xFFB9975B),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EconomyPage())),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// StatefulWidget to create a continuous "pulsing" animation
class _AnimatedProductCard extends StatefulWidget {
  const _AnimatedProductCard({
    required this.title,
    required this.subtitle,
    required this.assetImage,
    required this.warranty,
    required this.overlayColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String assetImage;
  final String warranty;
  final Color overlayColor;
  final VoidCallback onTap;

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: _buildProductCategoryCard(
        context: context,
        title: widget.title,
        subtitle: widget.subtitle,
        assetImage: widget.assetImage,
        warranty: widget.warranty,
        overlayColor: widget.overlayColor,
        onTap: widget.onTap,
      ),
    );
  }
}

// Reusable widget for creating the product category cards with a modern style.
Widget _buildProductCategoryCard({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String assetImage,
  required String warranty,
  required Color overlayColor,
  required VoidCallback onTap,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20), // More rounded corners
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 15,
          offset: const Offset(0, 5),
        )
      ],
    ),
    child: Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                assetImage,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: overlayColor.withValues(alpha: 0.5), child: const Center(child: Icon(Iconsax.gallery_slash, color: Colors.white70, size: 40))),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      overlayColor.withValues(alpha: 0.85),
                      overlayColor.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(color: Colors.white, height: 1.2),
                      children: [
                        const TextSpan(text: "UPTO\n", style: TextStyle(fontSize: 11)),
                        TextSpan(text: warranty, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                        const TextSpan(text: " YEARS\nWARRANTY+", style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Pill shape
                          padding: const EdgeInsets.symmetric(vertical: 10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Explore", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          const Icon(Iconsax.arrow_right_3, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}