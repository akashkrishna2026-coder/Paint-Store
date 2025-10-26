import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:c_h_p/product/explore/product_display_page.dart';
import 'package:iconsax/iconsax.dart';

class IndigoPaintsInteriorPage extends StatelessWidget {
  const IndigoPaintsInteriorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'All',
        'icon': Iconsax.layer,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProductDisplayPage(
                  title: 'Indigo Interior - All',
                  category: 'Interior',
                  brand: 'Indigo',
                ),
              ),
            ),
      },
      {
        'title': 'Platinum',
        'icon': Iconsax.diamonds,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProductDisplayPage(
                  title: 'Indigo Interior - Platinum',
                  category: 'Interior',
                  subCategory: 'Platinum',
                  brand: 'Indigo',
                ),
              ),
            ),
      },
      {
        'title': 'Gold',
        'icon': Iconsax.crown_1,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProductDisplayPage(
                  title: 'Indigo Interior - Gold',
                  category: 'Interior',
                  subCategory: 'Gold',
                  brand: 'Indigo',
                ),
              ),
            ),
      },
      {
        'title': 'Silver',
        'icon': Iconsax.medal_star,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProductDisplayPage(
                  title: 'Indigo Interior - Silver',
                  category: 'Interior',
                  subCategory: 'Silver',
                  brand: 'Indigo',
                ),
              ),
            ),
      },
      {
        'title': 'Bronze',
        'icon': Iconsax.award,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProductDisplayPage(
                  title: 'Indigo Interior - Bronze',
                  category: 'Interior',
                  subCategory: 'Bronze',
                  brand: 'Indigo',
                ),
              ),
            ),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Indigo Paints - Interior', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
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
          childAspectRatio: 1.1,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final m = items[i];
          return Card(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: m['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(m['icon'] as IconData, size: 40, color: Colors.deepOrange),
                    const SizedBox(height: 12),
                    Text(m['title'] as String, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}