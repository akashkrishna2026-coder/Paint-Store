import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// Assuming 'c_h_p' is your project name
import 'package:c_h_p/pages/view_painters_page.dart';
import 'package:c_h_p/pages/work_in_progress_page.dart';

class PaintingServicesPage extends StatelessWidget {
  const PaintingServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Painting Services", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _ServiceCard(
            icon: Iconsax.user_tag,
            title: "Professional Painters",
            subtitle: "Hire our team of expert painters for a flawless finish, every time.",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewPaintersPage()));
            },
          ),
          _ServiceCard(
            icon: Iconsax.camera,
            title: "Color Visualization",
            subtitle: "Use our in-app tool to virtually paint your room before you buy.",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkInProgressPage()));
            },
          ),
          _ServiceCard(
            icon: Iconsax.calculator,
            title: "Paint Calculator",
            subtitle: "Estimate the exact amount of paint you'll need for your project.",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkInProgressPage()));
            },
          ),
        ]
            .animate(interval: 200.ms)
            .fade(duration: 500.ms)
            .slideY(begin: 0.2, curve: Curves.easeOut),
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_ServiceCard> createState() => __ServiceCardState();
}

class __ServiceCardState extends State<_ServiceCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovering = true),
        onTapUp: (_) => setState(() => _isHovering = false),
        onTapCancel: () => setState(() => _isHovering = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 20),
          transform: _isHovering ? (Matrix4.identity()..translate(0, -8, 0)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isHovering
                ? [BoxShadow(color: Colors.deepOrange.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.deepOrange.shade50,
                child: Icon(widget.icon, size: 28, color: Colors.deepOrange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.subtitle, style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              // ⭐ UI ENHANCEMENT: Added an animation to the arrow icon
              AnimatedSlide(
                offset: _isHovering ? const Offset(0.15, 0) : Offset.zero,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: const Icon(Iconsax.arrow_right_3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}