import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// A helper function to convert a hex string to a Color object
Color hexToColor(String code) {
  return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}

class LatestColorsPage extends StatelessWidget {
  const LatestColorsPage({super.key});

  // Sample data simulating what you would fetch from Firebase.
  // Each map represents a product with a name and a hex code.
  final List<Map<String, String>> _colors = const [
    {'name': 'Rock Wall', 'hexCode': '#94938b'},
    {'name': 'Walnut Shell', 'hexCode': '#c89f70'},
    {'name': 'Jodhpur Walls', 'hexCode': '#3b78ae'},
    {'name': 'Dune Walk', 'hexCode': '#f0e5d1'},
    {'name': 'Vintage Walnut', 'hexCode': '#6f5c4b'},
    {'name': 'Walnut Cream', 'hexCode': '#e2d5c2'},
    {'name': 'Walnut Bark', 'hexCode': '#9d7f64'},
    {'name': 'Rainforest Walk', 'hexCode': '#4a7f5a'},
    {'name': 'Vintage Wine', 'hexCode': '#7b4c44'},
    {'name': 'Desert Tan', 'hexCode': '#d4b997'},
    {'name': 'Slate Grey', 'hexCode': '#5a5a5a'},
    {'name': 'Terracotta', 'hexCode': '#c06c57'},
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
                  color: hexToColor(colorItem['hexCode']!),
                  name: colorItem['name']!,
                  hexCode: colorItem['hexCode']!,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(BuildContext context, {required Color color, required String name, required String hexCode}) {
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
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hexCode,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

