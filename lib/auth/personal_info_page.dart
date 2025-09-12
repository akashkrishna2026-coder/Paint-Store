import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage>
    with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref("users");
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pincodeController = TextEditingController();

  // --- CHANGED: Removed old password controller ---
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;

  late AnimationController _pageLoadController;
  late AnimationController _pulseController;
  late List<Animation<Offset>> _slideAnimations;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    _pageLoadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _slideAnimations = List.generate(
      6, // Avatar, 3 fields, change pass button, save/cancel buttons
          (index) => Tween<Offset>(
        begin: const Offset(0, 0.6),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _pageLoadController,
        curve: Interval(
          0.1 * index,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      )),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _pageLoadController.forward();
  }

  @override
  void dispose() {
    _pageLoadController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _pincodeController.dispose();
    // --- CHANGED: Removed old password controller ---
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? "";
      _emailController.text = user.email ?? "";
      final snapshot = await _dbRef.child(user.uid).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _pincodeController.text = data["pincode"] ?? "";
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    final pincode = _pincodeController.text.trim();
    if (name.isEmpty || pincode.isEmpty) {
      _showToast("Name and Pincode cannot be empty", isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await _dbRef.child(user.uid).update({"name": name, "pincode": pincode});
      }
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("profile_pictures")
            .child(user!.uid)
            .child("profile.jpg");
        await ref.putFile(_selectedImage!, SettableMetadata(contentType: 'image/jpeg'));
        final url = await ref.getDownloadURL();
        await user.updatePhotoURL(url);
        await _dbRef.child(user.uid).update({"photoUrl": url});
        _showToast("Profile picture updated");
      }
      _showToast("Changes saved successfully");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showToast("Error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) setState(() => _selectedImage = File(picked.path));
    } catch (e) {
      _showToast("Cannot pick image: ${e.toString()}", isError: true);
    }
  }

  Future<void> _deleteProfilePicture() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("profile_pictures")
            .child(user.uid)
            .child("profile.jpg");
        await ref.delete();
        await user.updatePhotoURL(null);
        await _dbRef.child(user.uid).update({"photoUrl": null});
        setState(() => _selectedImage = null);
        _showToast("Profile picture deleted");
      }
    } catch (e) {
      _showToast("Cannot delete image: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
        msg: message,
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM);
  }

  void _showAvatarOptions() {
    final user = _auth.currentUser;
    if (user == null) return;
    if (user.photoURL != null || _selectedImage != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SafeArea(
            child: Wrap(children: [
              ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.deepOrange),
                  title: Text("Change Picture", style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  }),
              ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text("Delete Picture", style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteProfilePicture();
                  }),
              const Divider(height: 1),
              ListTile(
                  leading: const Icon(Icons.close),
                  title: Text("Cancel", style: GoogleFonts.poppins()),
                  onTap: () => Navigator.pop(context)),
            ]),
          ),
        ),
      );
    } else {
      _pickImage();
    }
  }

  // --- CHANGED: Method to handle password update logic without old password ---
  Future<void> _updatePassword() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmNewPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showToast("All password fields are required", isError: true);
      return;
    }
    if (newPass != confirmPass) {
      _showToast("New passwords do not match", isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showToast("New password must be at least 6 characters", isError: true);
      return;
    }

    Navigator.of(context).pop();
    setState(() => _isLoading = true);

    try {
      await user.updatePassword(newPass);
      _showToast("Password updated successfully!");
    } on FirebaseAuthException catch (e) {
      // This may fire if the user's session is old. Re-logging in would be required.
      _showToast("Error: ${e.message ?? 'Could not update password.'}", isError: true);
    } catch (e) {
      _showToast("An unexpected error occurred", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- CHANGED: Method to show the change password dialog without old password field ---
  Future<void> _showChangePasswordDialog() async {
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();

    bool obscureNew = true;
    bool obscureConfirm = true;

    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text("Change Password", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPasswordTextField(_newPasswordController, "New Password", obscureNew,
                            () => setStateDialog(() => obscureNew = !obscureNew)),
                    const SizedBox(height: 15),
                    _buildPasswordTextField(_confirmNewPasswordController, "Confirm New Password", obscureConfirm,
                            () => setStateDialog(() => obscureConfirm = !obscureConfirm)),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                  ),
                  ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    child: Text("Update", style: GoogleFonts.poppins(color: Colors.white)),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepOrange.shade400, Colors.orange.shade200])),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text("Edit Profile",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Stack(
          children: [
            Positioned(
                top: -100,
                left: -100,
                child: _buildGlassyCircle(200, Colors.white)),
            Positioned(
                bottom: -120,
                right: -150,
                child: _buildGlassyCircle(300, Colors.white)),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      SlideTransition(position: _slideAnimations[0], child: _buildProfileAvatar(user)),
                      const SizedBox(height: 30),
                      _buildGlassyFormCard(user),
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

  Widget _buildGlassyCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.08),
      ),
    );
  }

  Widget _buildGlassyFormCard(User? user) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              SlideTransition(position: _slideAnimations[1], child: _buildTextField(controller: _nameController, label: "Full Name", icon: Icons.person_outline)),
              const SizedBox(height: 20),
              SlideTransition(position: _slideAnimations[2], child: _buildTextField(controller: _emailController, label: "Email", icon: Icons.email_outlined, readOnly: true)),
              const SizedBox(height: 20),
              SlideTransition(position: _slideAnimations[3], child: _buildTextField(controller: _pincodeController, label: "Pincode", icon: Icons.location_on_outlined, keyboardType: TextInputType.number)),
              const SizedBox(height: 20),
              SlideTransition(position: _slideAnimations[4], child: _buildChangePasswordButton()),
              const SizedBox(height: 30),
              SlideTransition(position: _slideAnimations[5], child: _buildButtons()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(User? user) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2)
              ]),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.orange.shade100,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: (_selectedImage != null)
                  ? ClipOval(child: Image.file(_selectedImage!, key: const ValueKey('selected'), fit: BoxFit.cover, width: 120, height: 120))
                  : (user?.photoURL != null)
                  ? ClipOval(child: Image.network(user!.photoURL!, key: const ValueKey('network'), fit: BoxFit.cover, width: 120, height: 120))
                  : Icon(Icons.person, key: const ValueKey('icon'), size: 60, color: Colors.deepOrange.shade300),
            ),
          ),
        ),
        GestureDetector(
          onTap: _showAvatarOptions,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.deepOrange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                (user?.photoURL == null && _selectedImage == null)
                    ? Icons.add_a_photo
                    : Icons.edit,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
        required String label,
        required IconData icon,
        bool readOnly = false,
        TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
        prefixIcon: Icon(icon, color: Colors.white, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.white, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1)),
      ),
    );
  }

  Widget _buildPasswordTextField(TextEditingController controller, String label, bool obscureText, VoidCallback toggleVisibility) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleVisibility,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
        label: Text(
          "Change Password",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.white, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _showChangePasswordDialog,
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Cancel",
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.3),
            ),
            child: Text("Save",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

