import 'package:c_h_p/product/explore/product_display_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class AsianPaintsExteriorPage extends StatelessWidget {
  const AsianPaintsExteriorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Asian Paints - Exterior", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSubCategory(
            context,
            "Paints",
            Iconsax.color_swatch,
            [
              "Ultima Exterior Emulsions",
              "Apex Exterior Emulsions",
              "Ace Exterior Emulsions",
            ],
          ),
          _buildSubCategory(
            context,
            "Textures",
            Iconsax.brush_3,
            [
              "Ultima Allura Exterior Textures",
              "Apex Createx Exterior Textures",
              "Duracast Exterior Textures",
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategory(BuildContext context, String title, IconData icon, List<String> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            Column(
              children: items.map((item) => ListTile(
                title: Text(item, style: GoogleFonts.poppins()),
                trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDisplayPage(title: item, subCategory: item))),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}