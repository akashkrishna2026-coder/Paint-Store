import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:iconsax/iconsax.dart';

import '../auth/login_page.dart';
import '../widgets/home_drawer.dart';
import '../widgets/featured_carousel.dart';
import '../widgets/home_sections.dart';
import 'search_results_page.dart';
import '../product/explore_product.dart';
import '../product/product_detail_page.dart';
import '../product/cart_page.dart'; // Import the Cart Page
import 'report_issue_page.dart'; // Import the Report Issue Page

// DummyPage is still needed for some navigation items in the drawer.
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
  final List<Map<String, String>> scrollItems = [
    {"title": "Latest Colors", "image": "assets/color1.jpeg", "subtitle": "Trending shades for modern spaces"},
    {"title": "Top Picks", "image": "assets/color2.jpeg", "subtitle": "Our customers' favorites this season"},
    {"title": "Seasonal Offers", "image": "assets/color3.jpeg", "subtitle": "Special discounts for limited time"},
  ];

  DateTime? _lastBackPressTime;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  String _userRole = 'Customer';

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _isSearchLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fetchUserRole();
    _fetchAllProductsForSearch();

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });

    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
  }

  Future<void> _fetchAllProductsForSearch() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('products').get();
      if (snapshot.exists) {
        final productsMap = Map<String, dynamic>.from(snapshot.value as Map);
        _allProducts = productsMap.values.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      print("Error fetching all products: $e");
    }
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.email == 'akashkrishna389@gmail.com') {
        if (mounted) setState(() => _userRole = 'Admin');
        return;
      }
      try {
        final ref = FirebaseDatabase.instance.ref('users/${user.uid}');
        final snapshot = await ref.get();
        if (snapshot.exists && mounted) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() => _userRole = data['userType'] ?? 'Customer');
        }
      } catch (e) {
        print("Error fetching user role: $e");
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    _hideOverlay();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      _overlayEntry?.markNeedsBuild();
      _hideOverlay();
      return;
    }

    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }

    setState(() => _isSearchLoading = true);
    _showOverlay();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final filtered = _allProducts.where((product) {
        final productName = (product['name'] as String?)?.toLowerCase() ?? '';
        return productName.contains(query.toLowerCase());
      }).toList();

      setState(() {
        _suggestions = filtered;
        _isSearchLoading = false;
      });
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        top: kToolbarHeight + MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        child: Material(
          elevation: 4.0,
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: _isSearchLoading
                ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.deepOrange)))
                : _suggestions.isEmpty
                ? ListTile(title: Text('No results found for "${_searchController.text}"'))
                : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final product = _suggestions[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      product['imageUrl'] ?? '',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported),
                    ),
                  ),
                  title: Text(product['name'] ?? ''),
                  onTap: () {
                    _hideOverlay();
                    _searchFocusNode.unfocus();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Press back again to exit', style: GoogleFonts.poppins(color: Colors.white)),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Logout", style: GoogleFonts.poppins(color: Colors.red))),
        ],
      ),
    );
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.grey.shade200,
          iconTheme: IconThemeData(color: Colors.grey.shade800),
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search for paints & more...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
              ),
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  _hideOverlay();
                  _searchFocusNode.unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchResultsPage(searchQuery: query.trim()),
                    ),
                  );
                }
              },
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.notifications_none_outlined, color: Colors.grey.shade800),
            ),
          ],
        ),
        drawer: HomeDrawer(
          currentUser: currentUser,
          userRole: _userRole,
          onLogout: _logout,
        ),
        body: GestureDetector(
          onTap: () {
            _hideOverlay();
            _searchFocusNode.unfocus();
          },
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  FeaturedCarousel(scrollItems: scrollItems),
                  const SizedBox(height: 16),
                  const SectionTitle("Why Choose Us"),
                  const FeaturesSection(),
                  const SizedBox(height: 16),
                  const SectionTitle("Get in Touch"),
                  const ContactSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreProductPage()));
          },
          backgroundColor: Colors.deepOrange,
          shape: const CircleBorder(),
          child: const Icon(Iconsax.discover_1, color: Colors.white),
          elevation: 2.0,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          elevation: 8.0,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildBottomNavRow(isLeft: true, children: [
                _buildBottomNavItem(
                  icon: Iconsax.message_question,
                  label: 'Report',
                  // ⭐ UPDATED NAVIGATION ⭐
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssuePage()));
                  },
                ),
              ]),
              const SizedBox(width: 48),
              _buildBottomNavRow(isLeft: false, children: [
                _buildBottomNavItem(
                  icon: Iconsax.shopping_cart,
                  label: 'Cart',
                  // ⭐ UPDATED NAVIGATION ⭐
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
                  },
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavRow({required bool isLeft, required List<Widget> children}) {
    return Expanded(
      child: Row(
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: children.map((item) => Expanded(child: item)).toList(),
      ),
    );
  }

  Widget _buildBottomNavItem({required IconData icon, required String label, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: Colors.grey.shade700, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

