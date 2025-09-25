import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:iconsax/iconsax.dart';

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
  final _stockController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedBrand;

  final List<String> _brands = ['Asian Paints', 'Indigo Paints'];
  final List<String> _categories = ['Interior', 'Exterior', 'Waterproofing', 'Wood Finishes', 'Others'];

  // ⭐ UPDATED: "Super Luxury" is now a selectable sub-category for "Interior"
  final Map<String, List<String>> _subCategories = {
    'Interior': ['Super Luxury', 'Luxury', 'Premium', 'Economy', 'Textures', 'Wallpapers'],
    'Exterior': ['Ultima Exterior Emulsions', 'Apex Exterior Emulsions', 'Ace Exterior Emulsions', 'Exterior Textures'],
    'Waterproofing': ['Terrace & Tanks', 'Interior Waterproofing', 'Exterior Waterproofing', 'Bathroom', 'Cracks & Joints'],
    'Wood Finishes': ['General'],
    'Others': ['Brushes', 'Tools', 'Turpentine', 'Cloths'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a product image.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("You must be logged in.");

      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(_imageFile!.path)}';
      Reference storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName');
      TaskSnapshot snapshot = await storageRef.putFile(_imageFile!);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _dbRef.child('products').push().set({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': _priceController.text.trim(),
        'imageUrl': downloadUrl,
        'category': _selectedCategory,
        'subCategory': _selectedSubCategory,
        'brand': _selectedBrand,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully')));
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add product: $error')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Product", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
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
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : Center(child: Icon(Iconsax.gallery_add, size: 50, color: Colors.grey.shade600)),
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
                decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder(), prefixText: '₹'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter a price' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value!.isEmpty ? 'Please enter stock quantity' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBrand,
                decoration: const InputDecoration(labelText: 'Brand', border: OutlineInputBorder()),
                hint: const Text('Select Brand'),
                items: _brands.map((String brand) {
                  return DropdownMenuItem<String>(value: brand, child: Text(brand));
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedBrand = newValue),
                validator: (value) => value == null ? 'Please select a brand' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                hint: const Text('Select Category'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(value: category, child: Text(category));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                    _selectedSubCategory = null;
                  });
                },
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedCategory != null)
                DropdownButtonFormField<String>(
                  value: _selectedSubCategory,
                  decoration: const InputDecoration(labelText: 'Sub-Category', border: OutlineInputBorder()),
                  hint: const Text('Select Sub-Category'),
                  items: (_subCategories[_selectedCategory] ?? []).map((String subCategory) {
                    return DropdownMenuItem<String>(value: subCategory, child: Text(subCategory));
                  }).toList(),
                  onChanged: (newValue) => setState(() => _selectedSubCategory = newValue),
                  validator: (value) => value == null ? 'Please select a sub-category' : null,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}