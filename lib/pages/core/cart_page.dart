// lib/product/cart_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'payment_page.dart';
import '/../product/explore_product.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  void _updateQuantity(String productKey, int newQuantity) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseDatabase.instance.ref('users/${user.uid}/cart');
    if (newQuantity > 0) {
      cartRef.child(productKey).update({'quantity': newQuantity});
    } else {
      // If quantity is 0 or less, remove the item from the cart
      cartRef.child(productKey).remove();
    }
  }

  void _clearCart() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final cartRef = FirebaseDatabase.instance.ref('users/${user.uid}/cart');

    // Show a confirmation dialog before clearing
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Clear Cart", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove all items from your cart?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            child: Text("Cancel", style: GoogleFonts.poppins()),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text("Clear All", style: GoogleFonts.poppins()),
            onPressed: () {
              cartRef.remove(); // This removes the entire 'cart' node
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text("My Cart", style: GoogleFonts.poppins())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.login, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text("Please log in to view your cart.", style: GoogleFonts.poppins(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final DatabaseReference cartRef = FirebaseDatabase.instance.ref('users/${currentUser.uid}/cart');

    return StreamBuilder(
      stream: cartRef.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        // Decide if the cart is empty to show/hide the "Clear All" button
        final bool isCartEmpty = !snapshot.hasData ||
            snapshot.data?.snapshot.value == null ||
            (snapshot.data!.snapshot.value as Map).isEmpty;

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: Text("My Cart", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: IconThemeData(color: Colors.grey.shade800),
            // "Clear All" BUTTON IN APPBAR
            actions: [
              if (!isCartEmpty) // Only show if the cart is NOT empty
                IconButton(
                  icon: const Icon(Iconsax.trash),
                  tooltip: "Clear All",
                  onPressed: _clearCart,
                ),
            ],
          ),
          body: isCartEmpty
              ? _buildEmptyCart()
              : buildCartContent(snapshot), // Build content if cart is not empty
        );
      },
    );
  }

  // Helper method to build the main content when the cart is not empty
  Widget buildCartContent(AsyncSnapshot<DatabaseEvent> snapshot) {
    final cartMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
    final cartItems = cartMap.entries.toList();

    double subtotal = 0;
    for (var item in cartItems) {
      final itemData = Map<String, dynamic>.from(item.value);
      final price = double.tryParse(itemData['price'].toString()) ?? 0.0;
      final quantity = int.tryParse(itemData['quantity'].toString()) ?? 0;
      subtotal += price * quantity;
    }

    double total = subtotal;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return _buildCartItem(item.key, Map<String, dynamic>.from(item.value));
            },
          ),
        ),
        _buildOrderSummary(subtotal, total),
      ],
    );
  }

  // BROWSE PRODUCTS BUTTON ADDED
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.shopping_cart, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text("Your Cart is Empty", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text("Looks like you haven't added anything yet.", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Iconsax.shop, size: 20),
            label: Text("Browse Products", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExploreProductPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  // WRAPPED CART ITEM IN A Dismissible FOR SWIPE-TO-DELETE
  Widget _buildCartItem(String key, Map<String, dynamic> item) {
    final int quantity = int.tryParse(item['quantity'].toString()) ?? 0;
    final String price = item['price'].toString();
    final String imageUrl = item['imageUrl'] ?? '';
    final String name = item['name'] ?? 'No Name';

    return Dismissible(
      key: Key(key), // Each item needs a unique key
      direction: DismissDirection.endToStart, // Swipe from right to left
      onDismissed: (direction) {
        // This is called when the item is fully swiped
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          FirebaseDatabase.instance.ref('users/${user.uid}/cart/$key').remove();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$name removed from cart")),
        );
      },
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Iconsax.trash, color: Colors.white),
            SizedBox(width: 8),
            Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                  errorWidget: (c, e, s) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Iconsax.gallery_slash, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('₹$price', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 14)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(icon: Icon(Iconsax.minus_square, size: 24, color: Colors.grey.shade600), onPressed: () => _updateQuantity(key, quantity - 1)),
                  Text(quantity.toString(), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Iconsax.add_square, size: 24, color: Colors.deepOrange), onPressed: () => _updateQuantity(key, quantity + 1)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // No changes needed in _buildOrderSummary
  Widget _buildOrderSummary(double subtotal, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -10))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              Text('₹${total.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: total > 0
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutPage(totalAmount: total),
                  ),
                );
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
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
}