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
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late final DatabaseReference _cartRef;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _cartRef = FirebaseDatabase.instance.ref('users/${_currentUser!.uid}/cart');
    }
  }

  void _updateQuantity(String productKey, int newQuantity) {
    if (newQuantity > 0) {
      _cartRef.child(productKey).update({'quantity': newQuantity});
    } else {
      // If quantity is 0 or less, remove the item
      _cartRef.child(productKey).remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Cart")),
        body: const Center(child: Text("Please log in to view your cart.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("My Cart", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: StreamBuilder(
        stream: _cartRef.onValue,
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
          cartItems.forEach((item) {
            final itemData = Map<String, dynamic>.from(item.value);
            subtotal += (double.tryParse(itemData['price'] ?? '0') ?? 0) * (itemData['quantity'] ?? 0);
          });
          double deliveryFee = subtotal > 0 ? 50.00 : 0.00;
          double total = subtotal + deliveryFee;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return _buildCartItem(item.key, Map<String, dynamic>.from(item.value));
                  },
                ),
              ),
              _buildOrderSummary(subtotal, deliveryFee, total),
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
    int quantity = item['quantity'] ?? 0;
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
              child: Image.network(item['imageUrl'] ?? '', width: 70, height: 70, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('₹${item['price']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 14)),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(icon: const Icon(Iconsax.minus_square, size: 20), onPressed: () => _updateQuantity(key, quantity - 1)),
                Text(quantity.toString(), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Iconsax.add_square, size: 20, color: Colors.deepOrange), onPressed: () => _updateQuantity(key, quantity + 1)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal, double deliveryFee, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -10))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600)),
              Text('₹${subtotal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600)),
              Text('₹${deliveryFee.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
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
              onPressed: total > 0 ? () {} : null, // Disable button if cart is empty
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Proceed to Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}
