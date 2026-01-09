import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import 'product_detail_page.dart';
import 'explore/interior_page.dart';
import 'explore/exterior_page.dart';
import 'explore/waterproofing_page.dart';
import '../pages/color_catalogue_page.dart'; // Import the catalogue page
import '../pages/core/home_page.dart';
import '../auth/personal_info_page.dart';
import '../pages/core/cart_page.dart';

class ExploreProductPage extends ConsumerStatefulWidget {
  const ExploreProductPage({super.key});

  @override
  ConsumerState<ExploreProductPage> createState() => _ExploreProductPageState();
}

class _ExploreProductPageState extends ConsumerState<ExploreProductPage> {
  // This list holds three static category images that never refresh.
  static const List<AssetImage> _images = [
    AssetImage("assets/image_b8a96a.jpg"),
    AssetImage("assets/image_b8aca7.jpg"),
    AssetImage("assets/image_b8b0ca.jpg"),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-cache static images once - they will never refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exploreVMProvider.notifier).precacheHeroImages(context);
      // Trigger initial recommended load via ViewModel (idempotent)
      ref.read(exploreVMProvider.notifier).loadRecommended(limit: 10);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No pre-caching here to prevent refresh on navigation
  }

  // Helper function for navigation, keeping the fade transition
  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Widget _buildRecommendedSection() {
    final vmState = ref.watch(exploreVMProvider);
    if (vmState.loading) return const SizedBox.shrink();
    if (vmState.items.isEmpty) return const SizedBox.shrink();
    final items = vmState.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Recommended for you',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.grey.shade800),
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProductDetailPage(product: p)),
                  );
                },
                child: SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: CachedNetworkImage(
                            imageUrl: p.mainImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (c, u) =>
                                Container(color: Colors.grey.shade200),
                            errorWidget: (c, u, e) =>
                                const Icon(Iconsax.gallery_slash),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Explore Products",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
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
          //  Pass the Hero tag directly to the card builder
          _buildCategoryCard(
            tag: 'interior_card', // Unique tag for Hero animation
            title: "Interior Wall Paints",
            subtitle: "Paints, textures, and wallpapers for your home!",
            imageProvider: _images[0],
            onTap: () => _navigateToPage(context, const InteriorPage()),
          ),

          _buildCategoryCard(
            tag: 'exterior_card', // Unique tag
            title: "Exterior Wall Paints",
            subtitle: "Weather-proof paints for a lasting impression.",
            imageProvider: _images[1],
            onTap: () => _navigateToPage(context, const ExteriorPage()),
          ),

          _buildCategoryCard(
            tag: 'waterproofing_card', // Unique tag
            title: "Waterproofing",
            subtitle: "One-stop solutions for a leak-free home.",
            imageProvider: _images[2],
            onTap: () => _navigateToPage(context, const WaterproofingPage()),
          ),

          const SizedBox(height: 16),
          _buildRecommendedSection(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  //  Card builder for category tiles (Hero removed to avoid fade on back navigation)
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
                colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.4), BlendMode.darken),
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
                    shadows: [
                      const Shadow(blurRadius: 2, color: Colors.black54)
                    ],
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    shadows: [
                      const Shadow(blurRadius: 1, color: Colors.black45)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildBottomBar(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.2),
          spreadRadius: 1,
          blurRadius: 15,
          offset: const Offset(0, -5),
        )
      ],
    ),
    child: BottomAppBar(
      color: Colors.white,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BottomItem(
                icon: Iconsax.home_2,
                label: 'Home',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
                active: true,
              ),
              _BottomItem(
                icon: Iconsax.category,
                label: 'Catalog',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ColorCataloguePage()),
                  );
                },
              ),
              _BottomItem(
                icon: Iconsax.brush_2,
                label: 'Visualizer',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const _VisualizerPlaceholder()),
                  );
                },
              ),
              _BottomItem(
                icon: Iconsax.user,
                label: 'Profile',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.deepOrange : Colors.grey.shade600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualizerPlaceholder extends StatelessWidget {
  const _VisualizerPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visualizer')),
      body: const Center(child: Text('Visualizer coming soon')),
    );
  }
}
