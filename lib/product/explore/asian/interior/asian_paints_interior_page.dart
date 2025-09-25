import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:c_h_p/pages/color_catalogue_page.dart';
import 'package:c_h_p/product/explore/product_display_page.dart';
import 'package:c_h_p/product/explore/asian/interior/super_luxury_page.dart';

class AsianPaintsInteriorPage extends StatelessWidget {
  const AsianPaintsInteriorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text("Asian Paints - Interior", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.grey.shade800),
          bottom: TabBar(
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.deepOrange,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Paints"),
              Tab(text: "Textures"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPaintsTab(context),
            _buildTexturesTab(context),
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
                  Text("Interior Wall Paints", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Explore the versatile range of products", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDisplayPage(title: "All Interior Paints", category: "Interior"))),
              child: const Text("View All"),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Grid of Product Categories
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
          children: [
            _buildProductCategoryCard(
              context: context,
              title: "Super Luxury",
              subtitle: "lime based paints",
              assetImage: "assets/image_c505f5.png",
              warranty: "10",
              overlayColor: const Color(0xffD0D3E5),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperLuxuryPage())),
            ),
            _buildProductCategoryCard(
              context: context,
              title: "Luxury",
              subtitle: "emulsions",
              assetImage: "assets/image_b83903.png", // Corrected extension
              warranty: "8",
              overlayColor: const Color(0xff295362),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDisplayPage(title: "Luxury Paints", subCategory: "Luxury"))),
            ),
            _buildProductCategoryCard(
              context: context,
              title: "Premium",
              subtitle: "emulsions",
              assetImage: "assets/image_b8b149.png", // Corrected extension
              warranty: "6",
              overlayColor: const Color(0xff2F6F5E),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDisplayPage(title: "Premium Paints", subCategory: "Premium"))),
            ),
            _buildProductCategoryCard(
              context: context,
              title: "Economy",
              subtitle: "emulsions",
              assetImage: "assets/image_c55c29.png",
              warranty: "4",
              overlayColor: const Color(0xffB9975B),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDisplayPage(title: "Economy Paints", subCategory: "Economy"))),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Link to Color Catalogue
        ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Iconsax.color_swatch, color: Colors.deepOrange),
          title: Text("Popular Shades", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          subtitle: const Text("Browse our trending color catalogue"),
          trailing: const Icon(Iconsax.arrow_right_3),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ColorCataloguePage())),
        ),
      ],
    );
  }

  Widget _buildTexturesTab(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Iconsax.search_normal_1),
        label: const Text("View Textures"),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDisplayPage(title: "Interior Textures", category: "Textures"))),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      ),
    );
  }

  Widget _buildProductCategoryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String assetImage,
    required String warranty,
    required Color overlayColor,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(assetImage, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      overlayColor.withOpacity(0.8),
                      overlayColor.withOpacity(0.5),
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
                  Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(color: Colors.white, height: 1.1),
                      children: [
                        const TextSpan(text: "UPTO\n", style: TextStyle(fontSize: 10)),
                        TextSpan(text: warranty, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                        const TextSpan(text: " YEARS\nWARRANTY+", style: TextStyle(fontSize: 10)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Explore", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
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
    );
  }
}