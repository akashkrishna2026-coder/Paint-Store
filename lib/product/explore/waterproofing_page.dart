import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'asian/waterproof/asian_paints_waterproofing_page.dart';
import 'indigo/indigo_paints_waterproofing_page.dart';

class WaterproofingPage extends StatelessWidget {
  const WaterproofingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Select a Brand", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBrandOption(
            context: context,
            brandName: "Asian Paints",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AsianPaintsWaterproofingPage())),
          ),
          _buildBrandOption(
            context: context,
            brandName: "Indigo Paints",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IndigoPaintsWaterproofingPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandOption({
    required BuildContext context,
    required String brandName,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        title: Text(brandName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: const Icon(Iconsax.arrow_right_3, color: Colors.deepOrange),
        onTap: onTap,
      ),
    );
  }
}