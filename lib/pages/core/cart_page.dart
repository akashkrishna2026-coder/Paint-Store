import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

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
      cartRef.child(productKey).remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text("My Cart", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)), backgroundColor: Colors.white),
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

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("My Cart", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: StreamBuilder(
        stream: cartRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _buildEmptyCart();
          }

          final cartMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final cartItems = cartMap.entries.toList();

          double subtotal = 0;
          for (var item in cartItems) {
            final itemData = Map<String, dynamic>.from(item.value);

            double price = 0.0;
            if (itemData['price'] is num) {
              price = (itemData['price'] as num).toDouble();
            } else if (itemData['price'] is String) {
              price = double.tryParse(itemData['price']) ?? 0.0;
            }

            int quantity = 0;
            if (itemData['quantity'] is num) {
              quantity = (itemData['quantity'] as num).toInt();
            } else if (itemData['quantity'] is String) {
              quantity = int.tryParse(itemData['quantity']) ?? 0;
            }

            subtotal += price * quantity;
          }

          // ⭐ MODIFIED: The total is now just the subtotal
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
              // ⭐ MODIFIED: Pass only subtotal and total to the summary
              _buildOrderSummary(subtotal, total),
            ],
          );
        },
      ),
    );
  }

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
        ],
      ),
    );
  }

  Widget _buildCartItem(String key, Map<String, dynamic> item) {
    int quantity = 0;
    if (item['quantity'] is num) {
      quantity = (item['quantity'] as num).toInt();
    } else if (item['quantity'] is String) {
      quantity = int.tryParse(item['quantity'] as String) ?? 0;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['imageUrl'] ?? '',
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
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
                  Text(item['name'] ?? 'No Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis,),
                  const SizedBox(height: 4),
                  Text('₹${item['price']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 14)),
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
    );
  }

  // ⭐ MODIFIED: Removed the deliveryFee parameter and its corresponding UI row
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

          // ⭐ REMOVED: The Row widget for the delivery fee is gone.

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
              onPressed: total > 0 ? () {
                // TODO: Navigate to the checkout page
              } : null,
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