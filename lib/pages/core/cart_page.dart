import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer

import '../../model/product_model.dart'; // Import your Product model
import 'payment_page.dart';
import '/../product/explore_product.dart'; // For browsing

// Helper class to hold combined Cart Item and Product details
class CartItemDetails {
  final String productKey;
  final Map<String, dynamic> cartData; // Data from /users/$uid/cart/$productKey
  final Product? productDetails; // Full details from /products/$productKey

  CartItemDetails({
    required this.productKey,
    required this.cartData,
    this.productDetails,
  });

  // Getters for easier access, with fallbacks
  String get name => cartData['name'] ?? productDetails?.name ?? 'Unknown Product';
  String get imageUrl => cartData['mainImageUrl'] ?? productDetails?.mainImageUrl ?? '';
  int get quantity => cartData['quantity'] ?? 0;
  String get selectedSize => cartData['selectedSize'] ?? '';
  String get selectedPrice => cartData['selectedPrice'] ?? '0';
  List<PackSize> get availableSizes => productDetails?.packSizes ?? [];
}


class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // --- Cart Modification Functions ---

  void _updateQuantity(String productKey, int newQuantity) {
    final user = _auth.currentUser;
    if (user == null) return;
    final itemRef = _dbRef.child('users/${user.uid}/cart/$productKey');

    if (newQuantity > 0) {
      itemRef.update({'quantity': newQuantity});
    } else {
      itemRef.remove();
    }
  }

  void _updateSelectedSize(String productKey, PackSize newPackSize) {
    final user = _auth.currentUser;
    if (user == null) return;
    final itemRef = _dbRef.child('users/${user.uid}/cart/$productKey');

    itemRef.update({
      'selectedSize': newPackSize.size,
      'selectedPrice': newPackSize.price,
      'quantity': 1 // Reset quantity to 1 when size changes (common UX pattern)
    });
    // Optional: Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Size updated to ${newPackSize.size}"), duration: Duration(seconds: 1)),
    );
  }

  void _clearCart() {
    final user = _auth.currentUser;
    if (user == null) return;
    final cartRef = _dbRef.child('users/${user.uid}/cart');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Clear Cart", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Remove all items from your cart?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.of(ctx).pop()),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text("Clear All"),
            onPressed: () { cartRef.remove(); Navigator.of(ctx).pop(); },
          ),
        ],
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("My Cart", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.trash),
            onPressed: _clearCart,
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      body: currentUser == null
          ? _buildLoggedOutState()
          : StreamBuilder<DatabaseEvent>(
        stream: _dbRef.child('users/${currentUser.uid}/cart').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            // Show initial loading shimmer ONLY if there's no cached data yet
            return _buildCartLoadingShimmer(3); // Show 3 shimmer items initially
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading cart: ${snapshot.error}"));
          }

          final cartData = snapshot.data?.snapshot.value;
          final bool isCartEmpty = cartData == null || (cartData as Map).isEmpty;

          if (isCartEmpty) {
            return _buildEmptyCart();
          }

          final cartMap = Map<String, dynamic>.from(cartData as Map);
          final productKeys = cartMap.keys.toList();

          // Fetch product details based on keys in the cart
          return FutureBuilder<Map<String, Product?>>(
            future: _fetchAllProductDetails(productKeys),
            builder: (context, productDetailsSnapshot) {
              // Show shimmer while fetching details, *even if stream has data*
              if (productDetailsSnapshot.connectionState == ConnectionState.waiting) {
                return _buildCartLoadingShimmer(cartMap.length);
              }
              if (productDetailsSnapshot.hasError) {
                return Center(child: Text("Error loading product details: ${productDetailsSnapshot.error}"));
              }

              // Combine cart data with product details
              final productDetailsMap = productDetailsSnapshot.data ?? {};
              final cartItemsWithDetails = cartMap.entries.map((entry) {
                return CartItemDetails(
                  productKey: entry.key,
                  cartData: Map<String, dynamic>.from(entry.value),
                  productDetails: productDetailsMap[entry.key],
                );
              }).where((item) => item.productDetails != null).toList(); // Filter out items where details failed

              // Handle case where all product details failed to load
              if (cartItemsWithDetails.isEmpty && !isCartEmpty) {
                return Center(child: Text("Error loading details for cart items."));
              }


              return _buildCartContent(cartItemsWithDetails);
            },
          );
        },
      ),
    );
  }

  // --- Helper to Fetch Product Details ---
  Future<Map<String, Product?>> _fetchAllProductDetails(List<String> productKeys) async {
    Map<String, Product?> detailsMap = {};
    for (String key in productKeys) {
      try {
        final snapshot = await _dbRef.child('products/$key').get();
        if (snapshot.exists && snapshot.value != null) {
          detailsMap[key] = Product.fromMap(key, Map<String, dynamic>.from(snapshot.value as Map));
        } else {
          detailsMap[key] = null; // Mark as null if product deleted from main list
        }
      } catch (e) {
        debugPrint("Error fetching details for $key: $e");
        detailsMap[key] = null;
      }
    }
    return detailsMap;
  }


  // --- UI Building Widgets ---

  Widget _buildLoggedOutState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.login, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text("Please log in to view your cart.", style: GoogleFonts.poppins(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.shopping_cart, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("Your Cart is Empty", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text("Looks like you haven't added anything yet.", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Iconsax.shop, size: 20),
            label: Text("Browse Products", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreProductPage())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildCartContent(List<CartItemDetails> items) {
    double subtotal = 0;
    for (var item in items) {
      final price = double.tryParse(item.selectedPrice) ?? 0.0;
      subtotal += price * item.quantity;
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            itemCount: items.length,
            itemBuilder: (context, index) { // <<< The builder function starts here
              final item = items[index];
              // We already filtered out null productDetails before calling this function
              return _buildCartItem(item)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (100 * index).ms)
                  .moveY(begin: 20, curve: Curves.easeOutCubic);

              // *** NO return statement needed after the explicit return above ***
            }, // <<< The builder function ends here
          ),
        ),
        _buildOrderSummary(subtotal),
      ],
    );
  }


  Widget _buildCartItem(CartItemDetails item) {
    // Find the actual PackSize object matching the selected size string
    PackSize? currentSelectedPackSizeObject;
    if (item.productDetails != null) {
      try {
        currentSelectedPackSizeObject = item.availableSizes.firstWhere(
              (ps) => ps.size == item.selectedSize,
        );
      } catch (e) {
        // Handle case where selectedSize from cart doesn't match any available size
        currentSelectedPackSizeObject = item.availableSizes.isNotEmpty ? item.availableSizes.first : null;
        // Optionally: Update the cart item in Firebase to the first available size here if needed
      }
    }
    // Use fallback if details aren't loaded or size mismatch
    final currentSelectedPackSize = currentSelectedPackSizeObject ?? PackSize(size: item.selectedSize, price: item.selectedPrice);


    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key(item.productKey),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          _updateQuantity(item.productKey, 0); // Remove on dismiss
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${item.name} removed")));
        },
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(16)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [ Icon(Iconsax.trash, color: Colors.white), SizedBox(width: 8), Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl, // Use getter which has fallback
                  width: 80, height: 80, fit: BoxFit.cover,
                  placeholder: (c, u) => Container(width: 80, height: 80, color: Colors.grey.shade200),
                  errorWidget: (c, u, e) => Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Iconsax.gallery_slash)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis,),
                    const SizedBox(height: 8),
                    // --- Pack Size Dropdown ---
                    // Show dropdown only if product details are loaded and multiple valid sizes exist
                    if (item.productDetails != null && item.availableSizes.where((p) => p.price != '0' && p.price.isNotEmpty).length > 1)
                      DropdownButtonHideUnderline(
                        child: DropdownButton<PackSize>(
                          value: currentSelectedPackSize, // Use the found PackSize object
                          isDense: true,
                          items: item.availableSizes
                              .where((pack) => pack.price != '0' && pack.price.isNotEmpty) // Filter out invalid sizes
                              .map((PackSize packSize) {
                            return DropdownMenuItem<PackSize>(
                              value: packSize,
                              child: Text(
                                '${packSize.size} - ₹${packSize.price}',
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (PackSize? newValue) {
                            if (newValue != null && newValue.size != item.selectedSize) {
                              _updateSelectedSize(item.productKey, newValue);
                            }
                          },
                        ),
                      )
                    else // If only one size or details missing, just display current selection
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0), // Add padding for alignment
                        child: Text(
                            '${item.selectedSize} - ₹${item.selectedPrice}',
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700)
                        ),
                      ),
                    const SizedBox(height: 10),
                    // --- Quantity Controls ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Qty:', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700)),
                        Container(
                          height: 35,
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Iconsax.minus, size: 16),
                                onPressed: item.quantity > 1 ? () => _updateQuantity(item.productKey, item.quantity - 1) : null, // Disable minus at 1
                                padding: const EdgeInsets.symmetric(horizontal: 4), // Adjust padding
                                constraints: const BoxConstraints(),
                                splashRadius: 18,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(item.quantity.toString(), style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Iconsax.add, size: 16, color: Colors.deepOrange),
                                onPressed: () => _updateQuantity(item.productKey, item.quantity + 1),
                                padding: const EdgeInsets.symmetric(horizontal: 4), // Adjust padding
                                constraints: const BoxConstraints(),
                                splashRadius: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -10))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600)),
              Text('₹${subtotal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('₹${subtotal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: subtotal > 0
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(totalAmount: subtotal)))
                  : null, // Disable button if cart is empty/total is zero
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: Text('Proceed to Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  // Shimmer loading placeholder for the cart items
  Widget _buildCartLoadingShimmer(int itemCount) {
    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: itemCount > 0 ? itemCount : 3, // Show predicted count or default
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container( // Shimmer container matching card layout
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 20, width: double.infinity, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 15, width: 100, color: Colors.white),
                          const SizedBox(height: 10),
                          Container(height: 35, width: 120, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

}