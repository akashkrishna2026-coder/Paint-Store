import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final List<Map<String, String>> collections = [
    {"title": "Premium Collection", "image": "assets/premium.png"},
    {"title": "Budget Friendly", "image": "assets/budget.png"},
    {"title": "Eco Friendly", "image": "assets/eco.png"},
  ];

  final List<Map<String, String>> trendingColors = [
    {"name": "Sunset Orange", "color": "#FF7043"},
    {"name": "Ocean Blue", "color": "#42A5F5"},
    {"name": "Mint Green", "color": "#66BB6A"},
  ];

  final List<Map<String, String>> reviews = [
    {"name": "Rahul", "review": "Amazing quality and great service! Will buy again."},
    {"name": "Priya", "review": "Beautiful colors and quick delivery!"},
    {"name": "Aman", "review": "Great customer support and affordable pricing."},
  ];

  final List<String> services = [
    "Free Room Scanning",
    "Custom Color Consultation",
    "Bulk Order Discounts",
    "Fast Home Delivery"
  ];

  int _currentReviewIndex = 0;
  Timer? _reviewTimer;
  DateTime? _lastBackPressTime;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _startReviewCarousel();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _reviewTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _startReviewCarousel() {
    _reviewTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentReviewIndex = (_currentReviewIndex + 1) % reviews.length;
      });
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Press back again to exit',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.deepOrange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to log out?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Logout", style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.orange.shade50,
        appBar: AppBar(
          title: Text("Chandra Paints", style: GoogleFonts.pacifico(fontSize: 26, color: Colors.white)),
          backgroundColor: Colors.deepOrange,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Promotional Offers"),
                _buildPromoBanner(),
                const SizedBox(height: 16),

                _buildSectionTitle("Our Collections"),
                _buildHorizontalList(collections),
                const SizedBox(height: 16),

                _buildSectionTitle("Trending Colors"),
                _buildTrendingColors(),
                const SizedBox(height: 16),

                _buildSectionTitle("Our Services"),
                _buildServices(),
                const SizedBox(height: 16),

                _buildSectionTitle("Customer Reviews"),
                _buildReviewCarousel(),
                const SizedBox(height: 16),

                _buildSectionTitle("Contact Us"),
                _buildContactSection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.green,
          onPressed: () {
            launchUrl(Uri.parse("https://wa.me/919961339076"));
          },
          label: const Text("Need Help"),
          icon: const Icon(Icons.message),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Hero(
          tag: "promo",
          child: Image.asset("assets/promo.png", fit: BoxFit.cover, height: 180, width: double.infinity),
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<Map<String, String>> items) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CollectionDetailsPage(data: items[index])));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.orange.shade100, blurRadius: 5, offset: const Offset(2, 2)),
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Hero(
                      tag: items[index]["image"]!,
                      child: Image.asset(items[index]["image"]!, height: 100, width: 140, fit: BoxFit.cover),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(items[index]["title"]!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  )
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildTrendingColors() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        children: trendingColors.map((colorData) {
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ColorPreviewPage(
                  colorName: colorData["name"]!,
                  colorValue: Color(int.parse(colorData["color"]!.replaceAll("#", "0xFF"))),
                ),
              ));
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Color(int.parse(colorData["color"]!.replaceAll("#", "0xFF"))),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade400, blurRadius: 5, offset: const Offset(2, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(colorData["name"]!, style: GoogleFonts.poppins(fontSize: 12)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServices() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: services.map((service) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.deepOrange),
              title: Text(service, style: GoogleFonts.poppins()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.deepOrange),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewCarousel() {
    final review = reviews[_currentReviewIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Card(
          key: ValueKey(review["name"]),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("\"${review["review"]}\"", style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                Text("- ${review["name"]}"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📍 Location: Kochi, Kerala"),
          Text("📞 Phone: +91 98765 43210"),
          Text("✉ Email: chandrapaints@example.com"),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.facebook, color: Colors.blue),
                onPressed: () => launchUrl(Uri.parse("https://facebook.com")),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.purple),
                onPressed: () => launchUrl(Uri.parse("https://instagram.com")),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class CollectionDetailsPage extends StatelessWidget {
  final Map<String, String> data;
  const CollectionDetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(data["title"]!)),
      body: Center(
        child: Hero(
          tag: data["image"]!,
          child: Image.asset(data["image"]!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class ColorPreviewPage extends StatelessWidget {
  final String colorName;
  final Color colorValue;
  const ColorPreviewPage({super.key, required this.colorName, required this.colorValue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorValue,
      appBar: AppBar(title: Text(colorName)),
      body: Center(
        child: Text(colorName, style: GoogleFonts.poppins(fontSize: 28, color: Colors.white)),
      ),
    );
  }
}
