import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import 'color_catalogue_page.dart';

class ManageColorCataloguePage extends StatefulWidget {
  const ManageColorCataloguePage({super.key});

  @override
  State<ManageColorCataloguePage> createState() => _ManageColorCataloguePageState();
}

class _ManageColorCataloguePageState extends State<ManageColorCataloguePage> with SingleTickerProviderStateMixin {
  // Form keys
  final _shadeFormKey = GlobalKey<FormState>();
  final _familyFormKey = GlobalKey<FormState>();
  final _renameFamilyFormKey = GlobalKey<FormState>(); // ⭐ NEW

  // Controllers
  final _shadeNameController = TextEditingController();
  final _shadeCodeController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _newFamilyNameController = TextEditingController(); // ⭐ NEW

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('colorCatalogue');

  // State variables
  late TabController _tabController;
  String? _selectedFamilyKey;
  String? _familyToRenameKey; // ⭐ NEW
  List<Map<String, dynamic>> _families = [];
  Color _previewColor = Colors.grey.shade300;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    // ⭐ MODIFIED: Tab length is now 3
    _tabController = TabController(length: 3, vsync: this);
    _fetchFamilies();
  }

  void _fetchFamilies() {
    _dbRef.child('families').onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final familiesData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final List<Map<String, dynamic>> loadedFamilies = [];
        familiesData.forEach((key, value) {
          if (value is Map && value.containsKey('name')) {
            loadedFamilies.add({'key': key, 'name': value['name']});
          }
        });
        setState(() {
          _families = loadedFamilies;
          if (_selectedFamilyKey == null && _families.isNotEmpty) {
            _selectedFamilyKey = _families.first['key'];
          }
          if (_familyToRenameKey == null && _families.isNotEmpty) {
            _familyToRenameKey = _families.first['key'];
          }
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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    });
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _addShade() async {
    if (_shadeFormKey.currentState!.validate()) {
      if (_selectedFamilyKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a color family.'), backgroundColor: Colors.red),
        );
        return;
      }
      try {
        final newShadeRef = _dbRef.child('shades/$_selectedFamilyKey').push();
        await newShadeRef.set({
          'name': _shadeNameController.text.trim(),
          'code': _shadeCodeController.text.trim(),
          'hexCode': _colorToHex(_previewColor),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New shade added successfully!'), backgroundColor: Colors.green),
        );
        _shadeFormKey.currentState!.reset();
        _shadeNameController.clear();
        _shadeCodeController.clear();
        setState(() {
          _imageFile = null;
          _previewColor = Colors.grey.shade300;
          if (_families.isNotEmpty) {
            _selectedFamilyKey = _families.first['key'];
          }
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add shade: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addFamily() async {
    if (_familyFormKey.currentState!.validate()) {
      try {
        final newFamilyRef = _dbRef.child('families').push();
        await newFamilyRef.set({
          'name': _familyNameController.text.trim(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New family added successfully!'), backgroundColor: Colors.green),
        );
        _familyFormKey.currentState!.reset();
        _familyNameController.clear();
        _tabController.animateTo(0);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add family: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ⭐ NEW: Function to rename a color family
  Future<void> _renameFamily() async {
    if (_renameFamilyFormKey.currentState!.validate()) {
      if (_familyToRenameKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a family to rename.'), backgroundColor: Colors.red),
        );
        return;
      }
      try {
        await _dbRef.child('families/$_familyToRenameKey').update({
          'name': _newFamilyNameController.text.trim(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family renamed successfully!'), backgroundColor: Colors.green),
        );
        _renameFamilyFormKey.currentState!.reset();
        _newFamilyNameController.clear();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename family: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    _shadeNameController.dispose();
    _shadeCodeController.dispose();
    _familyNameController.dispose();
    _newFamilyNameController.dispose(); // ⭐ NEW
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Catalogue", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        // ⭐ MODIFIED: TabBar now has 3 tabs
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Add Shade', icon: Icon(Iconsax.color_swatch)),
            Tab(text: 'Add Family', icon: Icon(Iconsax.folder_add)),
            Tab(text: 'Rename Family', icon: Icon(Iconsax.edit)), // ⭐ NEW
          ],
        ),
      ),
      // ⭐ MODIFIED: TabBarView now has 3 children
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildAddShadeForm()),
          SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildAddFamilyForm()),
          SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildRenameFamilyForm()), // ⭐ NEW
        ],
      ),
    );
  }

  Widget _buildAddShadeForm() {
    // This widget remains the same
    return Form(
      key: _shadeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_families.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedFamilyKey,
              decoration: const InputDecoration(labelText: 'Color Family', border: OutlineInputBorder()),
              items: _families.map<DropdownMenuItem<String>>((family) {
                return DropdownMenuItem<String>(
                  value: family['key'] as String,
                  child: Text(family['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() { _selectedFamilyKey = value; });
              },
            )
          else
            const Center(child: Text("Loading families...")),
          const SizedBox(height: 16),
          TextFormField(
            controller: _shadeNameController,
            decoration: const InputDecoration(labelText: 'Shade Name', border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _shadeCodeController,
            decoration: const InputDecoration(labelText: '4-Digit Code', border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty ? 'Please enter a code' : null,
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
                      color: _previewColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    ),
                  )
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text("Visual Reference Image (Optional)", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 10),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Iconsax.gallery_add),
              label: Text(_imageFile == null ? 'Upload Image' : 'Change Image'),
              onPressed: _pickImage,
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
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAddFamilyForm() {
    // This widget remains the same
    return Form(
      key: _familyFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Create a New Color Family", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _familyNameController,
            decoration: const InputDecoration(labelText: 'Family Name (e.g., Blues & Greens)', border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty ? 'Please enter a family name' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.folder_add),
              label: const Text('Add Family'),
              onPressed: _addFamily,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          )
        ],
      ),
    );
  }

  // ⭐ NEW: Widget for the "Rename Family" form
  Widget _buildRenameFamilyForm() {
    return Form(
      key: _renameFamilyFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Rename an Existing Family", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_families.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _familyToRenameKey,
              decoration: const InputDecoration(labelText: 'Select Family to Rename', border: OutlineInputBorder()),
              items: _families.map<DropdownMenuItem<String>>((family) {
                return DropdownMenuItem<String>(
                  value: family['key'] as String,
                  child: Text(family['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _familyToRenameKey = value;
                  // Pre-fill the text field with the current name
                  final selectedFamily = _families.firstWhere((f) => f['key'] == value, orElse: () => {});
                  if (selectedFamily.isNotEmpty) {
                    _newFamilyNameController.text = selectedFamily['name'];
                  }
                });
              },
            )
          else
            const Center(child: Text("No families to rename.")),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newFamilyNameController,
            decoration: const InputDecoration(labelText: 'Enter New Family Name', border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty ? 'Please enter a new name' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.edit),
              label: const Text('Rename Family'),
              onPressed: _renameFamily,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          )
        ],
      ),
    );
  }
}