import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../pages/core/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:ui';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final String? prefilledEmail;

  const RegisterPage({super.key, this.prefilledEmail});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://smart-paint-shop-default-rtdb.firebaseio.com',
  ).ref();

  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideAnimations = List.generate(
      7, // Title, 5 fields, button, login text
          (index) => Tween<Offset>(
        begin: const Offset(0, 0.8),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.1 * index, 1.0, curve: Curves.easeOutCubic),
      )),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    // --- FIX: Added missing controllers ---
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    // --- END FIX ---
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final address = _addressController.text.trim();

    // --- UPDATED VALIDATION BLOCK ---
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || address.isEmpty) {
      _showSnackBar("Please fill all fields", isError: true);
      return;
    }
    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      _showSnackBar("Please enter a valid email address", isError: true);
      return;
    }
    if (password != confirm) {
      _showSnackBar("Passwords do not match", isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters", isError: true);
      return;
    }
    // Added complex password checks to match login page
    if (!password.contains(RegExp(r'[A-Z]'))) {
      _showSnackBar("Password must contain an uppercase letter", isError: true);
      return;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      _showSnackBar("Password must contain a number", isError: true);
      return;
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      _showSnackBar("Password must contain a special character", isError: true);
      return;
    }
    if (password.startsWith(' ')) {
      _showSnackBar("Password cannot start with a space", isError: true);
      return;
    }
    if (password.contains('  ')) {
      _showSnackBar("Password cannot contain consecutive spaces", isError: true);
      return;
    }
    // --- END OF UPDATED VALIDATION BLOCK ---

    setState(() => _isLoading = true);

    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCred.user!.uid;

      await userCred.user!.updateDisplayName(name);

      await _dbRef.child('users').child(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'userType': 'Customer', // All new users are customers
        'status': 'approved',
        'createdAt': DateTime.now().toIso8601String(),
      });
      // Initialize unified profile node for autofill & manager views
      await _dbRef.child('users').child(uid).child('profile').set({
        'fullName': name,
        'phone': phone,
        'email': email,
        'address': address,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      _showSnackBar("Registration successful!", isError: false);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Registration failed", isError: true);
    } catch (e) {
      _showSnackBar("An unexpected error occurred: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepOrange.shade400, Colors.orange.shade200],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned(top: -100, left: -100, child: _buildGlassyCircle(200)),
            Positioned(bottom: -150, right: -120, child: _buildGlassyCircle(300)),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SlideTransition(
                        position: _slideAnimations[0],
                        child: Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black.withValues(alpha: 0.2),
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildGlassyFormCard(),
                      const SizedBox(height: 20),
                      SlideTransition(
                        position: _slideAnimations[6],
                        child: _buildLoginRedirect(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassyCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  Widget _buildGlassyFormCard() {
    final emailIsPrefilled = widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            children: [
              SlideTransition(position: _slideAnimations[1], child: _buildTextField(_nameController, 'Full Name', Icons.person_outline)),
              const SizedBox(height: 16),
              SlideTransition(position: _slideAnimations[2], child: _buildTextField(_emailController, 'Email Address', Icons.email_outlined, readOnly: emailIsPrefilled, keyboardType: TextInputType.emailAddress)),
              const SizedBox(height: 16),
              SlideTransition(position: _slideAnimations[3], child: _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone)),
              const SizedBox(height: 16),
              SlideTransition(position: _slideAnimations[4], child: _buildTextField(_addressController, 'Address', Icons.home_outlined)),
              const SizedBox(height: 16),
              SlideTransition(
                position: _slideAnimations[5],
                child: _buildTextField(
                  _passwordController,
                  'Password',
                  Icons.lock_outline,
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SlideTransition(
                position: _slideAnimations[6],
                child: _buildTextField(
                  _confirmPasswordController,
                  'Confirm Password',
                  Icons.lock_person_outlined,
                  obscure: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SlideTransition(
                position: _slideAnimations[6],
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                    ),
                    onPressed: _registerUser,
                    child: Text('Register', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool obscure = false,
        bool readOnly = false,
        TextInputType keyboardType = TextInputType.text,
        Widget? suffixIcon,
      }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.8)),
        prefixIcon: Icon(icon, color: Colors.white, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: readOnly ? Colors.black.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.white, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1)),
      ),
    );
  }

  Widget _buildLoginRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.9)),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement( // Use pushReplacement for better navigation flow
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
          child: Text(
            "Login",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}