import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FreeDeliveryInfoPage extends StatefulWidget {
  const FreeDeliveryInfoPage({super.key});

  @override
  State<FreeDeliveryInfoPage> createState() => _FreeDeliveryInfoPageState();
}

class _FreeDeliveryInfoPageState extends State<FreeDeliveryInfoPage> {
  // ⭐ OPTIMIZATION: Make slide data static and constant, as it never changes.
  static const List<Map<String, String>> _slides = [
    {
      "image": "assets/delivery1.png",
      "title": "Our Coverage Area",
      "description": "We offer free delivery for all orders within a 50km radius of our main store in Mallappally, Kerala. Check our service map to see if your location is included."
    },
    {
      "image": "assets/delivery2.png",
      "title": "Fast & Reliable Service",
      "description": "Once your order is confirmed, our dedicated team ensures that your products are dispatched and delivered to your doorstep within 48 business hours."
    },
    {
      "image": "assets/delivery3.png",
      "title": "Safe & Secure Handling",
      "description": "All our paint products are handled with extreme care. We use specialized packaging to prevent leaks and damage during transit, ensuring they arrive in perfect condition."
    },
  ];

  // ⭐ OPTIMIZATION: Use a ValueNotifier to update only the dots, not the whole page.
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  bool _areImagesPrecached = false;

  // ⭐ OPTIMIZATION: Pre-cache images for smooth scrolling.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_areImagesPrecached) {
      for (final slide in _slides) {
        precacheImage(AssetImage(slide['image']!), context);
      }
      _areImagesPrecached = true;
    }
  }

  @override
  void dispose() {
    _currentPageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            onPageChanged: (int page) {
              _currentPageNotifier.value = page;
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _InfoSlide(
                imagePath: _slides[index]['image']!,
                title: _slides[index]['title']!,
                description: _slides[index]['description']!,
              );
            },
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            // ⭐ OPTIMIZATION: Use a ValueListenableBuilder to only rebuild the dots.
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, currentPage, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: currentPage == index ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ⭐ OPTIMIZATION: Extracted the slide into its own efficient StatelessWidget.
class _InfoSlide extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const _InfoSlide({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, shadows: [const Shadow(blurRadius: 4, color: Colors.black54)]),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 16, height: 1.5),
            ),
            const Spacer(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}