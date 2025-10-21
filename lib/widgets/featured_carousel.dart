import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

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
  final ValueNotifier<double> _pageOffset = ValueNotifier<double>(0.0);
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _pageController.addListener(() {
      if (_pageController.hasClients && _pageController.page != null) {
        _pageOffset.value = _pageController.page!;
      }
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % widget.scrollItems.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _pageOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = width * 0.55;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: ValueListenableBuilder<double>(
            valueListenable: _pageOffset,
            builder: (context, offset, _) {
              return PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.scrollItems.length,
                itemBuilder: (context, index) {
                  final item = widget.scrollItems[index];
                  final double difference = (offset - index);
                  final double scale = (1 - (difference.abs() * 0.08)).clamp(0.9, 1.0);
                  final double parallax = difference * (width / 6);

                  return Transform.scale(
                    scale: scale,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onItemTap(item);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background image with subtle parallax
                              Transform.translate(
                                offset: Offset(parallax, 0),
                                child: Image.asset(
                                  item['image']!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                              ),

                              // Gradient overlay (lighter for smoother render)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.2),
                                      Colors.black.withOpacity(0.55),
                                    ],
                                  ),
                                ),
                              ),

                              // Text overlay with animation
                              Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? '',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 6,
                                            color: Colors.black.withOpacity(0.4),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      item['subtitle'] ?? '',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  .animate(
                                key: ValueKey('${item['title']}$_currentPage'),
                                target: _currentPage == index ? 1 : 0,
                              )
                                  .fadeIn(duration: 500.ms)
                                  .slideY(begin: 0.2, duration: 500.ms),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // ✅ Smooth page indicator
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Row(
            key: ValueKey(_currentPage),
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.scrollItems.length, (index) {
              final bool active = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
