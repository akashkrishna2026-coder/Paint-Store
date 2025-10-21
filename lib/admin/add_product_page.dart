import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
  // Controllers for text fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  final _benefit1Controller = TextEditingController();
  final _benefit2Controller = TextEditingController();
  final _benefit3Controller = TextEditingController();
  final _price1LController = TextEditingController();
  final _price4LController = TextEditingController();
  final _price10LController = TextEditingController();
  final _price20LController = TextEditingController();
  final _brochureUrlController = TextEditingController(); // Added for consistency if needed elsewhere

  // State for images and files
  File? _mainImageFile;
  File? _backgroundImageFile;
  File? _benefitImage1;
  File? _benefitImage2;
  File? _benefitImage3;
  File? _brochureFile; // Keep if using file picker
  String? _brochureFileName; // Keep if using file picker

  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // State for dropdowns
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedBrand;
  final List<String> _brands = ['Asian Paints', 'Indigo Paints']; // Add more brands as needed
  final List<String> _categories = ['Interior', 'Exterior', 'Waterproofing', 'Wood Finishes', 'Others'];
  final Map<String, List<String>> _subCategories = {
    'Interior': ['Super Luxury', 'Luxury', 'Premium', 'Economy', 'Textures', 'Wallpapers'],
    'Exterior': ['Ultima Exterior Emulsions', 'Apex Exterior Emulsions', 'Ace Exterior Emulsions', 'Exterior Textures'],
    'Waterproofing': ['Terrace & Tanks', 'Interior Waterproofing', 'Exterior Waterproofing', 'Bathroom', 'Cracks & Joints'],
    'Wood Finishes': ['General'], // Keep 'General' or add specifics like 'Varnish', 'Polish'
    'Others': ['Brushes', 'Tools', 'Turpentine', 'Cloths'],
  };

  // Benefit class for better organization (Optional but recommended)
  // class BenefitData { File? image; TextEditingController controller = TextEditingController(); }
  // final List<BenefitData> _benefits = List.generate(3, (_) => BenefitData());

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _benefit1Controller.dispose();
    _benefit2Controller.dispose();
    _benefit3Controller.dispose();
    _price1LController.dispose();
    _price4LController.dispose();
    _price10LController.dispose();
    _price20LController.dispose();
    _brochureUrlController.dispose();
    // Dispose benefit controllers if using BenefitData class
    // _benefits.forEach((b) => b.controller.dispose());
    super.dispose();
  }

  // Pick an image using ImagePicker
  Future<void> _pickImage(Function(File) onImageSelected) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null && mounted) { // Check mounted before setState
      setState(() => onImageSelected(File(pickedFile.path)));
    }
  }

  // Pick a PDF brochure using FilePicker
  Future<void> _pickBrochure() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && mounted) { // Check mounted
      setState(() {
        _brochureFile = File(result.files.single.path!);
        _brochureFileName = result.files.single.name;
      });
    }
  }

  // Upload a file to Firebase Storage
  Future<String> _uploadFile(File file, String folder) async {
    String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    Reference storageRef = FirebaseStorage.instance.ref().child('$folder/$fileName');
    try {
      TaskSnapshot snapshot = await storageRef.putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading file to $folder: $e");
      throw Exception("Upload failed for $fileName"); // Re-throw to signal failure
    }
  }

  // Add product data to Firebase Realtime Database
  Future<void> _addProduct() async {
    // --- Validation ---
    if (!_formKey.currentState!.validate()) {
      // Show message that validation failed
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fix the errors in the form.'), backgroundColor: Colors.orange));
      return;
    }
    // Check required images/files
    if (_mainImageFile == null || _backgroundImageFile == null || _benefitImage1 == null || _benefitImage2 == null || _benefitImage3 == null || _brochureFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select all required images and the brochure PDF.')));
      return;
    }
    // --- End Validation ---

    setState(() => _isUploading = true);
    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context); // Capture context

    try {
      // --- Upload Files Concurrently ---
      // Use Future.wait for potentially faster uploads
      final urls = await Future.wait([
        _uploadFile(_mainImageFile!, 'product_images'),       // 0
        _uploadFile(_backgroundImageFile!, 'background_images'),// 1
        _uploadFile(_benefitImage1!, 'benefit_images'),      // 2
        _uploadFile(_benefitImage2!, 'benefit_images'),      // 3
        _uploadFile(_benefitImage3!, 'benefit_images'),      // 4
        _uploadFile(_brochureFile!, 'brochures'),           // 5
      ]);

      // --- Create packSizes Map Conditionally ---
      final Map<String, String> packSizes = {};
      String price1L = _price1LController.text.trim();
      String price4L = _price4LController.text.trim();
      String price10L = _price10LController.text.trim();
      String price20L = _price20LController.text.trim();

      // Add 1L (required)
      packSizes['1 L'] = price1L; // Assumes validated as not empty/valid number

      // Add optional sizes only if a valid price was entered
      if (price4L.isNotEmpty && double.tryParse(price4L) != null) {
        packSizes['4 L'] = price4L;
      }
      if (price10L.isNotEmpty && double.tryParse(price10L) != null) {
        packSizes['10 L'] = price10L;
      }
      if (price20L.isNotEmpty && double.tryParse(price20L) != null) {
        packSizes['20 L'] = price20L;
      }
      // --- End packSizes Map ---


      // --- Prepare Data for Firebase ---
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'brand': _selectedBrand,
        'category': _selectedCategory,
        'subCategory': _selectedSubCategory,
        'mainImageUrl': urls[0],
        'backgroundImageUrl': urls[1],
        'benefits': [ // Ensure benefit text fields are trimmed
          {'image': urls[2], 'text': _benefit1Controller.text.trim()},
          {'image': urls[3], 'text': _benefit2Controller.text.trim()},
          {'image': urls[4], 'text': _benefit3Controller.text.trim()},
        ],
        'brochureUrl': urls[5],
        'packSizes': packSizes, // Use the conditionally built map
      };

      // --- Save to Firebase ---
      await _dbRef.child('products').push().set(productData);

      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Product added successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context); // Go back after success
      }
    } catch (error) {
      debugPrint("Error adding product: $error"); // Log the specific error
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Failed to add product: ${error.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar( // App Bar Styling
            expandedHeight: 200.0, // Reduced height slightly
            pinned: true,
            floating: false,
            backgroundColor: Colors.deepOrange.shade700, // Darker shade
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Add New Product", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              centerTitle: true,
              background: Container( // Simple solid color background
                  color: Colors.deepOrange.shade700
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Main & Background Images *"),
                    Row(children: [
                      Expanded(child: _buildImagePicker("Main Image *", _mainImageFile, () => _pickImage((file) => setState(() => _mainImageFile = file)))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildImagePicker("Background Image *", _backgroundImageFile, () => _pickImage((file) => setState(() => _backgroundImageFile = file)))),
                    ]),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Product Details *"),
                    TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder(), alignLabelWithHint: true), maxLines: 3, validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a description' : null),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(labelText: 'Stock Quantity *', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter stock quantity';
                          if (int.tryParse(v) == null) return 'Enter a valid number';
                          return null;
                        }),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Pack Sizes & Prices"),
                    // --- 1L Price (Required) ---
                    TextFormField(
                      controller: _price1LController,
                      decoration: const InputDecoration(labelText: '1 L Price (MRP) *', border: OutlineInputBorder(), prefixText: '₹'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Price for 1L is required';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null; // Valid
                      },
                    ),
                    const SizedBox(height: 16),
                    // --- Optional Price Fields ---
                    Row(children: [
                      Expanded(child: _buildPriceFieldOptional(_price4LController, "Price (4 L)")), // Use Optional helper
                      const SizedBox(width: 16),
                      Expanded(child: _buildPriceFieldOptional(_price10LController, "Price (10 L)")), // Use Optional helper
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _buildPriceFieldOptional(_price20LController, "Price (20 L)")), // Use Optional helper
                      const SizedBox(width: 16),
                      const Expanded(child: SizedBox()), // Placeholder for alignment
                    ]),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Categorization *"),
                    DropdownButtonFormField<String>(value: _selectedBrand, decoration: const InputDecoration(labelText: 'Brand *', border: OutlineInputBorder()), items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(), onChanged: (v) => setState(() => _selectedBrand = v), validator: (v) => v == null ? 'Please select a brand' : null),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(value: _selectedCategory, decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()), items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) { setState(() { _selectedCategory = v; _selectedSubCategory = null; }); }, validator: (v) => v == null ? 'Please select a category' : null),
                    if (_selectedCategory != null && _subCategories[_selectedCategory] != null && _subCategories[_selectedCategory]!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                          value: _selectedSubCategory,
                          decoration: const InputDecoration(labelText: 'Sub-Category *', border: OutlineInputBorder()),
                          // Filter out empty subcategories just in case
                          items: (_subCategories[_selectedCategory] ?? []).where((sc) => sc.isNotEmpty).map((sc) => DropdownMenuItem(value: sc, child: Text(sc))).toList(),
                          onChanged: (v) => setState(() => _selectedSubCategory = v),
                          validator: (v) => v == null ? 'Please select a sub-category' : null),
                    ],
                    const SizedBox(height: 24),

                    _buildSectionTitle("Product Benefits (3 Required) *"),
                    _buildBenefitEditor(1, _benefitImage1, (file) => setState(() => _benefitImage1 = file), _benefit1Controller),
                    const SizedBox(height: 16),
                    _buildBenefitEditor(2, _benefitImage2, (file) => setState(() => _benefitImage2 = file), _benefit2Controller),
                    const SizedBox(height: 16),
                    _buildBenefitEditor(3, _benefitImage3, (file) => setState(() => _benefitImage3 = file), _benefit3Controller),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Product Brochure (PDF) *"),
                    _buildBrochurePicker(),
                    const SizedBox(height: 32),

                    // --- Submit Button ---
                    _isUploading
                        ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                        : ElevatedButton.icon(
                      onPressed: _addProduct,
                      icon: const Icon(Iconsax.add),
                      label: Text('Add Product', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56), // Full width button
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for section titles
  Widget _buildSectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0), // Added top padding
      child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)));

  // Helper for image pickers
  Widget _buildImagePicker(String label, File? imageFile, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)), // Smaller font
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.grey.shade100, // Lighter background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)),
            child: imageFile != null
                ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.file(imageFile, fit: BoxFit.cover)) // Inner radius
                : Center(child: Icon(Iconsax.gallery_add, size: 40, color: Colors.grey.shade500)), // Smaller icon
          ),
        ),
      ],
    );
  }

  // Helper for benefit editors
  Widget _buildBenefitEditor(int index, File? imageFile, Function(File) onImageSelected, TextEditingController controller) {
    return Card(
      elevation: 1.5, // Subtle elevation
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _pickImage(onImageSelected),
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.file(imageFile, fit: BoxFit.cover))
                    : Center(child: Icon(Iconsax.gallery_add, color: Colors.grey.shade600)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Benefit #$index Description *',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Adjust padding
                ),
                maxLines: 4, // Max lines for description
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter benefit description' : null,
              ),
            )
          ],
        ),
      ),
    );
  }


  // Helper for OPTIONAL price fields (4L, 10L, 20L)
  Widget _buildPriceFieldOptional(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label, // No '*'
        border: const OutlineInputBorder(),
        prefixText: '₹',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        // Only validate format if a value is entered
        if (value != null && value.trim().isNotEmpty && double.tryParse(value.trim()) == null) {
          return 'Invalid number'; // Keep message short
        }
        return null; // Return null if empty or valid number
      },
    );
  }

  // Helper for brochure picker
  Widget _buildBrochurePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickBrochure,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Adjust padding
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400)),
            child: Row(
              children: [
                Icon(Iconsax.document_upload, color: Colors.grey.shade700),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                      _brochureFileName ?? 'Select Brochure PDF *', // Indicate required
                      style: GoogleFonts.poppins(color: _brochureFileName != null ? Colors.black87 : Colors.grey.shade600), // Adjust color
                      overflow: TextOverflow.ellipsis),
                ),
                if (_brochureFileName != null) // Add clear button
                  IconButton(
                    icon: Icon(Iconsax.close_circle, color: Colors.grey.shade500, size: 20),
                    onPressed: (){ setState(() { _brochureFile = null; _brochureFileName = null; }); },
                    tooltip: 'Clear selection',
                  )
              ],
            ),
          ),
        ),
        // Add a simple validator message area below (optional but good UX)
        if (_brochureFile == null) // Show a hint if nothing is selected
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 12.0),
            child: Text('Brochure PDF is required.', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          )
      ],
    );
  }
}