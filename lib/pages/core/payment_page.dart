import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For user ID
import 'package:firebase_database/firebase_database.dart'; // For saving order
import 'package:iconsax/iconsax.dart'; // For icons
// Import your Cart Page if needed to clear cart after payment
// import 'cart_page.dart';
// Import a success page if you have one
// import 'order_success_page.dart';

class PaymentPage extends StatefulWidget {
  final int totalAmount; // Amount in smallest currency unit (e.g., paise)
  final String? deliveryAddress;
  final String? fullName;
  final String? email;
  final String? phone;
  final double? lat;
  final double? lng;

  const PaymentPage({
    super.key,
    required this.totalAmount,
    this.deliveryAddress,
    this.fullName,
    this.email,
    this.phone,
    this.lat,
    this.lng,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  bool _isProcessing = false; // To show loading state
  bool _paymentCompleted = false;
  String? _deliveryAddress;
  bool _openedCheckout = false;
  bool _checkoutInvoked = false; // helps detect if sheet failed to appear

  // --- Razorpay Event Listeners ---
  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _deliveryAddress = widget.deliveryAddress;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_openedCheckout) {
        _openedCheckout = true;
        _openCheckout();
      }
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // --- Handle Payment Success ---
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    debugPrint("✅ PAYMENT SUCCESSFUL: ${response.paymentId}");
    setState(() => _isProcessing = true); // Show processing indicator
    _paymentCompleted = true;
    try { _razorpay.clear(); } catch (_) {}

    // --- SAVE ORDER TO FIREBASE ---
    // This is where you save the order details after successful payment
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final rootRef = FirebaseDatabase.instance.ref();
      final userOrdersRef = rootRef.child('users/${user.uid}/orders');
      final orderRef = userOrdersRef.push();
      try {
        // Read cart items before clearing to build notification content
        final cartSnap = await rootRef.child('users/${user.uid}/cart').get();
        final List<String> purchasedNames = [];
        if (cartSnap.exists && cartSnap.value is Map) {
          final cartMap = Map<String, dynamic>.from(cartSnap.value as Map);
          for (final entry in cartMap.entries) {
            final v = Map<String, dynamic>.from(entry.value);
            final name = (v['name'] ?? '').toString();
            if (name.isNotEmpty) purchasedNames.add(name);
          }
        }

        final orderPayload = {
          'userId': user.uid,
          'orderId': orderRef.key, // Save the generated key as order ID
          'paymentId': response.paymentId,
          'signature': response.signature, // Important for server verification (if implemented)
          'orderTotal': widget.totalAmount / 100.0, // Convert back to main currency unit (e.g., INR)
          'status': 'Payment Successful - Pending Confirmation', // Initial status
          'timestamp': ServerValue.timestamp, // Firebase server timestamp
          'deliveryAddress': _deliveryAddress ?? '',
          if (widget.lat != null && widget.lng != null) 'deliveryLocation': {'lat': widget.lat, 'lng': widget.lng},
          'customer': {
            'name': widget.fullName ?? '',
            'email': widget.email ?? '',
            'phone': widget.phone ?? '',
          },
          'items': purchasedNames,
          // Manager fields
          'manager': {
            'status': 'pending',
            'eta': null, // to be set by manager
            'notes': null,
          },
        };

        await orderRef.set(orderPayload);
        debugPrint("✅ Order saved successfully to Firebase: ${orderRef.key}");

        // Mirror to global orders so Manager dashboard (which reads /orders) can see it
        try {
          await rootRef.child('orders').child(orderRef.key!).set(orderPayload);
        } catch (e) {
          debugPrint('Warn: Failed to mirror to /orders: $e');
        }

        // --- SEND NOTIFICATIONS ---
        await _sendPurchaseNotifications(user.uid, purchasedNames);

        // --- CLEAR CART --- (Optional but recommended)
        await rootRef.child('users/${user.uid}/cart').remove();
        debugPrint("🛒 Cart cleared.");

        // --- NAVIGATE TO SUCCESS PAGE ---
        if (mounted) {
          Navigator.pushReplacement( // Replace current page so user can't go back to payment
              context,
              MaterialPageRoute(builder: (_) => OrderSuccessPage(orderId: orderRef.key ?? 'N/A', paymentId: response.paymentId ?? 'N/A')) // Pass relevant IDs
          );
        }

      } catch (e) {
        debugPrint("❌ Error saving order: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Payment successful, but failed to save order: $e'),
            backgroundColor: Colors.orange,
          ));
          setState(() => _isProcessing = false);
        }
      }
    } else {
      debugPrint("❌ User not logged in after payment?");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment successful, but user session issue occurred.'),
          backgroundColor: Colors.orange,
        ));
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _sendPurchaseNotifications(String buyerUid, List<String> productNames) async {
    final db = FirebaseDatabase.instance.ref();
    
    // Build detailed message with product info
    final productInfo = productNames.isNotEmpty
        ? productNames.join(', ')
        : 'Items';
    
    final message = 'New Order: $productInfo';
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Enhanced payload with location and order details
    final payload = {
      'message': message,
      'timestamp': now,
      'isRead': false,
      'type': 'order', // Notification type
      'orderDetails': {
        'products': productNames,
        'totalAmount': widget.totalAmount / 100.0,
        'deliveryAddress': _deliveryAddress ?? 'Not specified',
        if (widget.lat != null && widget.lng != null) 'location': {
          'lat': widget.lat,
          'lng': widget.lng,
        },
        'customer': {
          'name': widget.fullName ?? 'N/A',
          'email': widget.email ?? 'N/A',
          'phone': widget.phone ?? 'N/A',
        },
      },
    };

    // Always notify the buyer (self) — allowed by rules
    try { await db.child('users/$buyerUid/notifications').push().set(payload); } catch (e) { debugPrint('Notify self failed: $e'); }

    // Broadcast to global role-based channels (managers/admins) — compatible with provided rules once added
    try { await db.child('notifications/globalForManagers').push().set(payload); } catch (e) { debugPrint('Notify managers failed: $e'); }
    try { await db.child('notifications/globalForAdmins').push().set(payload); } catch (e) { debugPrint('Notify admins failed: $e'); }
  }

  // --- Handle Payment Error ---
  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    if (_paymentCompleted) return;
    debugPrint("❌ PAYMENT FAILED: ${response.code} - ${response.message}");
    setState(() => _isProcessing = false); // Hide loading indicator
    final msg = (response.message == null || response.message!.isEmpty)
        ? 'Payment failed. Please try again.'
        : 'Payment Failed: ${response.message}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
    ));
    // You might want to navigate back or allow retry
  }

  // --- Handle External Wallet (like PhonePe, Google Pay) ---
  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    debugPrint("📦 EXTERNAL WALLET: ${response.walletName}");
    // You might show a message like "Waiting for payment confirmation from [walletName]..."
    // Razorpay usually handles the success/failure callback after this.
  }

  // --- Open Razorpay Checkout ---
  void _openCheckout() async {
    if (_isProcessing) return; // Prevent multiple clicks
    setState(() => _isProcessing = true); // Show loading indicator

    // Fetch user details (optional but good for prefill)
    final user = FirebaseAuth.instance.currentUser;
    String? userEmail = widget.email ?? user?.email;
    String? userContact = widget.phone;

    if (_deliveryAddress == null || _deliveryAddress!.trim().isEmpty) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a delivery address to proceed.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }

    if (widget.totalAmount < 100) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Amount too low to process. Minimum is ₹1.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }

    // --- Payment Options ---
    var options = {
      'key': 'rzp_test_RVfRg0s4WjSnkL', // ⭐ Replace with your ACTUAL Key ID
      'amount': widget.totalAmount, // Amount in paise (or smallest unit)
      'currency': 'INR',
      'name': 'Chandra Paints', // Your App/Company Name
      'description': 'Paint Order Payment', // Order Description
      'timeout': 120, // Payment timeout in seconds (optional)
      'prefill': {
        // Prefill user details if available
        if (userEmail != null) 'email': userEmail,
        if (userContact != null) 'contact': userContact,
      },
      'theme': {
        'color': '#FF5722' // Set theme color (Deep Orange hex)
      }
      // Add 'order_id' if you generate it on your server first (recommended for production)
      // 'order_id': serverGeneratedOrderId,
    };

    try {
      _checkoutInvoked = true;
      _razorpay.open(options);
      // Watchdog: if the sheet doesn't show (no callbacks) within 8s, let user retry
      Future.delayed(const Duration(seconds: 8), () {
        if (!mounted) return;
        if (!_paymentCompleted && _checkoutInvoked && _isProcessing) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open payment sheet. Tap to retry.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false); // Hide loading on error
      debugPrint('Error opening Razorpay checkout: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not start payment. Please try again. (Details: ${e.toString()})'),
        backgroundColor: Colors.red,
      ));
    }
    // Don't set _isProcessing = false here, wait for callbacks
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Processing Payment", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.deepOrange),
            const SizedBox(height: 16),
            Text('Opening secure payment...', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            if (!_isProcessing && !_paymentCompleted)
              ElevatedButton(
                onPressed: _openCheckout,
                child: const Text('Retry Payment'),
              ),
          ],
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