import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:c_h_p/product/explore/product_display_page.dart';
import 'package:iconsax/iconsax.dart';
import 'package:c_h_p/pages/core/cart_page.dart';

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
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: Text('Indigo Paints – Interior',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
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
      ),
      body: Column(
        children: [
          // Subtitle under title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Explore our premium range of interior paints\nTailored for every finish.',
                style: GoogleFonts.poppins(
                    color: Colors.grey.shade700, fontSize: 13, height: 1.35),
              ),
            ),
          ),
          // Grid tiles
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final m = items[i];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: InkWell(
                    onTap: m['onTap'] as VoidCallback,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(m['icon'] as IconData,
                                size: 28, color: Colors.deepOrange),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            m['title'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom button
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductDisplayPage(
                        title: 'Indigo Interior - All',
                        category: 'Interior',
                        brand: 'Indigo',
                      ),
                    ),
                  );
                },
                icon: const Icon(Iconsax.box),
                label: Text('Browse All Interior',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
