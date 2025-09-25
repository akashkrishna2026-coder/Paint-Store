// lib/product/checkout_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

// Enum to manage the selected payment method
enum PaymentMethod { card, upi, cod }

class CheckoutPage extends StatefulWidget {
  final double totalAmount;

  const CheckoutPage({
    super.key,
    required this.totalAmount,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardFormKey = GlobalKey<FormState>();
  PaymentMethod _selectedMethod = PaymentMethod.card;
  bool _isProcessing = false;
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();

  // Razorpay instance
  late Razorpay _razorpay;

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
    _razorpay.clear();
    _pageController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  // Razorpay event handlers
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("✅ PAYMENT SUCCESS: ${response.paymentId}");
    setState(() => _isProcessing = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentSuccessDialog(
        amount: widget.totalAmount,
        onConfirm: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("❌ PAYMENT ERROR: ${response.code} - ${response.message}");
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}"), backgroundColor: Colors.redAccent),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("📦 EXTERNAL WALLET: ${response.walletName}");
  }

  // Stepper logic
  void _nextStep() {
    // Validate the current step's form before proceeding
    if (_currentStep == 0 && !_formKey.currentState!.validate()) {
      return;
    }
    if (_currentStep == 1) {
      if (_selectedMethod == PaymentMethod.card && !_cardFormKey.currentState!.validate()) {
        return;
      }
      if (_selectedMethod == PaymentMethod.upi && _upiController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter your UPI ID'), backgroundColor: Colors.redAccent));
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(duration: 300.ms, curve: Curves.easeInOut);
    } else {
      // Final step is to process payment
      _processPayment();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(duration: 300.ms, curve: Curves.easeInOut);
    }
  }

  void _onPaymentMethodChanged(PaymentMethod? method) {
    if (method != null) {
      setState(() => _selectedMethod = method);
    }
  }

  // Payment processing logic
  void _processPayment() {
    setState(() => _isProcessing = true);

    if (_selectedMethod == PaymentMethod.cod) {
      // For Cash on Delivery, simulate success
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isProcessing = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PaymentSuccessDialog(
            isCOD: true,
            amount: widget.totalAmount,
            onConfirm: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        );
      });
      return;
    }

    // For Card or UPI, open Razorpay
    var options = {
      'key': 'rzp_test_YOUR_KEY_ID', // IMPORTANT: PASTE YOUR RAZORPAY TEST KEY ID HERE
      'amount': (widget.totalAmount * 100).toInt(), // Amount in the smallest currency unit (paise)
      'name': 'Smart Paint Shop',
      'description': 'Order Payment',
      'prefill': {
        'contact': _phoneController.text,
        'email': 'customer@example.com' // You can get this from FirebaseAuth
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("Error opening Razorpay: $e");
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Checkout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildAddressStep(),
                _buildPaymentStep(),
                _buildReviewStep(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavigationButtons(),
    );
  }

  // --- UI Builder Widgets ---

  Widget _buildProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _buildProgressStep("Address", 0)),
          Expanded(child: _buildProgressStep("Payment", 1)),
          Expanded(child: _buildProgressStep("Review", 2)),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String title, int stepNumber) {
    bool isActive = _currentStep == stepNumber;
    bool isCompleted = _currentStep > stepNumber;
    Color activeColor = Colors.deepOrange;
    Color inactiveColor = Colors.grey.shade300;

    return Row(
      children: [
        AnimatedContainer(
          duration: 300.ms,
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isCompleted ? activeColor : (isActive ? activeColor : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(color: isCompleted || isActive ? activeColor : inactiveColor, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
              (stepNumber + 1).toString(),
              style: GoogleFonts.poppins(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isActive || isCompleted ? Colors.black87 : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Shipping Address"),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: "Full Name",
                      icon: Iconsax.user,
                      validator: (v) => v!.isEmpty ? "Name is required" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: "Address Line",
                      icon: Iconsax.location,
                      validator: (v) => v!.isEmpty ? "Address is required" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: "City",
                            icon: Iconsax.buildings,
                            validator: (v) => v!.isEmpty ? "City is required" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _pincodeController,
                            label: "Pincode",
                            icon: Iconsax.code,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) => v!.length != 6 ? "Invalid pincode" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: "Phone Number",
                      icon: Iconsax.call,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v!.length != 10 ? "Invalid phone number" : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Select Payment Method"),
          _buildPaymentMethodSelector(),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: 300.ms,
            child: _selectedMethod == PaymentMethod.card
                ? _buildCardForm()
                : _selectedMethod == PaymentMethod.upi
                ? _buildUpiForm()
                : _buildCodInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Form(
      key: _cardFormKey,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTextField(
                controller: _cardNumberController,
                label: "Card Number",
                icon: Iconsax.card,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                validator: (v) => v!.length != 16 ? "Invalid card number" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _expiryController,
                      label: "MM/YY",
                      icon: Iconsax.calendar,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      validator: (v) => v!.length != 4 ? "Invalid date" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _cvvController,
                      label: "CVV",
                      icon: Iconsax.lock,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                      validator: (v) => v!.length != 3 ? "Invalid CVV" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _cardHolderController,
                label: "Cardholder Name",
                icon: Iconsax.user,
                validator: (v) => v!.isEmpty ? "Name is required" : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpiForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildTextField(
          controller: _upiController,
          label: "UPI ID",
          icon: Iconsax.scan_barcode,
          hintText: "yourname@upi",
        ),
      ),
    );
  }

  Widget _buildCodInfo() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const ListTile(
        leading: Icon(Iconsax.wallet_money, color: Colors.deepOrange),
        title: Text("Cash on Delivery Selected"),
        subtitle: Text("Please keep the exact amount ready"),
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Review Your Order"),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSummaryRow("Total Amount", "₹${widget.totalAmount.toStringAsFixed(2)}", isTotal: true),
                ],
              ),
            ),
          ),
          _buildSectionTitle("Shipping To"),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Iconsax.location, color: Colors.deepOrange),
              title: Text(_nameController.text),
              subtitle: Text("${_addressController.text}, ${_cityController.text} - ${_pincodeController.text}"),
            ),
          ),
          _buildSectionTitle("Payment Method"),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(
                _selectedMethod == PaymentMethod.card ? Iconsax.card :
                _selectedMethod == PaymentMethod.upi ? Iconsax.scan_barcode :
                Iconsax.wallet_money,
                color: Colors.deepOrange,
              ),
              title: Text(
                _selectedMethod == PaymentMethod.card ? "Credit/Debit Card" :
                _selectedMethod == PaymentMethod.upi ? "UPI" :
                "Cash on Delivery",
              ),
              subtitle: _selectedMethod == PaymentMethod.card
                  ? Text("Ending in **** ${_cardNumberController.text.substring(_cardNumberController.text.length - 4)}")
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              TextButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            const Spacer(),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                child: _isProcessing
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text(
                  _currentStep == 2 ? 'Pay ₹${widget.totalAmount.toStringAsFixed(2)}' : 'Continue',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      children: [
        _paymentOption("Credit/Debit Card", Iconsax.card, PaymentMethod.card),
        _paymentOption("UPI", Iconsax.scan_barcode, PaymentMethod.upi),
        _paymentOption("Cash on Delivery", Iconsax.wallet_money, PaymentMethod.cod),
      ],
    );
  }

  Widget _paymentOption(String title, IconData icon, PaymentMethod method) {
    bool isSelected = _selectedMethod == method;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? Colors.deepOrange.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? Colors.deepOrange : Colors.grey.shade300, width: 1.5),
      ),
      child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: _selectedMethod,
        onChanged: _onPaymentMethodChanged,
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        secondary: Icon(icon, color: Colors.deepOrange),
        activeColor: Colors.deepOrange,
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          Text(value, style: GoogleFonts.poppins(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.deepOrange : Colors.black87, fontSize: isTotal ? 18 : 16)),
        ],
      ),
    );
  }
}

class PaymentSuccessDialog extends StatelessWidget {
  final double amount;
  final VoidCallback onConfirm;
  final bool isCOD;

  const PaymentSuccessDialog({
    super.key,
    required this.amount,
    required this.onConfirm,
    this.isCOD = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(
                isCOD ? "Order Placed!" : "Payment Successful!",
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            if (!isCOD)
              Text("₹${amount.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            const SizedBox(height: 16),
            Text(
                isCOD ? "Your order will be delivered soon. Please pay on delivery." : "Your order has been placed successfully. You will receive a confirmation email shortly.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey.shade600)
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Continue Shopping", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}