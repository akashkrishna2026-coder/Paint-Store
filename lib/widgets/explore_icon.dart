import 'package:flutter/material.dart';
import 'dart:math' as math;

class HyperRealisticExploreIcon extends StatefulWidget {
  // Increased default size for a bigger, more clickable icon
  final double size;
  const HyperRealisticExploreIcon({super.key, this.size = 38.0});

  @override
  State<HyperRealisticExploreIcon> createState() => _HyperRealisticExploreIconState();
}

class _HyperRealisticExploreIconState extends State<HyperRealisticExploreIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10), // The speed of one full rotation
      vsync: this,
    )..repeat(); // Make the animation loop forever
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Casing (Static Background)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE0E0E0), Color(0xFFC0C0C0), Color(0xFF9E9E9E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.1, 0.5, 0.9],
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: widget.size * 0.15, offset: Offset(widget.size * 0.08, widget.size * 0.08)),
                BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: widget.size * 0.1, offset: Offset(-widget.size * 0.04, -widget.size * 0.04)),
              ],
              border: Border.all(color: const Color(0xFF757575), width: widget.size * 0.01),
            ),
          ),

          // Inner Face with "Glass" Effect (Static Background)
          Container(
            margin: EdgeInsets.all(widget.size * 0.08),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5F5F5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: widget.size * 0.05, spreadRadius: -widget.size * 0.02, offset: Offset(0, widget.size * 0.02)),
                BoxShadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: widget.size * 0.03, spreadRadius: -widget.size * 0.01, offset: Offset(0, -widget.size * 0.01)),
              ],
            ),
          ),

          // Subtle tick marks for added realism
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CompassTicksPainter(size: widget.size),
          ),

          // The parts that will spin
          RotationTransition(
            turns: _controller,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Compass Needle (Red Part)
                Transform.rotate(
                  angle: -0.785, // 45 degrees North-East
                  child: ClipPath(
                    clipper: _TriangleClipper(),
                    child: Container(
                      width: widget.size * 0.65,
                      height: widget.size * 0.65,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepOrange, Color(0xFFC62828), Color(0xFF880E4F)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Compass Needle (White Part)
                Transform.rotate(
                  angle: 2.356, // 135 degrees South-West
                  child: ClipPath(
                    clipper: _TriangleClipper(),
                    child: Container(
                      width: widget.size * 0.65,
                      height: widget.size * 0.65,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFAFAFA), Color(0xFFE0E0E0), Color(0xFFB0B0B0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Central Pivot Point (Stays on top and doesn't spin)
          Container(
            width: widget.size * 0.18,
            height: widget.size * 0.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF616161), Color(0xFF212121)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: widget.size * 0.03, offset: Offset(widget.size * 0.01, widget.size * 0.01)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for the compass tick marks
class _CompassTicksPainter extends CustomPainter {
  final double size;
  _CompassTicksPainter({required this.size});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.75;

    for (int i = 0; i < 360; i += 30) {
      final angle = (i * math.pi / 180);
      final p1 = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      final p2 = Offset(center.dx + (radius - 4) * math.cos(angle), center.dy + (radius - 4) * math.sin(angle));
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Clipper for the needle shape (unchanged)
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}