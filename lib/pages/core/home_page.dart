  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:firebase_database/firebase_database.dart';
  import 'package:flutter/material.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:iconsax/iconsax.dart';
  import 'dart:async';

  // ⭐ IMPORTS CLEANED UP (Assuming 'c_h_p' is your project name)
  import 'package:c_h_p/model/product_model.dart';
  import 'package:c_h_p/auth/login_page.dart';
  import 'package:c_h_p/widgets/home_drawer.dart';
  import 'package:c_h_p/widgets/featured_carousel.dart';
  import 'package:c_h_p/widgets/home_sections.dart';
  import 'package:c_h_p/product/search_results_page.dart';
  import 'package:c_h_p/product/explore_product.dart';
  import 'package:c_h_p/product/product_detail_page.dart';
  import 'package:c_h_p/pages/core/cart_page.dart';
  import 'package:c_h_p/pages/core/report_issue_page.dart';
  import 'package:c_h_p/pages/latest_colors_page.dart';
  import 'package:c_h_p/pages/core/notifications_page.dart';

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

    List<Product> _allProducts = [];
    List<Product> _suggestions = [];

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

    void _handleCarouselTap(Map<String, String> item) {
      final title = item['title'];
      if (title == 'Latest Colors') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LatestColorsPage()));
      } else {
        // For "Top Picks" and "Seasonal Offers", navigate to the main explore page
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreProductPage()));
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
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search for paints...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                ),
                onSubmitted: (query) {
                  if (query.trim().isNotEmpty) {
                    _hideOverlay();
                    _searchFocusNode.unfocus();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SearchResultsPage(searchQuery: query.trim())));
                  }
                },
              ),
            ),
            actions: [
              StreamBuilder(
                stream: currentUser != null ? FirebaseDatabase.instance.ref('users/${currentUser.uid}/notifications').onValue : null,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                    final notifications = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                    notifications.forEach((key, value) {
                      if (value['isRead'] == false) {
                        unreadCount++;
                      }
                    });
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (currentUser != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                          } else {
                            _showLoginPrompt();
                          }
                        },
                        icon: const Icon(Iconsax.notification),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          drawer: HomeDrawer(
            currentUser: currentUser,
            userRole: _userRole,
            onLogout: _logout,
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  FeaturedCarousel(
                    scrollItems: scrollItems,
                    onItemTap: _handleCarouselTap,
                  ),
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
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreProductPage())),
            backgroundColor: Colors.deepOrange,
            shape: const CircleBorder(),
            child: const Icon(Iconsax.discover_1, color: Colors.white),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            elevation: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildBottomNavItem(
                  icon: Iconsax.message_question,
                  label: 'Report',
                  onPressed: () {
                    if (currentUser == null) {
                      _showLoginPrompt();
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssuePage()));
                    }
                  },
                ),
                _buildBottomNavItem(
                  icon: Iconsax.shopping_cart,
                  label: 'Cart',
                  onPressed: () {
                    if (currentUser == null) {
                      _showLoginPrompt();
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    Future<void> _fetchAllProductsForSearch() async {
      try {
        final snapshot = await FirebaseDatabase.instance.ref('products').get();
        if (snapshot.exists && snapshot.value is Map) {
          final productsMap = Map<String, dynamic>.from(snapshot.value as Map);
          if (mounted) {
            setState(() {
              _allProducts = productsMap.entries.map((entry) {
                return Product.fromMap(entry.key, Map<String, dynamic>.from(entry.value));
              }).toList();
            });
          }
        }
      } catch (e) {
        print("Error fetching all products for search: $e");
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
        if (mounted) setState(() => _suggestions = []);
        _overlayEntry?.markNeedsBuild();
        _hideOverlay();
        return;
      }
      if (!_searchFocusNode.hasFocus) _searchFocusNode.requestFocus();
      if (mounted) setState(() => _isSearchLoading = true);
      _showOverlay();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        final filtered = _allProducts.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
        if (mounted) {
          setState(() {
            _suggestions = filtered;
            _isSearchLoading = false;
          });
        }
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
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: _isSearchLoading
                    ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.deepOrange)))
                    : _suggestions.isEmpty
                    ? ListTile(title: Text('No results for "${_searchController.text}"'))
                    : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final product = _suggestions[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported),
                        ),
                      ),
                      title: Text(product.name),
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
            backgroundColor: Colors.black87,
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
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel", style: GoogleFonts.poppins())),
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

    void _showLoginPrompt() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Login Required", style: GoogleFonts.poppins()),
          content: Text("You need to be logged in to use this feature.", style: GoogleFonts.poppins()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              child: Text("Login", style: GoogleFonts.poppins(color: Colors.white)),
            )
          ],
        ),
      );
    }

    Widget _buildBottomNavItem({required IconData icon, required String label, required VoidCallback onPressed}) {
      return IconButton(
        tooltip: label,
        icon: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey.shade700),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade700)),
          ],
        ),
        onPressed: onPressed,
      );
    }
  }