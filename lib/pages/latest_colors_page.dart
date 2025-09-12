import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class LatestColorsPage extends StatelessWidget {
  const LatestColorsPage({super.key});

  // Sample data inspired by your reference image.
  // You can replace this with data fetched from Firebase.
  final List<Map<String, dynamic>> _colors = const [
    {'name': 'Rock Wall', 'color': Color(0xFF94938b)},
    {'name': 'Walnut Shell', 'color': Color(0xFFc89f70)},
    {'name': 'Jodhpur Walls', 'color': Color(0xFF3b78ae)},
    {'name': 'Dune Walk', 'color': Color(0xFFf0e5d1)},
    {'name': 'Vintage Walnut', 'color': Color(0xFF6f5c4b)},
    {'name': 'Walnut Cream', 'color': Color(0xFFe2d5c2)},
    {'name': 'Walnut Bark', 'color': Color(0xFF9d7f64)},
    {'name': 'Rainforest Walk', 'color': Color(0xFF4a7f5a)},
    {'name': 'Vintage Wine', 'color': Color(0xFF7b4c44)},
    {'name': 'Desert Tan', 'color': Color(0xFFd4b997)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Latest Colors", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Trending Shades",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Discover the perfect hue for your space from our curated collection.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _colors.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final colorItem = _colors[index];
                return _buildColorSwatch(
                  context,
                  color: colorItem['color'],
                  name: colorItem['name'],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(BuildContext context, {required Color color, required String name}) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
