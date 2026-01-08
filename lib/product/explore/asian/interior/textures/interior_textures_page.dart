import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:c_h_p/product/explore/asian/interior/textures/textures_page.dart';
import 'package:iconsax/iconsax.dart';
import 'package:c_h_p/pages/core/cart_page.dart';

class InteriorTexturesPage extends StatelessWidget {
  const InteriorTexturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Select a Brand",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBrandOption(
            context: context,
            brandName: "Asian Paints",
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const TexturesPage(category: "Interior")));
            },
          ),
          _buildBrandOption(
            context: context,
            brandName: "Indigo Paints",
            onTap: () {
              // Placeholder for Indigo's interior textures
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBrandOption(
      {required BuildContext context,
      required String brandName,
      required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        title: Text(brandName,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
