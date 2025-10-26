import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:c_h_p/pages/core/cart_page.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'asian/interior/asian_paints_interior_page.dart';

import 'indigo/interior-emulsions/indigo_paints_interior_page.dart';

class InteriorPage extends StatelessWidget {
  const InteriorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
// ⭐ UI: Added a subtle gradient background for a less bland look

      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Text("Select a Brand",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
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

      body: Container(
        width: double.infinity,

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

// ⭐ UI: Centered the cards vertically on the page

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BuildBrandOption(
                assetLogo: "assets/asian.jpg",
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AsianPaintsInteriorPage())),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .moveY(begin: 30, curve: Curves.easeOut),

              const SizedBox(
                  height: 20), // ⭐ UI: Increased spacing between cards

              _BuildBrandOption(
                assetLogo: "assets/indigo.jpg",
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const IndigoPaintsInteriorPage())),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 300.ms)
                  .moveY(begin: 30, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildBrandOption extends StatefulWidget {
  final String assetLogo;

  final VoidCallback onTap;

  const _BuildBrandOption({required this.assetLogo, required this.onTap});

  @override
  State<_BuildBrandOption> createState() => _BuildBrandOptionState();
}

class _BuildBrandOptionState extends State<_BuildBrandOption> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        scale: _isHovering ? 1.05 : 1.0,
        duration: 200.ms,
        curve: Curves.easeOut,
        child: Card(
          margin: EdgeInsets.zero, // ⭐ UI: Removed default card margin

          elevation: _isHovering ? 10 : 4,

          shadowColor: Colors.black.withValues(alpha: 0.15),

          clipBehavior: Clip.antiAlias,

          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

          child: InkWell(
            onTap: widget.onTap,
            child: Container(
              height: 150, // ⭐ UI: Increased card height

              padding: const EdgeInsets.all(16),

              color: Colors.white,

              child: Center(
// ⭐ UI: Added padding around the logo inside the card

                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    widget.assetLogo,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
