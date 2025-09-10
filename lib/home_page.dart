import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'login_page.dart';
import 'dashboard_page.dart';
import 'personal_info_page.dart';
import 'explore_product.dart';


// ================= Dummy Page =================
class DummyPage extends StatelessWidget {
  final String title;
  const DummyPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Text(
          "Welcome to $title",
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

// ================= Home Page =================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final List<Map<String, String>> collections = [
    {
      "title": "Premium Collection",
      "image": "assets/premium.png",
      "subtitle": "Luxury finishes for discerning clients"
    },
    {
      "title": "Budget Friendly",
      "image": "assets/budget.png",
      "subtitle": "Quality paints at affordable prices"
    },
    {
      "title": "Eco Friendly",
      "image": "assets/eco.png",
      "subtitle": "Sustainable options for eco-conscious homes"
    },
  ];

  final List<Map<String, String>> scrollItems = [
    {
      "title": "Latest Colors",
      "image": "assets/color1.jpeg",
      "subtitle": "Trending shades for modern spaces"
    },
    {
      "title": "Top Picks",
      "image": "assets/color2.jpeg",
      "subtitle": "Our customers' favorites this season"
    },
    {
      "title": "Seasonal Offers",
      "image": "assets/color3.jpeg",
      "subtitle": "Special discounts for limited time"
    },
  ];

  final List<Map<String, dynamic>> testimonials = [
    {
      "name": "Rajesh Kumar",
      "comment": "Excellent quality paints that lasted through monsoon season!",
      "rating": 5
    },
    {
      "name": "Priya Nair",
      "comment": "Professional service and great color consultation.",
      "rating": 4
    },
    {
      "name": "Vikram Singh",
      "comment": "The eco-friendly option exceeded my expectations.",
      "rating": 5
    },
  ];

  DateTime? _lastBackPressTime;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _autoScrollTimer; // nullable to avoid late initialization issues

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Auto-scroll the PageView every 4 seconds
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && mounted) {
        _currentPage = (_currentPage + 1) % scrollItems.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _autoScrollTimer?.cancel(); // safe cancel
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text('Press back again to exit', style: GoogleFonts.poppins(color: Colors.white)),
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
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }

  bool isAdmin(String? email) {
    return email?.toLowerCase() == 'akashkrishna389@gmail.com';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.orange.shade50,
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 40,
                width: 40,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.brush, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 10),
              Text(
                "Chandra Paints",
                style: GoogleFonts.pacifico(fontSize: 26, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.deepOrange,
          elevation: 4,
          shadowColor: Colors.deepOrange.withOpacity(0.6),
        ),
        drawer: _buildDrawer(currentUser),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(),
                _buildSectionTitle("Featured Collections"),
                _buildScrollableItems(screenWidth), // <-- method present below
                const SizedBox(height: 24),
                _buildSectionTitle("Our Product Categories"),
                _buildHorizontalList(collections, screenWidth),
                const SizedBox(height: 24),
                _buildSectionTitle("Why Choose Us"),
                _buildFeaturesSection(),
                const SizedBox(height: 24),
                _buildSectionTitle("Customer Testimonials"),
                _buildTestimonialsSection(),
                const SizedBox(height: 24),
                _buildSectionTitle("Contact Us"),
                _buildContactSection(),
                const SizedBox(height: 30),
                _buildFooter(),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.green,
          onPressed: () => launchUrl(Uri.parse("https://wa.me/919961339076")),
          label: const Text("Chat with Us"),
          icon: const Icon(Icons.message),
        ),
      ),
    );
  }

  // ================= Drawer =================
  Widget _buildDrawer(User? currentUser) => Drawer(
    child: Column(
      children: [
        Container(
          color: Colors.deepOrange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: currentUser?.photoURL != null
                    ? NetworkImage(currentUser!.photoURL!)
                    : null,
                child: currentUser?.photoURL == null
                    ? const Icon(Icons.person, color: Colors.deepOrange, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser != null
                          ? (currentUser.displayName ?? currentUser.email ?? "User")
                          : "Welcome Guest",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (currentUser == null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          elevation: 3,
                        ),
                        icon: const Icon(Icons.login, size: 18),
                        label: Text("Login / Signup", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                      ),
                    if (currentUser != null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentUser.email ?? "",
                              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoPage()));
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            if (currentUser != null)
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.deepOrange),
                title: Text("Dashboard", style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardPage(role: isAdmin(currentUser?.email) ? "admin" : "customer"),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.color_lens, color: Colors.deepOrange),
              title: Text("Color Visualizer", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DummyPage(title: "Color Visualizer")));
              },
            ),
            ListTile(
              leading: const Icon(Icons.calculate, color: Colors.deepOrange),
              title: Text("Paint Calculator", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DummyPage(title: "Paint Calculator")));
              },
            ),
            ListTile(
              leading: const Icon(Icons.article, color: Colors.deepOrange),
              title: Text("Blog & Tips", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DummyPage(title: "Blog & Tips")));
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.deepOrange),
              title: Text("Report Issue", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report Issue Clicked")));
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.deepOrange),
              title: Text("FAQs", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DummyPage(title: "FAQs")));
              },
            ),
          ]),
        ),
        if (FirebaseAuth.instance.currentUser != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                elevation: 3,
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: Text("Logout", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onPressed: _logout,
            ),
          ),
      ],
    ),
  );

  // ================= Sections =================
  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
    child: Text(
      title,
      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
    ),
  );

  // Hero Section with brand message
  Widget _buildHeroSection() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.deepOrange.withOpacity(0.8), Colors.orange.shade100],
      ),
    ),
    child: Column(
      children: [
        Text(
          "Transforming Spaces with Color",
          style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "Premium quality paints for your home and business",
          style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExploreProductPage()),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.deepOrange,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 5,
          ),
          child: Text(
              "Explore Products",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16
              )
          ),
        ),
      ],
    ),
  );

  // ------------------ THE MISSING METHOD (and corrected) ------------------
  Widget _buildScrollableItems(double screenWidth) {
    final screenHeight = MediaQuery.of(context).size.height;
    final itemHeight = screenHeight * 0.35;

    return Column(
      children: [
        SizedBox(
          height: itemHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: scrollItems.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final item = scrollItems[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.hasClients && _pageController.position.haveDimensions) {
                    final page = _pageController.page ?? _pageController.initialPage.toDouble();
                    value = page - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.8, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * itemHeight,
                      width: screenWidth * 0.9,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DummyPage(title: item["title"]!))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Image.asset(
                          item["image"]!,
                          height: itemHeight,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: itemHeight,
                            width: double.infinity,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ]),
                          ),
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item["title"]!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                              if (item["subtitle"] != null) Text(item["subtitle"]!, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(scrollItems.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 12 : 8,
              height: _currentPage == index ? 12 : 8,
              decoration: BoxDecoration(color: _currentPage == index ? Colors.deepOrange : Colors.grey, shape: BoxShape.circle),
            );
          }),
        ),
      ],
    );
  }

  // Horizontal list of collections
  Widget _buildHorizontalList(List<Map<String, String>> items, double screenWidth) => SizedBox(
    height: 200,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        double cardWidth = screenWidth * 0.45;
        final image = items[index]["image"]!;
        final heroTag = 'collection-$image-$index'; // unique tag
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: cardWidth,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.white, boxShadow: [
            BoxShadow(color: Colors.orange.shade100, blurRadius: 8, offset: const Offset(2, 4)),
          ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Hero(
                  tag: heroTag,
                  child: Image.asset(
                    image,
                    height: 120,
                    width: cardWidth,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      width: cardWidth,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(items[index]["title"]!, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                  if (items[index]["subtitle"] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(items[index]["subtitle"]!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
                    ),
                ]),
              ),
            ],
          ),
        );
      },
    ),
  );

  // Features/Why Choose Us section
  Widget _buildFeaturesSection() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Wrap(spacing: 16, runSpacing: 16, children: [
      _buildFeatureItem(icon: Icons.verified_user, title: "Quality Assurance", description: "All our paints undergo rigorous quality testing"),
      _buildFeatureItem(icon: Icons.local_shipping, title: "Free Delivery", description: "Free delivery on orders above ₹2000"),
      _buildFeatureItem(icon: Icons.color_lens, title: "Color Consultation", description: "Expert advice to choose perfect colors"),
      _buildFeatureItem(icon: Icons.eco, title: "Eco-Friendly", description: "Low VOC paints for healthier living"),
    ]),
  );

  Widget _buildFeatureItem({required IconData icon, required String title, required String description}) => Container(
    width: (MediaQuery.of(context).size.width - 48) / 2,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
      BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
    ]),
    child: Column(children: [
      Icon(icon, color: Colors.deepOrange, size: 32),
      const SizedBox(height: 8),
      Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
      const SizedBox(height: 4),
      Text(description, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
    ]),
  );

  // Testimonials section
  Widget _buildTestimonialsSection() => SizedBox(
    height: 200,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: testimonials.length,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final testimonial = testimonials[index];
        return Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
          ]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              for (int i = 0; i < 5; i++)
                Icon(i < testimonial["rating"] ? Icons.star : Icons.star_border, color: Colors.amber, size: 16),
              const Spacer(),
              Icon(Icons.format_quote, color: Colors.deepOrange.withOpacity(0.3), size: 32),
            ]),
            const SizedBox(height: 8),
            Text(testimonial["comment"], style: GoogleFonts.poppins(fontStyle: FontStyle.italic, fontSize: 14), maxLines: 4, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text("- ${testimonial["name"]}", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.deepOrange)),
          ]),
        );
      },
    ),
  );

  // Contact Section
  Widget _buildContactSection() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
      BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
    ]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Get in Touch", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.deepOrange)),
      const SizedBox(height: 16),
      _buildContactInfoItem(Icons.location_on, "📍 Location: Kochi, Kerala"),
      _buildContactInfoItem(Icons.phone, "📞 Phone: +91 98765 43210"),
      _buildContactInfoItem(Icons.email, "✉ Email: chandrapaints@example.com"),
      const SizedBox(height: 16),
      Text("Business Hours:", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      Text("Monday - Saturday: 9:00 AM - 6:00 PM", style: GoogleFonts.poppins(fontSize: 12)),
      Text("Sunday: 10:00 AM - 2:00 PM", style: GoogleFonts.poppins(fontSize: 12)),
      const SizedBox(height: 16),
      Text("Follow Us:", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Row(children: [
        IconButton(icon: const Icon(Icons.facebook, color: Colors.blue, size: 28), onPressed: () => launchUrl(Uri.parse("https://facebook.com"))),
        IconButton(icon: const Icon(Icons.camera_alt, color: Colors.purple, size: 28), onPressed: () => launchUrl(Uri.parse("https://instagram.com"))),
        IconButton(icon: const Icon(Icons.play_arrow, color: Colors.red, size: 28), onPressed: () => launchUrl(Uri.parse("https://youtube.com"))),
      ]),
    ]),
  );

  Widget _buildContactInfoItem(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.deepOrange, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: GoogleFonts.poppins())),
    ]),
  );

  // Footer
  Widget _buildFooter() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 20),
    color: Colors.deepOrange.withOpacity(0.9),
    child: Column(children: [
      Text("Chandra Paints", style: GoogleFonts.pacifico(fontSize: 22, color: Colors.white)),
      const SizedBox(height: 8),
      Text("© ${DateTime.now().year} All Rights Reserved", style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
    ]),
  );
}
