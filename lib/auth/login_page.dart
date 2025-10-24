import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iconsax/iconsax.dart';
import '../firebase_options.dart';
import '../pages/core/home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final bool showSkip;

  const LoginPage({super.key, this.showSkip = true});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _dbRef;

  // Hover states
  bool _isLoginHovered = false;
  bool _isGoogleHovered = false;
  bool _isSkipHovered = false;
  bool _isSignUpHovered = false;
  bool _isForgotHovered = false;
  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://smart-paint-shop-default-rtdb.firebaseio.com',
    ).ref();
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // --- THIS IS THE NEW ERROR HANDLING BLOCK ---
      String errorMessage = "Login failed. Please try again."; // Default
      if (e.code == 'invalid-credential') {
        errorMessage = "Incorrect email or password. Please try again.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "This user account has been disabled.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address format is not valid.";
      } else {
        // A generic message for other unexpected Firebase errors
        errorMessage = "An error occurred. Please check your connection.";
      }
      _showSnackBar(errorMessage, Colors.redAccent);
      // --- END OF NEW BLOCK ---
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = kIsWeb
          ? GoogleSignIn(clientId: DefaultFirebaseOptions.web.appId)
          : GoogleSignIn();

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user != null) {
        final userRef = _dbRef.child("users").child(user.uid);
        final snapshot = await userRef.get();

        if (!snapshot.exists) {
          await userRef.set({
            'uid': user.uid,
            'name': user.displayName,
            'email': user.email,
            'photoUrl': user.photoURL,
            'userType': 'Customer',
            'status': 'approved',
            'createdAt': DateTime.now().toIso8601String(),
          });
        } else {
          await userRef.update({
            'name': user.displayName,
            'photoUrl': user.photoURL,
          });
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Google Sign-In failed", Colors.redAccent);
    } catch (e) {
      _showSnackBar("An unexpected error occurred during Google Sign-In.", Colors.redAccent);
    }
    finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Please enter your email address to reset password.", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar("Password reset link sent to your email.", Colors.green);
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred.";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found for that email.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is not valid.";
      }
      _showSnackBar(errorMessage, Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            // Background elements with animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Stack(
                      children: [
                        Positioned(
                            top: -size.height * 0.15,
                            right: -size.width * 0.2,
                            child: Container(
                                width: size.width * 0.6,
                                height: size.width * 0.6,
                                decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                        colors: [
                                          Colors.deepOrange.withOpacity(0.2),
                                          Colors.deepOrange.withOpacity(0.05),
                                          Colors.transparent
                                        ],
                                        stops: const [0.1, 0.5, 1.0]
                                    ),
                                    shape: BoxShape.circle
                                )
                            )
                        ),
                        Positioned(
                            bottom: -size.height * 0.2,
                            left: -size.width * 0.2,
                            child: Container(
                                width: size.width * 0.5,
                                height: size.width * 0.5,
                                decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                        colors: [
                                          Colors.orange.withOpacity(0.15),
                                          Colors.orange.withOpacity(0.05),
                                          Colors.transparent
                                        ],
                                        stops: const [0.1, 0.5, 1.0]
                                    ),
                                    shape: BoxShape.circle
                                )
                            )
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with animation
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [
                                      Colors.deepOrange.withOpacity(0.15),
                                      Colors.orange.withOpacity(0.1)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.deepOrange.withOpacity(0.3),
                                    width: 2
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.deepOrange.withOpacity(0.2),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4)
                                  )
                                ]
                            ),
                            child: Icon(
                                Iconsax.brush_1,
                                size: 40,
                                color: Colors.deepOrange
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Title with gradient
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.deepOrange,
                                Colors.orange,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                                'Welcome',
                                style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2
                                ),
                                textAlign: TextAlign.center
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                              'Sign in to continue to your account',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  height: 1.4
                              ),
                              textAlign: TextAlign.center
                          ),

                          const SizedBox(height: 40),

                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email Address',
                            icon: Iconsax.sms,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Iconsax.lock_1,
                            obscure: true,
                            isPassword: true,
                            toggleObscure: () { setState(() { _obscurePassword = !_obscurePassword; }); },
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              // --- Validation Fix from previous step ---
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              // --- End Fix ---
                              if (!value.contains(RegExp(r'[A-Z]'))) {
                                return 'Password must contain an uppercase letter';
                              }
                              if (!value.contains(RegExp(r'[0-9]'))) {
                                return 'Password must contain a number';
                              }
                              if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                                return 'Password must contain a special character';
                              }
                              if (value.startsWith(' ')) {
                                return 'Password cannot start with a space';
                              }
                              if (value.contains('  ')) {
                                return 'Password cannot contain consecutive spaces';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Forgot password with hover effect
                          MouseRegion(
                            onEnter: (_) => setState(() => _isForgotHovered = true),
                            onExit: (_) => setState(() => _isForgotHovered = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: _isForgotHovered
                                      ? Colors.deepOrange.withOpacity(0.1)
                                      : Colors.transparent
                              ),
                              child: TextButton(
                                onPressed: _resetPassword,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                    "Forgot Password?",
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.w500,
                                        decoration: _isForgotHovered
                                            ? TextDecoration.underline
                                            : TextDecoration.none
                                    )
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login button with hover effect
                          MouseRegion(
                            onEnter: (_) => setState(() => _isLoginHovered = true),
                            onExit: (_) => setState(() => _isLoginHovered = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                    colors: [
                                      Colors.deepOrange,
                                      _isLoginHovered ? Colors.orange : Colors.deepOrange[700]!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight
                                ),
                                boxShadow: _isLoginHovered
                                    ? [
                                  BoxShadow(
                                      color: Colors.deepOrange.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4)
                                  )
                                ]
                                    : [
                                  BoxShadow(
                                      color: Colors.deepOrange.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2)
                                  )
                                ],
                              ),
                              child: _isLoading
                                  ? Container(
                                  padding: const EdgeInsets.all(16),
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2
                                  )
                              )
                                  : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)
                                    ),
                                  ),
                                  onPressed: _loginUser,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                        'Login',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600
                                        )
                                    ),
                                  )
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          Row(children: [
                            Expanded(
                                child: Divider(
                                    thickness: 1,
                                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300
                                )
                            ),
                            Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                    "Or continue with",
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600
                                    )
                                )
                            ),
                            Expanded(
                                child: Divider(
                                    thickness: 1,
                                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300
                                )
                            ),
                          ]),

                          const SizedBox(height: 30),

                          // Google sign in with hover effect
                          MouseRegion(
                            onEnter: (_) => setState(() => _isGoogleHovered = true),
                            onExit: (_) => setState(() => _isGoogleHovered = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300
                                ),
                                color: _isGoogleHovered
                                    ? (isDark ? Colors.grey.shade700 : Colors.grey.shade100)
                                    : (isDark ? Colors.grey.shade800 : Colors.white),
                                boxShadow: _isGoogleHovered
                                    ? [
                                  BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2)
                                  )
                                ]
                                    : null,
                              ),
                              child: OutlinedButton.icon(
                                  icon: Image.asset(
                                      "assets/google.png",
                                      height: 24,
                                      width: 24,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                          Iconsax.gallery,
                                          size: 24,
                                          color: Colors.grey.shade600
                                      )
                                  ),
                                  label: Text(
                                      "Sign in with Google",
                                      style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.grey.shade800
                                      )
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)
                                    ),
                                    side: BorderSide.none,
                                    backgroundColor: Colors.transparent,
                                  ),
                                  onPressed: _signInWithGoogle
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Sign up link with hover effect
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                  "Don't have an account?",
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600
                                  )
                              ),
                              const SizedBox(width: 4),
                              MouseRegion(
                                onEnter: (_) => setState(() => _isSignUpHovered = true),
                                onExit: (_) => setState(() => _isSignUpHovered = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: _isSignUpHovered
                                          ? Colors.deepOrange.withOpacity(0.1)
                                          : Colors.transparent
                                  ),
                                  child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation, secondaryAnimation) => const RegisterPage(),
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                return SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(1, 0),
                                                    end: Offset.zero,
                                                  ).animate(animation),
                                                  child: child,
                                                );
                                              },
                                              transitionDuration: const Duration(milliseconds: 400),
                                            )
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                          "Sign up",
                                          style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.deepOrange,
                                              fontWeight: FontWeight.w600,
                                              decoration: _isSignUpHovered
                                                  ? TextDecoration.underline
                                                  : TextDecoration.none
                                          )
                                      )
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Skip button with hover effect
            if (widget.showSkip)
              Positioned(
                top: 16,
                right: 16,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isSkipHovered = true),
                  onExit: (_) => setState(() => _isSkipHovered = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _isSkipHovered
                          ? (isDark ? Colors.grey.shade700 : Colors.white)
                          : (isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.white.withOpacity(0.7)),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(_isSkipHovered ? 0.1 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2)
                        )
                      ],
                      border: _isSkipHovered
                          ? Border.all(color: Colors.deepOrange.withOpacity(0.3))
                          : null,
                    ),
                    child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 500),
                              )
                          );
                        },
                        child: Text(
                            "Skip",
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepOrange
                            )
                        )
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
        required String hint,
        required IconData icon,
        bool obscure = false,
        bool isPassword = false,
        VoidCallback? toggleObscure,
        bool obscureText = true,
        String? Function(String?)? validator}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : obscure,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: GoogleFonts.poppins(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          fontSize: 15,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.deepOrange,
          size: 20,
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Iconsax.eye_slash : Iconsax.eye,
            color: Colors.grey.shade500,
            size: 20,
          ),
          onPressed: toggleObscure,
        )
            : null,
        filled: true,
        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.deepOrange.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}