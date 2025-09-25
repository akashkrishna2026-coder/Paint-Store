// lib/product/edit_product_page.dart

import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:iconsax/iconsax.dart';

class EditProductPage extends StatefulWidget {
  final String? productKey;
  final Map<String, dynamic>? productData;

  const EditProductPage({super.key, this.productKey, this.productData});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  File? _imageFile;
  String? _networkImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? _selectedCategory;
  String? _selectedSubCategory;

  final List<String> _categories = ['Interior', 'Exterior', 'Waterproofing', 'Wood Finishes'];
  final Map<String, List<String>> _subCategories = {
    'Interior': ['Super Luxury', 'Luxury', 'Premium', 'Economy', 'Textures', 'Wallpapers'],
    'Exterior': ['Ultima Exterior Emulsions', 'Apex Exterior Emulsions', 'Ace Exterior Emulsions', 'Exterior Textures'],
    'Waterproofing': ['Terrace & Tanks', 'Interior Waterproofing', 'Exterior Waterproofing', 'Bathroom', 'Cracks & Joints'],
    'Wood Finishes': ['General'],
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productData?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.productData?['description'] ?? '');
    _priceController = TextEditingController(text: widget.productData?['price']?.toString() ?? '');
    _networkImageUrl = widget.productData?['imageUrl'];
    _selectedCategory = widget.productData?['category'];
    _selectedSubCategory = widget.productData?['subCategory'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select categories.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl = _networkImageUrl;

      if (_imageFile != null) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(_imageFile!.path)}';
        Reference storageRef = _storage.ref().child('product_images/$fileName');
        TaskSnapshot snapshot = await storageRef.putFile(_imageFile!);
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': _priceController.text.trim(),
        'imageUrl': imageUrl,
        'category': _selectedCategory,
        'subCategory': _selectedSubCategory,
      };

      if (widget.productKey == null) {
        await _dbRef.child('products').push().set(productData);
      } else {
        await _dbRef.child('products/${widget.productKey!}').update(productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product ${widget.productKey == null ? 'added' : 'updated'} successfully')));
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save product: $error')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.productKey != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Product" : "Add New Product", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.teal,
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
                      : (_networkImageUrl != null && _networkImageUrl!.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_networkImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Iconsax.gallery_slash, size: 40, color: Colors.grey)))
                      : Center(child: Icon(Iconsax.gallery_add, size: 50, color: Colors.grey.shade600))),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Product name is required.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Product Description', border: OutlineInputBorder()),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Description is required.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder(), prefixText: '₹'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value!.isEmpty ? 'Price is required.' : null,
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
                  items: _subCategories[_selectedCategory]!.map((String subCategory) {
                    return DropdownMenuItem<String>(value: subCategory, child: Text(subCategory));
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedSubCategory = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a sub-category' : null,
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                    : ElevatedButton.icon(
                  onPressed: _saveProduct,
                  icon: const Icon(Iconsax.save_21),
                  label: Text(isEditing ? 'Update Product' : 'Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}