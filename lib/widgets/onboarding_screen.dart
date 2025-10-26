import 'package:flutter/material.dart';
import '../auth/login_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "Welcome to ChandraPAINT",
      "subtitle": "Your one-stop solution for all painting needs.",
      "image": "assets/onboard1.jpeg"
    },
    {
      "title": "Premium Quality Paints",
      "subtitle": "Get the best quality paints at affordable prices.",
      "image": "assets/onboard2.jpeg"
    },
    {
      "title": "Free Delivery",
      "subtitle": "We deliver paints quickly to your doorstep.",
      "image": "assets/onboard3.jpeg"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _pageIndex = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(_pages[index]['image']!, height: 250),
                      const SizedBox(height: 30),
                      Text(
                        _pages[index]['title']!,
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _pages[index]['subtitle']!,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
                  (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.all(5),
                height: 8,
                width: _pageIndex == index ? 20 : 8,
                decoration: BoxDecoration(
                  color: _pageIndex == index ? Colors.pink : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_pageIndex == _pages.length - 1)
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const LoginPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding:
                const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Get Started",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
