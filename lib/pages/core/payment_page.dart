import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // ⭐ Import Razorpay
import 'package:firebase_auth/firebase_auth.dart'; // For user ID
import 'package:firebase_database/firebase_database.dart'; // For saving order
import 'package:iconsax/iconsax.dart'; // For icons
// Import your Cart Page if needed to clear cart after payment
import 'cart_page.dart';
// Import a success page if you have one
// import 'order_success_page.dart';

class PaymentPage extends StatefulWidget {
  final int totalAmount; // Amount in smallest currency unit (e.g., paise)
  // Add other details you might need, like delivery address, cart items list
  // final String deliveryAddress;
  // final List<CartItemDetails> cartItems;

  const PaymentPage({
    super.key,
    required this.totalAmount,
    // required this.deliveryAddress,
    // required this.cartItems,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  bool _isProcessing = false; // To show loading state

  // --- Razorpay Event Listeners ---
  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // Clear listeners when page is disposed
    super.dispose();
  }

  // --- Handle Payment Success ---
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    print("✅ PAYMENT SUCCESSFUL: ${response.paymentId}");
    setState(() => _isProcessing = true); // Show processing indicator

    // --- SAVE ORDER TO FIREBASE ---
    // This is where you save the order details after successful payment
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final orderRef = FirebaseDatabase.instance.ref('orders').push(); // Create a new unique order ID
      try {
        await orderRef.set({
          'userId': user.uid,
          'orderId': orderRef.key, // Save the generated key as order ID
          'paymentId': response.paymentId,
          'signature': response.signature, // Important for server verification (if implemented)
          'orderTotal': widget.totalAmount / 100.0, // Convert back to main currency unit (e.g., INR)
          'status': 'Payment Successful - Pending Confirmation', // Initial status
          'timestamp': ServerValue.timestamp, // Firebase server timestamp
          // Add other necessary details passed to this page:
          // 'deliveryAddress': widget.deliveryAddress,
          // 'items': widget.cartItems.map((item) => item.toMap()).toList(), // Need a toMap method in CartItemDetails
        });
        print("✅ Order saved successfully to Firebase: ${orderRef.key}");

        // --- CLEAR CART --- (Optional but recommended)
        await FirebaseDatabase.instance.ref('users/${user.uid}/cart').remove();
        print("🛒 Cart cleared.");

        // --- NAVIGATE TO SUCCESS PAGE ---
        if (mounted) {
          Navigator.pushReplacement( // Replace current page so user can't go back to payment
              context,
              MaterialPageRoute(builder: (_) => OrderSuccessPage(orderId: orderRef.key ?? 'N/A', paymentId: response.paymentId ?? 'N/A')) // Pass relevant IDs
          );
        }

      } catch (e) {
        print("❌ Error saving order: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Payment successful, but failed to save order: $e'),
            backgroundColor: Colors.orange,
          ));
          setState(() => _isProcessing = false);
        }
      }
    } else {
      print("❌ User not logged in after payment?");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment successful, but user session issue occurred.'),
          backgroundColor: Colors.orange,
        ));
        setState(() => _isProcessing = false);
      }
    }
  }

  // --- Handle Payment Error ---
  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    print("❌ PAYMENT FAILED: ${response.code} - ${response.message}");
    setState(() => _isProcessing = false); // Hide loading indicator
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment Failed: ${response.message}'),
      backgroundColor: Colors.red,
    ));
    // You might want to navigate back or allow retry
  }

  // --- Handle External Wallet (like PhonePe, Google Pay) ---
  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    print("📦 EXTERNAL WALLET: ${response.walletName}");
    // You might show a message like "Waiting for payment confirmation from [walletName]..."
    // Razorpay usually handles the success/failure callback after this.
  }

  // --- Open Razorpay Checkout ---
  void _openCheckout() async {
    if (_isProcessing) return; // Prevent multiple clicks
    setState(() => _isProcessing = true); // Show loading indicator

    // Fetch user details (optional but good for prefill)
    final user = FirebaseAuth.instance.currentUser;
    String? userEmail = user?.email;
    // You might fetch phone number from your user profile in Firebase if available

    // --- Payment Options ---
    var options = {
      'key': 'rzp_test_RVfRg0s4WjSnkL', // ⭐ Replace with your ACTUAL Key ID
      'amount': widget.totalAmount, // Amount in paise (or smallest unit)
      'name': 'Chandra Paints', // Your App/Company Name
      'description': 'Paint Order Payment', // Order Description
      'timeout': 120, // Payment timeout in seconds (optional)
      'prefill': {
        // Prefill user details if available
        if (userEmail != null) 'email': userEmail,
        // if (userPhone != null) 'contact': userPhone
      },
      'theme': {
        'color': '#FF5722' // Set theme color (Deep Orange hex)
      }
      // Add 'order_id' if you generate it on your server first (recommended for production)
      // 'order_id': serverGeneratedOrderId,
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if(mounted) setState(() => _isProcessing = false); // Hide loading on error
      debugPrint('Error opening Razorpay checkout: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error initiating payment: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
    // Don't set _isProcessing = false here, wait for callbacks
  }

  @override
  Widget build(BuildContext context) {
    // Format amount back to INR for display
    final double amountInRupees = widget.totalAmount / 100.0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Confirm Payment", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Iconsax.wallet_money, size: 80, color: Colors.deepOrange.shade300),
              const SizedBox(height: 24),
              Text(
                'Total Amount Payable',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${amountInRupees.toStringAsFixed(2)}', // Display formatted amount
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              // Display Delivery Address (if passed)
              // if (widget.deliveryAddress.isNotEmpty) ...[
              //    Text("Deliver to:", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
              //    Text(widget.deliveryAddress, style: GoogleFonts.poppins(fontSize: 16), textAlign: TextAlign.center),
              //    const SizedBox(height: 30),
              // ],

              _isProcessing
                  ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange)) // Show loading indicator
                  : ElevatedButton.icon(
                icon: const Icon(Iconsax.shield_tick),
                label: Text('Proceed to Pay Securely', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                onPressed: _openCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              if (!_isProcessing) // Show cancel only when not processing
                TextButton(
                  onPressed: () => Navigator.pop(context), // Go back to cart or previous page
                  child: Text('Cancel Payment', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                ),
              const Spacer(), // Pushes content to center if less
            ],
          ),
        ),
      ),
    );
  }
}


// --- Simple Order Success Page (Placeholder) ---
// Create a new file e.g., lib/pages/core/order_success_page.dart
class OrderSuccessPage extends StatelessWidget {
  final String orderId;
  final String paymentId;

  const OrderSuccessPage({super.key, required this.orderId, required this.paymentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order Successful"), automaticallyImplyLeading: false), // Prevent back button
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.tick_circle, color: Colors.green, size: 100),
              SizedBox(height: 20),
              Text("Payment Successful!", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Your order has been placed.", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700)),
              SizedBox(height: 20),
              Text("Order ID: $orderId", style: GoogleFonts.poppins(fontSize: 14)),
              Text("Payment ID: $paymentId", style: GoogleFonts.poppins(fontSize: 14)),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to the Home page or Explore page
                  Navigator.popUntil(context, (route) => route.isFirst); // Go back to the very first route (usually home)
                },
                child: Text("Continue Shopping"),
              )
            ],
          ),
        ),
      ),
    );
  }
}