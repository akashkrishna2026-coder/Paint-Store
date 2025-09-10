import 'dart:io';
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

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref("users");
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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
      setState(() {});
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
        await _dbRef.child(user.uid).update({
          "name": name,
          "pincode": pincode,
        });
      }

      // Upload image if selected
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("profile_pictures")
            .child("${user!.uid}.jpg");

        await ref.putFile(
          _selectedImage!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final url = await ref.getDownloadURL();
        await user.updatePhotoURL(url);
        await _dbRef.child(user.uid).update({"photoUrl": url});

        _showToast("Profile picture updated successfully");
      }

      _showToast("Changes saved successfully");
      Navigator.pop(context);
    } catch (e) {
      _showToast("Cannot upload image", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      _showToast("Cannot upload image", isError: true);
    }
  }

  Future<void> _deleteProfilePicture() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("profile_pictures/${user.uid}.jpg");

        await ref.delete();
        await user.updatePhotoURL(null);
        await _dbRef.child(user.uid).update({"photoUrl": null});

        setState(() => _selectedImage = null);

        _showToast("Profile picture deleted");
      }
    } catch (e) {
      _showToast("Cannot delete image", isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showAvatarOptions() {
    final user = _auth.currentUser;
    if (user == null) return;

    if (user.photoURL != null || _selectedImage != null) {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Picture"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Delete Picture"),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfilePicture();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    } else {
      // New user / no picture
      _pickImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(
          "Personal Info",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture with + icon if empty
            Stack(
              children: [
                GestureDetector(
                  onTap: _showAvatarOptions,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null) as ImageProvider<Object>?,
                    child: (user?.photoURL == null && _selectedImage == null)
                        ? const Icon(Icons.person,
                        size: 55, color: Colors.deepOrange)
                        : null,
                  ),
                ),
                if ((user?.photoURL == null && _selectedImage == null))
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 30),

            // Name
            _buildTextField(
              controller: _nameController,
              label: "Full Name",
              icon: Icons.person,
            ),
            const SizedBox(height: 20),

            // Email (readonly)
            _buildTextField(
              controller: _emailController,
              label: "Email",
              icon: Icons.email,
              readOnly: true,
            ),
            const SizedBox(height: 20),

            // Pincode
            _buildTextField(
              controller: _pincodeController,
              label: "Pincode",
              icon: Icons.location_on,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),

            // Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Save Changes",
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: Colors.deepOrange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Cancel",
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.deepOrange)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepOrange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
