import 'dart:async';
import 'package:c_h_p/auth/login_page.dart';
import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/pages/color_catalogue_page.dart';
import 'package:c_h_p/pages/core/cart_page.dart';
import 'package:c_h_p/pages/core/notifications_page.dart';
import 'package:c_h_p/pages/core/report_issue_page.dart';
import 'package:c_h_p/product/explore_product.dart';
import 'package:c_h_p/product/latest_colors_page.dart';
import 'package:c_h_p/product/product_detail_page.dart';
import 'package:c_h_p/product/search_results_page.dart';
import 'package:c_h_p/widgets/featured_carousel.dart';
import 'package:c_h_p/widgets/home_drawer.dart';
import 'package:c_h_p/widgets/home_sections.dart';
import 'package:c_h_p/pages/paint_calculator_page.dart';
import 'package:c_h_p/pages/view_painters_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:c_h_p/services/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
// Removed custom spinning explore icon; using a generic icon instead

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> scrollItems = [
    {
      "title": "Painting Services",
      "image": "assets/painter.jpg",
      "subtitle": "Hire pros or explore services"
    },
    {
      "title": "Latest Colors",
      "image": "assets/color3.jpeg",
      "subtitle": "Trending shades for modern spaces"
    },
    {
      "title": "Paint Calculator",
      "image": "assets/calc.webp",
      "subtitle": "Estimate paint quantity easily"
    },
  ];

  DateTime? _lastBackPressTime;
  String _userRole = 'Customer';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  List<Product> _allProducts = [];
  List<Product> _suggestions = [];
  Timer? _debounce;
  bool _isSearchLoading = false;
  int _selectedIndex = 1;
  bool _productsLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _searchFocusNode.addListener(_handleSearchFocus);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (var item in scrollItems) {
      if (item['image'] != null) {
        precacheImage(AssetImage(item['image']!), context);
      }
    }
    precacheImage(const AssetImage("assets/image_b8a96a.jpg"), context);
    precacheImage(const AssetImage("assets/image_b8aca7.jpg"), context);
    precacheImage(const AssetImage("assets/image_b8b0ca.jpg"), context);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_handleSearchFocus);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    _hideOverlay();
    super.dispose();
  }

  Future<void> _fetchAllProductsForSearch() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('products').get();
      if (snapshot.exists && snapshot.value is Map) {
        final productsMap = Map<String, dynamic>.from(snapshot.value as Map);
        if (mounted) {
          setState(() {
            _allProducts = productsMap.entries.map((entry) {
              return Product.fromMap(
                  entry.key, Map<String, dynamic>.from(entry.value));
            }).toList();
            _productsLoaded = true;
            if (_searchController.text.trim().isNotEmpty) {
              final query = _searchController.text.toLowerCase();
              _suggestions = _allProducts
                  .where((p) => p.name.toLowerCase().contains(query))
                  .toList();
              _isSearchLoading = false;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching all products for search: $e");
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
          final fetchedRole = data['userType'] ?? 'Customer';
          setState(() => _userRole = fetchedRole);
        }
      } catch (e) {
        debugPrint("Error fetching user role: $e");
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Text("Logout",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to log out?",
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text("Logout", style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      // Unsubscribe from user topic before sign out
      await FCMService.unsubscribeForUser(FirebaseAuth.instance.currentUser);
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  void _handleCarouselTap(Map<String, String> item) {
    final title = item['title'];
    Widget page;
    if (title == 'Painting Services') {
      page = const ViewPaintersPage();
    } else if (title == 'Top Picks') {
      page = const ViewPaintersPage();
    } else if (title == 'Seasonal Offers') {
      // Proxy: route to Color Catalogue as Color Visualization page placeholder
      page = const ColorCataloguePage();
    } else if (title == 'Latest Colors') {
      page = const LatestColorsPage();
    } else if (title == 'Paint Calculator') {
      page = const PaintCalculatorPage();
    } else {
      page = const ExploreProductPage();
    }
    _navigateToWithFade(page);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final allow = await _onWillPop();
        if (allow && mounted) {
          nav.maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(currentUser),
        drawer: HomeDrawer(
            currentUser: currentUser, userRole: _userRole, onLogout: _logout),
        // No FAB here; Trend management moved to Manager Dashboard
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              RepaintBoundary(
                child: FeaturedCarousel(
                  scrollItems: scrollItems,
                  onItemTap: _handleCarouselTap,
                ),
              ),
              // Removed PopularTrendsSection to reduce homepage jank
              const SizedBox(height: 12),
              const RepaintBoundary(child: SectionTitle("Get in Touch")),
              const RepaintBoundary(child: GetInTouchSection()),
              const SizedBox(height: 120),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(currentUser),
      ),
    );
  }

  AppBar _buildAppBar(User? currentUser) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.grey.shade200,
      iconTheme: IconThemeData(color: Colors.grey.shade800),
      title: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search for paints...',
            hintStyle:
                GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
            prefixIcon: const Icon(Iconsax.search_normal_1,
                color: Colors.grey, size: 20),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              _hideOverlay();
              _searchFocusNode.unfocus();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          SearchResultsPage(searchQuery: query.trim())));
            }
          },
        ),
      ),
      actions: [
        StreamBuilder<DatabaseEvent>(
          stream: currentUser != null
              ? FirebaseDatabase.instance
                  .ref('users/${currentUser.uid}/notifications')
                  .limitToLast(50) // Limit to reduce data load
                  .onValue
              : null,
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
              try {
                final notifications = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map);
                notifications.forEach((key, value) {
                  if (value['isRead'] == false) unreadCount++;
                });
              } catch (e) {
                // Handle error silently
              }
            }
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  onPressed: () => _navigateToWithFade(
                      const NotificationsPage(),
                      checkAuth: true),
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
                          borderRadius: BorderRadius.circular(10)),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$unreadCount',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(User? currentUser) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 15,
              offset: const Offset(0, -5))
        ],
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              _navigateToWithFade(const ReportIssuePage(), checkAuth: true);
              break;
            case 1:
              _navigateToWithFade(const ExploreProductPage());
              break;
            case 2:
              _navigateToWithFade(const CartPage(), checkAuth: true);
              break;
          }
        },
        indicatorColor: Colors.deepOrange.shade100,
        backgroundColor: Colors.transparent,
        elevation: 0,
        destinations: const [
          NavigationDestination(
              icon: Icon(Iconsax.message_question), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(
              icon: Icon(Iconsax.shopping_cart), label: 'Cart'),
        ],
      ),
    );
  }

  void _navigateToWithFade(Widget page, {bool checkAuth = false}) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (checkAuth && currentUser == null) {
      _showLoginPrompt();
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _handleSearchFocus() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (_searchController.text.trim().isEmpty) {
      if (mounted) setState(() => _suggestions = []);
      _hideOverlay();
      return;
    }
    if (!_searchFocusNode.hasFocus) _searchFocusNode.requestFocus();
    if (mounted) setState(() => _isSearchLoading = true);
    // Lazy-load products on first search
    if (!_productsLoaded) {
      _fetchAllProductsForSearch();
    }
    _showOverlay();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_productsLoaded) {
        final filtered = _allProducts
            .where((p) => p.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
        if (mounted) {
          setState(() {
            _suggestions = filtered;
            _isSearchLoading = false;
          });
        }
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
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: _isSearchLoading
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.deepOrange)))
                  : _suggestions.isEmpty
                      ? ListTile(
                          title: Text(
                              'No results for "${_searchController.text}"'))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _suggestions.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final product = _suggestions[index];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: RepaintBoundary(
                                  child: CachedNetworkImage(
                                    // ⭐ FIX: Changed 'imageUrl' to 'mainImageUrl'
                                    imageUrl: product.mainImageUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 120,
                                    errorWidget: (c, e, s) =>
                                        const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                              title: Text(product.name),
                              onTap: () {
                                _hideOverlay();
                                _searchFocusNode.unfocus();
                                _navigateToWithFade(
                                    ProductDetailPage(product: product));
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
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Press back again to exit',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.black87,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return false;
    }
    return true;
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Text("Login Required", style: GoogleFonts.poppins()),
        content: Text("You need to be logged in to use this feature.",
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginPage()));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child:
                Text("Login", style: GoogleFonts.poppins(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
