import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  final String? prefilledEmail;

  const RegisterPage({super.key, this.prefilledEmail});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  String _userType = 'Customer';
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://smart-paint-shop-default-rtdb.firebaseio.com',
  ).ref();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final address = _addressController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

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
        'userType': _userType,
        'createdAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Registration failed")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailIsPrefilled = widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Create Account',
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTextField(_nameController, 'Full Name', Icons.person),

              // Email field: readOnly if prefilled
              _buildTextField(
                _emailController,
                'Email',
                Icons.email,
                readOnly: emailIsPrefilled,
              ),

              _buildTextField(_phoneController, 'Phone', Icons.phone),
              _buildTextField(_addressController, 'Address', Icons.home),
              _buildTextField(_passwordController, 'Password', Icons.lock, obscure: true),
              _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock_outline, obscure: true),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("User Type:"),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _userType,
                    items: ['Customer', 'Painter', 'Shop Owner'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) => setState(() => _userType = value!),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  backgroundColor: Colors.deepOrange,
                ),
                onPressed: _registerUser,
                child: Text('Register', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscure = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          fillColor: readOnly ? Colors.grey.shade200 : null,
          filled: readOnly,
        ),
      ),
    );
  }
}
