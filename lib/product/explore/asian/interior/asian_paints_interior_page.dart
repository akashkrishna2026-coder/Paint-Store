import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:c_h_p/product/explore/product_display_page.dart';
import 'package:c_h_p/pages/core/cart_page.dart';

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
        backgroundColor:
            const Color(0xFFF8F9FA), // A lighter, modern background
        appBar: AppBar(
          title: Text(
            "Interior Paints",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          backgroundColor: Colors.white,
          elevation: 0, // Cleaner look with no shadow
          iconTheme: const IconThemeData(color: Colors.black87),
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)),
              ),
              child: TabBar(
                labelColor: Colors.deepOrange,
                unselectedLabelColor: Colors.grey.shade600,
                indicator: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.deepOrange, width: 3)),
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
                  Text("Interior Wall Paints",
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text("Explore our versatile range of products",
                      style: GoogleFonts.poppins(
                          color: Colors.grey.shade700, fontSize: 14)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProductDisplayPage(
                          title: "All Interior Paints", category: "Interior"))),
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("View All"),
            ),
          ],
        ),

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
                subtitle: "Premium finish paints",
                badge: "LIME BASED",
                assetImage: "assets/image_c505f5.png",
                networkImageUrl:
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuBigJD2vQoIYV5J3nIxk9A73Yfa-G-3jXt0k5yOsAepvRNKpK8_Sb1jIUTH7Dr59jKSW8cEYdoXxcKnFy5pJlBWJfrc60o87aibiJvIC8Ljtl67XLeSVAt0rD0_ypn2v7zq7U-kn2J5rfhuTkAALJcIHpAYF3yRbidc8D_YEsInzB0qg96YOjxSGgMTC25bs_7otW5jxKHGJn2M4EAhMmt-CZCd8kKPgObLuaSy4hnKUoXdToi939-_sZ63W2N6vo3WezmOwYjuks4",
                warranty: "10",
                overlayColor: const Color(0xFF6A78D1),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SuperLuxuryPage())),
              ),
            ),
            Hero(
              tag: "Luxury", // Unique tag
              child: _AnimatedProductCard(
                title: "Luxury",
                subtitle: "High sheen finish",
                badge: "EMULSIONS",
                assetImage: "assets/image_b83903.png",
                networkImageUrl:
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuBApUDyigH6GyMF8SxDA78u-tdxVB14Zdm5_R5hM_xCTUYxCTVyXQ-A6eEX3Wa-LP0IbuhUFXfT_Khzof0vAq1c5LI5oysgSMdp6dRTjDMnivcoaGc6abRBW_Vh-P2XTG2nJNxxuzDI-pzImrhES_jY5rRlCCRIS8hrJ84aJB1gZy_NGYZ0G-dH-PrIsWBZ3d1IKNMAskY7Qqzk_mAYrZA9ForaaIRl2xY5dG-zyiHSis7USLO4xnpUwXkZZE74fgnzN4mBN_gldng",
                warranty: "8",
                overlayColor: const Color(0xFF295362),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LuxuryPage())),
              ),
            ),
            Hero(
              tag: "Premium", // Unique tag
              child: _AnimatedProductCard(
                title: "Premium",
                subtitle: "Rich smooth finish",
                badge: "EMULSIONS",
                assetImage: "assets/image_b8b149.png",
                networkImageUrl:
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuAn-UFe4ey3QW8Vwo0PXFkzAfY4voxWFJ631SGr31WrXNIlr4f4gZxSWzfu4xO0F3ndCOUb_lTvwu-egpT3-qDOhMkjAia37w-F2lVN66-Zb7771EEkysVKD2Pcg7qXR3SUIAniTlBoai93sGgremjXYmNdS28bqx9gnOifrBh1f0VxDcBUCLc0XSDi3BkF5m8t35K7Y_2A68yXj2P5DKSmx-Adzx2HnT-u8dJQiQaIHyWPwGVW3Rc7wK-4Y5k14az919ewBPAM4D8",
                warranty: "6",
                overlayColor: const Color(0xFF2F6F5E),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PremiumPage())),
              ),
            ),
            Hero(
              tag: "Economy", // Unique tag
              child: _AnimatedProductCard(
                title: "Economy",
                subtitle: "Value for money",
                badge: "BUDGET",
                assetImage: "assets/image_c55c29.png",
                networkImageUrl:
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuDzPmoHBJRaCzxl3rR4v8uctu0Q02hMXTLI5_-4xnTZEzTgzyL6k_kgfKgC0v-1pFyHBZ_wEZEvcpSZXK_r7FQHRp4774jJmkfvbmJZQNcUTig-8ZAqyh4qbZZOw1QoYpN7azhfHF0SXE-bqlcwghmh0tRZrwNG7_n_W8tounChknAtZrSXa2ZE-1m2iqzrOJeEPQ6LIMPkZTGAqlaG2_0zNtUDLLcqeH0FxIXrpETsgO6z05qExJpD7lkzDPojJj_WOy6AWzborO8",
                warranty: "4",
                overlayColor: const Color(0xFFB9975B),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EconomyPage())),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Stateless version without any animation
class _AnimatedProductCard extends StatelessWidget {
  const _AnimatedProductCard({
    required this.title,
    required this.subtitle,
    this.badge,
    this.networkImageUrl,
    required this.assetImage,
    required this.warranty,
    required this.overlayColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String? badge;
  final String? networkImageUrl;
  final String assetImage;
  final String warranty;
  final Color overlayColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = _buildProductCategoryCard(
      context: context,
      title: title,
      subtitle: subtitle,
      badge: badge,
      networkImageUrl: networkImageUrl,
      assetImage: assetImage,
      warranty: warranty,
      overlayColor: overlayColor,
      onTap: onTap,
    );
    return RepaintBoundary(child: card);
  }
}

// Reusable widget for creating the product category cards with a modern style.
Widget _buildProductCategoryCard({
  required BuildContext context,
  required String title,
  required String subtitle,
  String? badge,
  String? networkImageUrl,
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
              child: RepaintBoundary(
                child: (networkImageUrl != null && networkImageUrl.isNotEmpty)
                    ? Image.network(
                        networkImageUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                        errorBuilder: (c, e, s) => Image.asset(
                          assetImage,
                          fit: BoxFit.cover,
                          cacheWidth: 600,
                        ),
                      )
                    : Image.asset(
                        assetImage,
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                        errorBuilder: (c, e, s) => Container(
                            color: overlayColor.withValues(alpha: 0.5),
                            child: const Center(
                                child: Icon(Iconsax.gallery_slash,
                                    color: Colors.white70, size: 40))),
                      ),
              ),
            ),
            if (badge != null && badge.isNotEmpty)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    badge.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
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
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8))),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("UP TO",
                                style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11)),
                            Text(warranty,
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0)),
                            Text("YEARS\nWarranty+",
                                style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11,
                                    height: 1.0)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: const Icon(Iconsax.arrow_right_3,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
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
