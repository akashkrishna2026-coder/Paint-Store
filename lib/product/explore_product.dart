import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'explore/interior_page.dart';
import 'explore/exterior_page.dart';
import 'explore/waterproofing_page.dart';
import '../pages/color_catalogue_page.dart'; // Import the catalogue page
import '../pages/core/cart_page.dart';

class ExploreProductPage extends StatefulWidget {
  const ExploreProductPage({super.key});

  @override
  State<ExploreProductPage> createState() => _ExploreProductPageState();
}

class _ExploreProductPageState extends State<ExploreProductPage> {
  // This list holds the images for pre-caching.
  final List<AssetImage> _images = [
    const AssetImage("assets/image_b8a96a.jpg"),
    const AssetImage("assets/image_b8aca7.jpg"),
    const AssetImage("assets/image_b8b0ca.jpg"),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache images to help prevent flicker on first load
    for (var image in _images) {
      precacheImage(image, context);
    }
  }

  // Helper function for navigation, keeping the fade transition
  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Explore Products", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
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
        padding: const EdgeInsets.all(16.0),
        children: [
          // ⭐ FIX: Pass the Hero tag directly to the card builder
          _buildCategoryCard(
            tag: 'interior_card', // Unique tag for Hero animation
            title: "Interior Wall Paints",
            subtitle: "Paints, textures, and wallpapers for your home!",
            imageProvider: _images[0],
            onTap: () => _navigateToPage(context, const InteriorPage()),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms).moveY(begin: 30, curve: Curves.easeOut),

          _buildCategoryCard(
            tag: 'exterior_card', // Unique tag
            title: "Exterior Wall Paints",
            subtitle: "Weather-proof paints for a lasting impression.",
            imageProvider: _images[1],
            onTap: () => _navigateToPage(context, const ExteriorPage()),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).moveY(begin: 30, curve: Curves.easeOut),

          _buildCategoryCard(
            tag: 'waterproofing_card', // Unique tag
            title: "Waterproofing",
            subtitle: "One-stop solutions for a leak-free home.",
            imageProvider: _images[2],
            onTap: () => _navigateToPage(context, const WaterproofingPage()),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms).moveY(begin: 30, curve: Curves.easeOut),

          const SizedBox(height: 24), // Spacing before the button

          // Explore Catalogue Button (Corrected Icon)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ColorCataloguePage()),
              );
            },
            icon: const Icon(Iconsax.colors_square),
            label: Text('Explore Color Catalogue', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.deepOrange, backgroundColor: Colors.deepOrange.shade50,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.deepOrange.shade100),
              ),
              elevation: 0,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms).moveY(begin: 30, curve: Curves.easeOut),
        ],
      ),
    );
  }

  // ⭐ FIX: This card builder now includes the Hero widget internally
  Widget _buildCategoryCard({
    required String tag, // Added tag parameter
    required String title,
    required String subtitle,
    required ImageProvider imageProvider,
    required VoidCallback onTap,
  }) {
    return Padding(
      // Added padding to prevent potential clipping issues during animation
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        type: MaterialType.transparency,
        child: Hero(
          tag: tag,
          // ⭐ FIX: Added flightShuttleBuilder for smoother transition
          flightShuttleBuilder: (
              BuildContext flightContext,
              Animation<double> animation,
              HeroFlightDirection flightDirection,
              BuildContext fromHeroContext,
              BuildContext toHeroContext,
              ) {
            final Hero toHero = toHeroContext.widget as Hero;
            // Apply a slight scale animation during the flight
            return ScaleTransition(
              scale: animation.drive(
                Tween<double>(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: toHero.child,
            );
          },
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 200,
              // Removed margin, using Padding wrapper instead
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [const Shadow(blurRadius: 2, color: Colors.black54)],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      shadows: [const Shadow(blurRadius: 1, color: Colors.black45)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}