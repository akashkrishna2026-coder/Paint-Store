// lib/product/explore_product_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'explore/interior_page.dart';
import 'explore/exterior_page.dart';
import 'explore/waterproofing_page.dart';

class ExploreProductPage extends StatelessWidget {
  const ExploreProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Explore Products", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCategoryCard(
            context: context,
            title: "Interior Wall Paints",
            subtitle: "Paints, textures, and wallpapers for your home!",
            assetImage: "assets/image_b8a96a.jpg", // From your uploaded images
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InteriorPage())),
          ),
          _buildCategoryCard(
            context: context,
            title: "Exterior Wall Paints",
            subtitle: "Weather-proof paints for a lasting impression.",
            assetImage: "assets/image_b8aca7.jpg", // From your uploaded images
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExteriorPage())),
          ),
          _buildCategoryCard(
            context: context,
            title: "Waterproofing",
            subtitle: "One-stop solutions for a leak-free home.",
            assetImage: "assets/image_b8b0ca.jpg", // From your uploaded images
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterproofingPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String assetImage,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(assetImage),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }
}