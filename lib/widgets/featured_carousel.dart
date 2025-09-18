import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // ⭐ 1. IMPORT ANIMATION PACKAGE
import 'package:google_fonts/google_fonts.dart';

class FeaturedCarousel extends StatefulWidget {
  final List<Map<String, String>> scrollItems;
  final void Function(Map<String, String> item) onItemTap;

  const FeaturedCarousel({
    super.key,
    required this.scrollItems,
    required this.onItemTap,
  });

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  // ⭐ 2. VARIABLE TO TRACK SCROLL OFFSET FOR PARALLAX
  double _pageOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // ⭐ 3. ADD A LISTENER TO UPDATE THE SCROLL OFFSET
    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() {
          _pageOffset = _pageController.page!;
        });
      }
    });

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % widget.scrollItems.length;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.scrollItems.length,
        itemBuilder: (context, index) {
          final item = widget.scrollItems[index];
          // ⭐ 4. CALCULATE THE PARALLAX EFFECT OFFSET
          double parallaxOffset = (_pageOffset - index) * (MediaQuery.of(context).size.width / 3);

          return GestureDetector(
            onTap: () => widget.onItemTap(item),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              // ⭐ 5. USE A STACK TO LAYER THE IMAGE, GRADIENT, AND TEXT
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // --- BACKGROUND IMAGE WITH PARALLAX ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Transform.translate(
                      offset: Offset(parallaxOffset, 0),
                      child: Image.asset(
                        item['image']!,
                        fit: BoxFit.cover,
                        // This helps the image feel like it fills a larger space
                        width: MediaQuery.of(context).size.width * 1.2,
                        height: 200,
                      ),
                    ),
                  ),

                  // --- GRADIENT OVERLAY FOR TEXT READABILITY ---
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),

                  // --- ANIMATED TEXT CONTENT ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [const Shadow(blurRadius: 5, color: Colors.black54)],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['subtitle']!,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                  // ⭐ 6. APPLY ANIMATION TO THE TEXT COLUMN
                      .animate(
                    // This key ensures the animation re-triggers on auto-scroll
                    key: ValueKey('${item['title']}$_currentPage'),
                    target: _currentPage == index ? 1 : 0,
                  )
                      .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}