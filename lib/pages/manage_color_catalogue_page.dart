// lib/pages/manage_color_catalogue_page.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ManageColorCataloguePage extends StatefulWidget {
  const ManageColorCataloguePage({super.key});

  @override
  State<ManageColorCataloguePage> createState() =>
      _ManageColorCataloguePageState();
}

class _ManageColorCataloguePageState extends State<ManageColorCataloguePage>
    with SingleTickerProviderStateMixin {
  final _shadeFormKey = GlobalKey<FormState>();
  final _categoryFormKey = GlobalKey<FormState>();
  final _renameCategoryFormKey = GlobalKey<FormState>();

  final _shadeNameController = TextEditingController();
  final _shadeCodeController = TextEditingController();
  final _categoryNameController = TextEditingController();
  final _newCategoryNameController = TextEditingController();

  // ⭐ FIX: Corrected database reference to the proper path.
  // This was pointing to 'colorCategories/colorCategories' before.
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref('colorCategories');

  late TabController _tabController;
  String? _selectedCategoryKey;
  String? _categoryToRenameKey;
  List<String> _categories = [];
  Color _previewColor = Colors.grey.shade300;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCategories();
  }

  void _fetchCategories() {
    _dbRef.onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final categoriesData =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        final List<String> loadedCategories = categoriesData.keys.toList();

        setState(() {
          _categories = loadedCategories;
          if (_selectedCategoryKey == null ||
              !_categories.contains(_selectedCategoryKey)) {
            _selectedCategoryKey =
                _categories.isNotEmpty ? _categories.first : null;
          }
          if (_categoryToRenameKey == null ||
              !_categories.contains(_categoryToRenameKey)) {
            _categoryToRenameKey =
                _categories.isNotEmpty ? _categories.first : null;
          }
        });
      } else {
        setState(() {
          _categories = [];
          _selectedCategoryKey = null;
          _categoryToRenameKey = null;
        });
      }
    });
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _previewColor,
              onColorChanged: (color) {
                setState(() {
                  _previewColor = color;
                });
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  String _colorToHex(Color color) {
    final argb = color.toARGB32();
    final rgb = argb & 0x00FFFFFF;
    final hex = rgb.toRadixString(16).padLeft(6, '0').toUpperCase();
    return '#$hex';
  }

  Future<void> _addShade() async {
    if (_shadeFormKey.currentState!.validate()) {
      if (_selectedCategoryKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a color category.'),
              backgroundColor: Colors.red),
        );
        return;
      }
      try {
        final shadeCode = _shadeCodeController.text.trim();

        await _dbRef.child('${_selectedCategoryKey!}/$shadeCode').set({
          'name': _shadeNameController.text.trim(),
          'hex': _colorToHex(_previewColor),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('New shade added successfully!'),
              backgroundColor: Colors.green),
        );
        _shadeFormKey.currentState!.reset();
        _shadeNameController.clear();
        _shadeCodeController.clear();
        setState(() {
          _previewColor = Colors.grey.shade300;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add shade: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addCategory() async {
    if (_categoryFormKey.currentState!.validate()) {
      try {
        final newCategoryName = _categoryNameController.text
            .trim()
            .toLowerCase()
            .replaceAll(' ', '');
        await _dbRef.child(newCategoryName).set({});

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('New category added successfully!'),
              backgroundColor: Colors.green),
        );
        _categoryFormKey.currentState!.reset();
        _categoryNameController.clear();
        _tabController.animateTo(0);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add category: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _renameCategory() async {
    if (_renameCategoryFormKey.currentState!.validate()) {
      if (_categoryToRenameKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a category to rename.'),
              backgroundColor: Colors.red),
        );
        return;
      }
      try {
        final oldCategoryKey = _categoryToRenameKey!;
        final newCategoryKey = _newCategoryNameController.text
            .trim()
            .toLowerCase()
            .replaceAll(' ', '');

        final oldSnap = await _dbRef.child(oldCategoryKey).get();
        if (oldSnap.exists && oldSnap.value is Map) {
          final map = Map<String, dynamic>.from(oldSnap.value as Map);
          await _dbRef.child(newCategoryKey).set(map);
        } else {
          await _dbRef.child(newCategoryKey).set({});
        }
        await _dbRef.child(oldCategoryKey).remove();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Category renamed successfully!'),
              backgroundColor: Colors.green),
        );
        _renameCategoryFormKey.currentState!.reset();
        _newCategoryNameController.clear();
        setState(() {
          _categoryToRenameKey = newCategoryKey;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to rename category: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shadeNameController.dispose();
    _shadeCodeController.dispose();
    _categoryNameController.dispose();
    _newCategoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Catalogue",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Add Shade', icon: Icon(Iconsax.color_swatch)),
            Tab(text: 'Add Category', icon: Icon(Iconsax.folder_add)),
            Tab(text: 'Rename Category', icon: Icon(Iconsax.edit)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
              padding: const EdgeInsets.all(16.0), child: _buildAddShadeForm()),
          SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildAddCategoryForm()),
          SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildRenameCategoryForm()),
        ],
      ),
    );
  }

  Widget _buildAddShadeForm() {
    return Form(
      key: _shadeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_categories.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedCategoryKey,
              decoration: const InputDecoration(
                  labelText: 'Color Category', border: OutlineInputBorder()),
              items: _categories.map<DropdownMenuItem<String>>((categoryName) {
                return DropdownMenuItem<String>(
                  value: categoryName,
                  child: Text(categoryName[0].toUpperCase() +
                      categoryName.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryKey = value;
                });
              },
            )
          else
            const Center(
                child:
                    Text("No categories found. Please add a category first.")),
          const SizedBox(height: 16),
          TextFormField(
            controller: _shadeNameController,
            decoration: const InputDecoration(
                labelText: 'Shade Name', border: OutlineInputBorder()),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _shadeCodeController,
            decoration: const InputDecoration(
                labelText: 'Shade Code (e.g., 8029, K261)',
                border: OutlineInputBorder()),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter a code' : null,
          ),
          const SizedBox(height: 16),
          const Text("Selected Color"),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showColorPicker,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: _previewColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Center(
                  child: Text(
                'Tap to pick a color',
                style: GoogleFonts.poppins(
                  color: _previewColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                ),
              )),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.add),
              label: const Text('Add Shade'),
              onPressed: _addShade,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAddCategoryForm() {
    return Form(
      key: _categoryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Create a New Color Category",
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _categoryNameController,
            decoration: const InputDecoration(
                labelText: 'Category Name (e.g., Reds)',
                border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter a category name'
                : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.folder_add),
              label: const Text('Add Category'),
              onPressed: _addCategory,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRenameCategoryForm() {
    return Form(
      key: _renameCategoryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Rename an Existing Category",
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_categories.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _categoryToRenameKey,
              decoration: const InputDecoration(
                  labelText: 'Select Category to Rename',
                  border: OutlineInputBorder()),
              items: _categories.map<DropdownMenuItem<String>>((categoryName) {
                return DropdownMenuItem<String>(
                  value: categoryName,
                  child: Text(categoryName[0].toUpperCase() +
                      categoryName.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _categoryToRenameKey = value;
                  _newCategoryNameController.text = value ?? '';
                });
              },
            )
          else
            const Center(child: Text("No categories to rename.")),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newCategoryNameController,
            decoration: const InputDecoration(
                labelText: 'Enter New Category Name',
                border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter a new name'
                : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.edit),
              label: const Text('Rename Category'),
              onPressed: _renameCategory,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          )
        ],
      ),
    );
  }
}
