import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class EditProductPage extends StatefulWidget {
  final String? productKey;
  final Map<String, dynamic>? productData;

  // If productKey is null, it's a new product. Otherwise, we're editing.
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

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('products');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if we are editing an existing product
    _nameController = TextEditingController(text: widget.productData?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.productData?['description'] ?? '');
    _priceController = TextEditingController(text: widget.productData?['price'] ?? '');
    _networkImageUrl = widget.productData?['imageUrl'];
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    // An image is only required if we are adding a NEW product.
    if (_imageFile == null && widget.productKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl = _networkImageUrl;

      // If a new image was selected, upload it
      if (_imageFile != null) {
        String fileName = path.basename(_imageFile!.path);
        Reference storageRef = _storage.ref().child('product_images/$fileName');
        UploadTask uploadTask = storageRef.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': _priceController.text.trim(),
        'imageUrl': imageUrl,
      };

      if (widget.productKey == null) {
        // ADD new product
        await _dbRef.push().set(productData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully')));
      } else {
        // UPDATE existing product
        await _dbRef.child(widget.productKey!).update(productData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully')));
      }

      if(mounted) Navigator.pop(context);

    } catch (error) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save product: $error')));
    } finally {
      if(mounted) setState(() => _isUploading = false);
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
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : (_networkImageUrl != null
                      ? Image.network(_networkImageUrl!, fit: BoxFit.cover)
                      : const Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey))),
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
              const SizedBox(height: 32),
              _isUploading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : ElevatedButton.icon(
                onPressed: _saveProduct,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Update Product' : 'Add Product'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
