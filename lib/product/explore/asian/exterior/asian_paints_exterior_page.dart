import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:c_h_p/product/explore/product_display_page.dart';
import 'package:c_h_p/product/explore/asian/interior/textures/textures_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';
import 'package:c_h_p/pages/core/cart_page.dart';
import 'package:iconsax/iconsax.dart';

// ⭐ IMPORT THE NEW PAGES YOU CREATED
import 'ultima_page.dart';
import 'apex_page.dart';
import 'ace_page.dart';

class AsianPaintsExteriorPage extends StatelessWidget {
  const AsianPaintsExteriorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text("Asian Paints - Exterior",
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
          bottom: TabBar(
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey.shade600,
            indicator: MaterialIndicator(
              color: Colors.deepOrange,
              height: 4,
              topLeftRadius: 8,
              topRightRadius: 8,
              tabPosition: TabPosition.bottom,
            ),
            tabs: const [
              Tab(text: "Paints"),
              Tab(text: "Textures"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPaintsTab(context),
            const TexturesPage(category: "Exterior")
                .animate()
                .fadeIn(duration: 400.ms, curve: Curves.easeIn),
          ],
        ),
      ),
    );
  }

  Widget _buildPaintsTab(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const cardAspectRatio = 0.7;
    const crossAxisSpacing = 16.0;
    final cardWidth = (screenWidth - (2 * 16) - crossAxisSpacing) / 2;
    final cardHeight = cardWidth / cardAspectRatio;

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
                  Text("Exterior Wall Paints",
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Protection and beauty for outer walls",
                      style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProductDisplayPage(
                          title: "All Exterior Paints", category: "Exterior"))),
              child: const Text("View All"),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Card Layout
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: cardHeight,
                    child: Hero(
                      tag: "Ultima_card",
                      child: ProductCategoryCard(
                        title: "Ultima",
                        subtitle: "emulsions",
                        assetImage: "assets/ultima.jpg",
                        warranty: "15",
                        overlayColor: const Color(0xff004d40),
                        // ⭐ FIX: Navigate to the new UltimaPage
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UltimaPage())),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: crossAxisSpacing),
                Expanded(
                  child: SizedBox(
                    height: cardHeight,
                    child: Hero(
                      tag: "Apex_card",
                      child: ProductCategoryCard(
                        title: "Apex",
                        subtitle: "emulsions",
                        assetImage: "assets/Apex.jpg",
                        warranty: "8",
                        overlayColor: const Color(0xff4a148c),
                        // ⭐ FIX: Navigate to the new ApexPage
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ApexPage())),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: crossAxisSpacing),
            Center(
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: Hero(
                  tag: "Ace_card",
                  child: ProductCategoryCard(
                    title: "Ace",
                    subtitle: "emulsions",
                    assetImage: "assets/Ace.jpg",
                    warranty: "5",
                    overlayColor: const Color(0xffbf360c),
                    // ⭐ FIX: Navigate to the new AcePage
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AcePage())),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// THE REUSABLE PRODUCT CARD (This widget is unchanged and correct)
class ProductCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String assetImage;
  final String warranty;
  final Color overlayColor;
  final VoidCallback onTap;

  const ProductCategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.assetImage,
    required this.warranty,
    required this.overlayColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(assetImage,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                        color: overlayColor.withValues(alpha: 0.5),
                        child: const Center(
                            child: Icon(Iconsax.gallery_slash,
                                color: Colors.white70, size: 40)))),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        overlayColor.withValues(alpha: 0.8),
                        overlayColor.withValues(alpha: 0.5)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                            color: Colors.white, height: 1.1),
                        children: [
                          const TextSpan(
                              text: "UPTO\n", style: TextStyle(fontSize: 10)),
                          TextSpan(
                              text: warranty,
                              style: const TextStyle(
                                  fontSize: 36, fontWeight: FontWeight.bold)),
                          const TextSpan(
                              text: " YEARS\nWARRANTY+",
                              style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Explore",
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            const Icon(Iconsax.arrow_right_3, size: 14),
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
}
