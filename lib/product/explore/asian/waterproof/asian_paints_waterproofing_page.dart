import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../product_display_page.dart';

class AsianPaintsWaterproofingPage extends StatelessWidget {
  const AsianPaintsWaterproofingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // List of waterproofing categories
    final List<Map<String, dynamic>> categories = [
      {'title': "Terrace & Tanks", 'icon': Iconsax.home_2},
      {'title': "Exterior", 'icon': Iconsax.building_4},
      {'title': "Interior", 'icon': Iconsax.gallery},
      {'title': "Bathroom", 'icon': Iconsax.safe_home},
      {'title': "Cracks & Joints", 'icon': Iconsax.danger},
      {'title': "Tiling Solutions", 'icon': Iconsax.row_vertical},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Asian Paints - Waterproofing", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2, // Adjust aspect ratio for better look
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildGridItem(
            context,
            category['title'],
            category['icon'],
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDisplayPage(title: category['title'], category: "Waterproofing", subCategory: category['title']))),
          );
        },
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepOrange),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}