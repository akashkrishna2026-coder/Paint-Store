import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:c_h_p/model/product_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:iconsax/iconsax.dart';

class EditProductPage extends StatefulWidget {
  final String productKey;
  final Map<String, dynamic> productData;

  const EditProductPage({
    super.key,
    required this.productKey,
    required this.productData,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  // Use a Product object to easily access data
  late Product _product;

  // Controllers for all text fields
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _stockController;
  late final TextEditingController _benefit1Controller;
  late final TextEditingController _benefit2Controller;
  late final TextEditingController _benefit3Controller;
  late final TextEditingController _price1LController;
  late final TextEditingController _price4LController;
  late final TextEditingController _price10LController;
  late final TextEditingController _price20LController;

  // File holders for new images/files
  File? _mainImageFile;
  File? _backgroundImageFile;
  File? _benefitImage1File;
  File? _benefitImage2File;
  File? _benefitImage3File;
  File? _brochureFile;
  String? _brochureFileName;

  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedBrand;

  final List<String> _brands = ['Asian Paints', 'Indigo Paints'];
  final List<String> _categories = ['Interior', 'Exterior', 'Waterproofing', 'Wood Finishes', 'Others'];
  final Map<String, List<String>> _subCategories = {
    'Interior': ['Super Luxury', 'Luxury', 'Premium', 'Economy', 'Textures', 'Wallpapers'],
    'Exterior': ['Ultima Exterior Emulsions', 'Apex Exterior Emulsions', 'Ace Exterior Emulsions', 'Exterior Textures'],
    'Waterproofing': ['Terrace & Tanks', 'Interior Waterproofing', 'Exterior Waterproofing', 'Bathroom', 'Cracks & Joints'],
    'Wood Finishes': ['General'],
    'Others': ['Brushes', 'Tools', 'Turpentine', 'Cloths'],
  };

  @override
  void initState() {
    super.initState();
    // Initialize the Product object from the passed data
    _product = Product.fromMap(widget.productKey, widget.productData);

    // Initialize all controllers with the existing product data
    _nameController = TextEditingController(text: _product.name);
    _descriptionController = TextEditingController(text: _product.description);
    _stockController = TextEditingController(text: _product.stock.toString());

    // Safely initialize benefit controllers
    _benefit1Controller = TextEditingController(text: _product.benefits.isNotEmpty ? _product.benefits[0].text : '');
    _benefit2Controller = TextEditingController(text: _product.benefits.length > 1 ? _product.benefits[1].text : '');
    _benefit3Controller = TextEditingController(text: _product.benefits.length > 2 ? _product.benefits[2].text : '');

    // Initialize pack size controllers
    _price1LController = TextEditingController(text: _product.packSizes.firstWhere((p) => p.size == '1 L', orElse: () => PackSize(size: '', price: '')).price);
    _price4LController = TextEditingController(text: _product.packSizes.firstWhere((p) => p.size == '4 L', orElse: () => PackSize(size: '', price: '')).price);
    _price10LController = TextEditingController(text: _product.packSizes.firstWhere((p) => p.size == '10 L', orElse: () => PackSize(size: '', price: '')).price);
    _price20LController = TextEditingController(text: _product.packSizes.firstWhere((p) => p.size == '20 L', orElse: () => PackSize(size: '', price: '')).price);

    // Initialize dropdowns
    _selectedBrand = _product.brand;
    _selectedCategory = _product.category;
    _selectedSubCategory = _product.subCategory;
  }

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
    super.dispose();
  }

  Future<void> _pickImage(Function(File) onImageSelected) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => onImageSelected(File(pickedFile.path)));
    }
  }

  Future<void> _pickBrochure() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() {
        _brochureFile = File(result.files.single.path!);
        _brochureFileName = result.files.single.name;
      });
    }
  }

  Future<String> _uploadFile(File file, String folder) async {
    String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    Reference storageRef = FirebaseStorage.instance.ref().child('$folder/$fileName');
    TaskSnapshot snapshot = await storageRef.putFile(file);
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);

    try {
      // Smartly upload only the files that have changed
      String mainImageUrl = _mainImageFile != null ? await _uploadFile(_mainImageFile!, 'product_images') : _product.mainImageUrl;
      String backgroundImageUrl = _backgroundImageFile != null ? await _uploadFile(_backgroundImageFile!, 'background_images') : _product.backgroundImageUrl;
      String benefit1ImageUrl = _benefitImage1File != null ? await _uploadFile(_benefitImage1File!, 'benefit_images') : _product.benefits[0].image;
      String benefit2ImageUrl = _benefitImage2File != null ? await _uploadFile(_benefitImage2File!, 'benefit_images') : _product.benefits[1].image;
      String benefit3ImageUrl = _benefitImage3File != null ? await _uploadFile(_benefitImage3File!, 'benefit_images') : _product.benefits[2].image;
      String brochureUrl = _brochureFile != null ? await _uploadFile(_brochureFile!, 'brochures') : _product.brochureUrl;

      final updatedProductData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'brand': _selectedBrand,
        'category': _selectedCategory,
        'subCategory': _selectedSubCategory,
        'mainImageUrl': mainImageUrl,
        'backgroundImageUrl': backgroundImageUrl,
        'benefits': [
          {'image': benefit1ImageUrl, 'text': _benefit1Controller.text.trim()},
          {'image': benefit2ImageUrl, 'text': _benefit2Controller.text.trim()},
          {'image': benefit3ImageUrl, 'text': _benefit3Controller.text.trim()},
        ],
        'brochureUrl': brochureUrl,
        'packSizes': {
          '1 L': _price1LController.text.trim(),
          '4 L': _price4LController.text.trim(),
          '10 L': _price10LController.text.trim(),
          '20 L': _price20LController.text.trim(),
        },
      };

      await FirebaseDatabase.instance.ref('products/${widget.productKey}').update(updatedProductData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully')));
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update product: $error')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Product", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle("Main & Background Images"),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildImagePicker("Main Image", _mainImageFile, _product.mainImageUrl, () => _pickImage((file) => setState(() => _mainImageFile = file)))),
                const SizedBox(width: 16),
                Expanded(child: _buildImagePicker("Background", _backgroundImageFile, _product.backgroundImageUrl, () => _pickImage((file) => setState(() => _backgroundImageFile = file)))),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle("Product Details"),
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3, validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stock Quantity'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 24),

            _buildSectionTitle("Pack Sizes & Prices"),
            Row(children: [
              Expanded(child: _buildPriceField(_price1LController, "Price (1 L)")),
              const SizedBox(width: 16),
              Expanded(child: _buildPriceField(_price4LController, "Price (4 L)")),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildPriceField(_price10LController, "Price (10 L)")),
              const SizedBox(width: 16),
              Expanded(child: _buildPriceField(_price20LController, "Price (20 L)")),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle("Categorization"),
            DropdownButtonFormField<String>(value: _selectedBrand, decoration: const InputDecoration(labelText: 'Brand'), items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(), onChanged: (v) => setState(() => _selectedBrand = v), validator: (v) => v == null ? 'Required' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(value: _selectedCategory, decoration: const InputDecoration(labelText: 'Category'), items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) { setState(() { _selectedCategory = v; _selectedSubCategory = null; }); }, validator: (v) => v == null ? 'Required' : null),
            if (_selectedCategory != null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(value: _selectedSubCategory, decoration: const InputDecoration(labelText: 'Sub-Category'), items: (_subCategories[_selectedCategory] ?? []).map((sc) => DropdownMenuItem(value: sc, child: Text(sc))).toList(), onChanged: (v) => setState(() => _selectedSubCategory = v), validator: (v) => v == null ? 'Required' : null),
            ],
            const SizedBox(height: 24),

            _buildSectionTitle("Product Benefits"),
            _buildBenefitEditor(1, _benefitImage1File, _product.benefits.isNotEmpty ? _product.benefits[0].image : null, (file) => setState(() => _benefitImage1File = file), _benefit1Controller),
            const SizedBox(height: 16),
            _buildBenefitEditor(2, _benefitImage2File, _product.benefits.length > 1 ? _product.benefits[1].image : null, (file) => setState(() => _benefitImage2File = file), _benefit2Controller),
            const SizedBox(height: 16),
            _buildBenefitEditor(3, _benefitImage3File, _product.benefits.length > 2 ? _product.benefits[2].image : null, (file) => setState(() => _benefitImage3File = file), _benefit3Controller),
            const SizedBox(height: 24),

            _buildSectionTitle("Product Brochure (PDF)"),
            _buildBrochurePicker(),
            const SizedBox(height: 32),

            _isUploading
                ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                : ElevatedButton.icon(
              onPressed: _updateProduct,
              icon: const Icon(Iconsax.edit),
              label: Text('Update Product', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)));

  Widget _buildImagePicker(String label, File? imageFile, String? networkImageUrl, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: imageFile != null
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(imageFile, fit: BoxFit.cover))
                : (networkImageUrl != null && networkImageUrl.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: networkImageUrl, fit: BoxFit.cover, errorWidget: (c,u,e) => const Icon(Iconsax.gallery_slash)))
                : const Center(child: Icon(Iconsax.gallery_add, size: 40, color: Colors.grey))),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitEditor(int index, File? imageFile, String? networkImageUrl, Function(File) onImageSelected, TextEditingController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _pickImage(onImageSelected),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(imageFile, fit: BoxFit.cover))
                    : (networkImageUrl != null && networkImageUrl.isNotEmpty
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: networkImageUrl, fit: BoxFit.cover, errorWidget: (c,u,e) => const Icon(Iconsax.gallery_slash)))
                    : const Center(child: Icon(Iconsax.gallery_add, color: Colors.grey))),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: controller, decoration: InputDecoration(labelText: 'Benefit #$index Description', border: const OutlineInputBorder(), alignLabelWithHint: true), maxLines: 4, validator: (v) => v!.isEmpty ? 'Required' : null)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField(TextEditingController controller, String label) => TextFormField(controller: controller, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixText: '₹'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null);

  Widget _buildBrochurePicker() {
    return InkWell(
      onTap: _pickBrochure,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
        child: Row(
          children: [
            Icon(Iconsax.document_upload, color: Colors.grey.shade700),
            const SizedBox(width: 16),
            Expanded(child: Text(
              _brochureFileName ?? (_product.brochureUrl.isNotEmpty
                  ? _product.brochureUrl.split('/').last.split('?').first.replaceAll('%2F', '/')
                  : 'Select Brochure PDF...'),
              style: GoogleFonts.poppins(),
              overflow: TextOverflow.ellipsis,
            )),
          ],
        ),
      ),
    );
  }
}