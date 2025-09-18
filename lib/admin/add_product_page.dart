import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables for the shades dropdown
  List<String> _shadeNames = [];
  String? _selectedShadeName;
  bool _isLoadingShades = true;

  @override
  void initState() {
    super.initState();
    _fetchShadeNames();
  }

  // Method to fetch all shade names from Firebase
  Future<void> _fetchShadeNames() async {
    try {
      final snapshot = await _dbRef.child('colorCatalogue/shades').get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<String, dynamic> families = Map<String, dynamic>.from(snapshot.value as Map);
        final List<String> names = [];
        families.forEach((familyKey, shades) {
          final Map<String, dynamic> shadesMap = Map<String, dynamic>.from(shades as Map);
          shadesMap.forEach((shadeKey, shadeData) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(shadeData as Map);
            if (data['name'] != null) {
              names.add(data['name']);
            }
          });
        });
        setState(() {
          _shadeNames = names..sort(); // Sort them alphabetically
          _isLoadingShades = false;
        });
      } else {
        setState(() => _isLoadingShades = false);
      }
    } catch (e) {
      print("Error fetching shades: $e");
      setState(() => _isLoadingShades = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image for the product.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("You must be logged in.");

      final userRoleSnapshot = await _dbRef.child('users/${user.uid}/userType').get();
      final userRole = userRoleSnapshot.value as String?;

      if (user.email != 'akashkrishna389@gmail.com' && userRole != 'Admin' && userRole != 'Manager') {
        throw Exception("You do not have permission to add products.");
      }

      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(_imageFile!.path)}';
      Reference storageRef = _storage.ref().child('product_images/$fileName');
      TaskSnapshot snapshot = await storageRef.putFile(_imageFile!);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Add the selected shade name to the product data
      await _dbRef.child('products').push().set({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': _priceController.text.trim(),
        'imageUrl': downloadUrl,
        'shadeName': _selectedShadeName, // This links the product to the shade
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully')));
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add product: ${error.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Product", style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to select an image'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter a price' : null,
              ),
              const SizedBox(height: 16),
              _isLoadingShades
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                value: _selectedShadeName,
                decoration: const InputDecoration(
                  labelText: 'Color Shade (Optional)',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select a shade'),
                items: _shadeNames.map((String shadeName) {
                  return DropdownMenuItem<String>(
                    value: shadeName,
                    child: Text(shadeName),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedShadeName = newValue;
                  });
                },
              ),
              const SizedBox(height: 32),
              _isUploading
                  ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                  : ElevatedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text('Add Product', style: GoogleFonts.poppins(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                    )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}