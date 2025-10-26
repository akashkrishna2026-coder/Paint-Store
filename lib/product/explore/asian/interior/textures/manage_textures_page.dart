import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart'; // For generating unique combination IDs

// --- Color Helper ---
// Converts hex color strings (#RRGGBB or #AARRGGBB) to Flutter Color.
Color hexToColor(String code) {
  try {
    final hex = code.replaceAll('#', '');
    if (hex.length == 6) { // RGB
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) { // ARGB
      return Color(int.parse(hex, radix: 16));
    }
    return Colors.grey.shade300; // Fallback
  } catch (e) {
    debugPrint("Error converting hex '$code': $e");
    return Colors.grey.shade300; // Fallback on error
  }
}

// --- Data Structure for Editing Combinations ---
// Holds combination data temporarily while editing in the form/dialog.
class CombinationEditData {
  String id;
  File? imageFile; // New image picked by user
  String? networkImageUrl; // Existing image URL from Firebase
  List<Map<String, String>> colors; // List like {"role": "Top", "code": "1234", "name": "Sky Blue"}

  CombinationEditData({
    required this.id,
    this.imageFile,
    this.networkImageUrl,
    required this.colors,
  });

  // Converts to a Map for saving to Firebase. Requires the final image URL.
  Map<String, dynamic> toJson(String finalImageUrl) {
    return {
      'id': id,
      'imageUrl': finalImageUrl,
      'colors': colors,
    };
  }

  // Creates an instance from Firebase data Map.
  factory CombinationEditData.fromJson(Map<String, dynamic> json) {
    return CombinationEditData(
      id: json['id'] ?? Uuid().v4(), // Use existing ID or generate new
      networkImageUrl: json['imageUrl'],
      // Safely parse the colors list
      colors: (json['colors'] as List<dynamic>?)
          ?.whereType<Map>() // Ensure elements are Maps
          .map((colorData) => Map<String, String>.from(colorData.cast<String, String>())) // Cast inner map safely
          .toList() ??
          [], // Default to empty list
    );
  }
}

// --- Main Page Widget ---
// Manages the overall state (showing list or form)
class ManageTexturesPage extends StatefulWidget {
  const ManageTexturesPage({super.key});
  @override
  State<ManageTexturesPage> createState() => _ManageTexturesPageState();
}

class _ManageTexturesPageState extends State<ManageTexturesPage> {
  bool _isFormVisible = false; // Controls whether the list or the form is shown
  String? _editingKey; // Holds the Firebase key of the texture being edited (null if adding)
  Map<String, dynamic>? _initialData; // Holds the data of the texture being edited

  // Shows the form, optionally pre-filled with data for editing
  void _showForm({String? key, Map<String, dynamic>? data}) {
    setState(() {
      _isFormVisible = true;
      _editingKey = key;
      _initialData = data;
    });
  }

  // Hides the form and returns to the list view
  void _hideForm() {
    setState(() {
      _isFormVisible = false;
      _editingKey = null;
      _initialData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isFormVisible ? Colors.white : Colors.grey.shade100, // Different background for form vs. list
      appBar: AppBar(
        title: Text(
            _isFormVisible
                ? (_editingKey == null ? "Add New Texture" : "Edit Texture") // Dynamic title
                : "Manage Textures",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: _isFormVisible ? 1 : 0, // Show elevation only when form is visible
        // Animate between the back button (for list) and close button (for form)
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: _isFormVisible
              ? IconButton(
            key: const ValueKey('close_button'), // Key helps animation identify the widget
            icon: Icon(Iconsax.close_circle, color: Colors.grey.shade800),
            onPressed: _hideForm, // Close button hides the form
            tooltip: 'Close Form',
          )
              : Navigator.canPop(context)
              ? BackButton(key: const ValueKey('back_button'), color: Colors.grey.shade800)
              : null, // Show back button if possible
        ),
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      // Animate the transition between the list and the form views
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child), // Fade animation
        child: _isFormVisible
            ? _TextureForm(
          key: ValueKey(_editingKey ?? 'add_texture'), // Unique key for state management
          textureKey: _editingKey,
          initialData: _initialData,
          onSave: _hideForm, // Callback to hide the form when saved
        )
            : _TextureList(
          key: const ValueKey('texture_list'), // Unique key
          onEdit: (key, data) => _showForm(key: key, data: data), // Callback to show form for editing
        ),
      ),
      // Show Floating Action Button only when the list is visible
      floatingActionButton: !_isFormVisible
          ? FloatingActionButton.extended(
        onPressed: () => _showForm(), // Show form for adding a new texture
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: Text("Add Texture", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ).animate().scale(delay: 100.ms) // Add a slight animation to the FAB
          : null, // Hide FAB when form is visible
    );
  }
}

// --- WIDGET FOR DISPLAYING THE TEXTURE LIST ---
class _TextureList extends StatelessWidget {
  final Function(String, Map<String, dynamic>) onEdit; // Callback when edit button is tapped
  final DatabaseReference _texturesRef = FirebaseDatabase.instance.ref('textures');
  final TextEditingController _searchController = TextEditingController();
  // Use ValueNotifier for efficient search updates without rebuilding the whole StreamBuilder
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');

  _TextureList({super.key, required this.onEdit});

  // Shows a confirmation dialog before deleting a texture
  void _showDeleteDialog(BuildContext context, String key, String name, String? imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Deletion'),
        content: Text('Delete "$name"? Associated images will also be removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async { // Make async for storage deletion
              Navigator.of(ctx).pop(); // Close dialog first
              ScaffoldMessengerState messenger = ScaffoldMessenger.of(context); // Capture scaffold messenger
              try {
                // Fetch final data to get combination URLs before deleting RTDB entry
                final textureSnapshot = await _texturesRef.child(key).get();
                List<String> combinationImageUrls = [];
                if (textureSnapshot.exists && textureSnapshot.value is Map) {
                  final data = Map<String, dynamic>.from(textureSnapshot.value as Map);
                  if (data['combinations'] is List) {
                    combinationImageUrls = (data['combinations'] as List)
                        .whereType<Map>()
                        .map((combo) => combo['imageUrl'] as String?)
                        .where((url) => url != null && url.isNotEmpty)
                        .cast<String>()
                        .toList();
                  }
                }

                // 1. Delete from Realtime Database
                await _texturesRef.child(key).remove();

                // 2. Attempt to delete main image from Storage
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  try {
                    await FirebaseStorage.instance.refFromURL(imageUrl).delete();
                  } catch (e) {
                    debugPrint("Error deleting main storage file $imageUrl: $e");
                  }
                }
                // 3. Attempt to delete combination images from Storage
                for (String comboUrl in combinationImageUrls) {
                  try {
                    await FirebaseStorage.instance.refFromURL(comboUrl).delete();
                  } catch (e) {
                    debugPrint("Error deleting combo storage file $comboUrl: $e");
                  }
                }

                messenger.showSnackBar(SnackBar(content: Text('"$name" deleted.'), backgroundColor: Colors.red));

              } catch (dbError) {
                messenger.showSnackBar(SnackBar(content: Text('Failed to delete "$name": $dbError'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Search Bar ---
        Padding(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by texture name...',
              prefixIcon: const Icon(Iconsax.search_normal_1, size: 20, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) => _searchQueryNotifier.value = value.toLowerCase(),
          ),
        ),
        // --- Texture List using StreamBuilder ---
        Expanded(
          child: StreamBuilder(
            stream: _texturesRef.orderByChild('name').onValue, // Listen to changes ordered by name
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              // Loading State
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
              }
              // Error State
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              // No Data State
              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return const Center(child: Text("No textures found. Tap '+' to add one!"));
              }

              // Data Received: Process and display
              final texturesMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
              final texturesList = texturesMap.entries.map((e) {
                final valueMap = e.value is Map ? Map<String, dynamic>.from(e.value) : <String, dynamic>{};
                return {'key': e.key, ...valueMap};
              }).toList();
              texturesList.sort((a, b) => (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase()));

              // Filter the list based on the search query using ValueListenableBuilder
              return ValueListenableBuilder<String>(
                  valueListenable: _searchQueryNotifier, // Listen to search changes
                  builder: (context, searchQuery, _) {
                    final filteredList = texturesList.where((texture) {
                      final name = (texture['name'] as String? ?? '').toLowerCase();
                      return name.contains(searchQuery);
                    }).toList();

                    // No Results State
                    if (filteredList.isEmpty) {
                      return Center(child: Text(searchQuery.isEmpty ? "No textures added yet." : "No textures match '$searchQuery'.", style: TextStyle(color: Colors.grey.shade600)));
                    }

                    // Display Filtered List
                    return ListView.builder(
                      key: const PageStorageKey('texture_list_view'), // Added key
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Padding includes space for FAB
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final texture = filteredList[index];
                        final key = texture['key'] as String?; // Safely cast
                        final data = Map<String, dynamic>.from(texture)..remove('key');
                        if (key == null) return const SizedBox.shrink(); // Skip if key is missing

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1.5,
                          shadowColor: Colors.black.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: data['imageUrl'] ?? '', // Main image URL
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                                placeholder: (c, u) => Container(width: 55, height: 55, color: Colors.grey.shade200),
                                errorWidget: (c, u, e) => Container(width: 55, height: 55, color: Colors.grey.shade100, child: const Icon(Iconsax.gallery_slash)),
                              ),
                            ),
                            title: Text(data['name'] ?? 'No Name', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            subtitle: Text("${data['category'] ?? 'N/A'}"), // Removed Color Family
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Iconsax.edit, color: Colors.blueAccent[700], size: 22),
                                  onPressed: () => onEdit(key, data), // Pass full data map
                                  tooltip: 'Edit',
                                  splashRadius: 20,
                                ),
                                IconButton(
                                  icon: Icon(Iconsax.trash, color: Colors.redAccent[700], size: 22),
                                  onPressed: () => _showDeleteDialog(context, key, data['name'] ?? 'this texture', data['imageUrl']), // Pass image URL
                                  tooltip: 'Delete',
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 40).ms, duration: 250.ms); // Animate list items
                      },
                    );
                  });
            },
          ),
        ),
      ],
    );
  }
}


// --- WIDGET FOR THE ADD/EDIT FORM ---
class _TextureForm extends StatefulWidget {
  final String? textureKey;
  final Map<String, dynamic>? initialData;
  final VoidCallback onSave;
  const _TextureForm({super.key, this.textureKey, this.initialData, required this.onSave});
  @override
  State<_TextureForm> createState() => _TextureFormState();
}

class _TextureFormState extends State<_TextureForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _selectedCategory;
  File? _mainImageFile;
  String? _networkMainImageUrl;
  bool _isUploading = false;
  bool _isLoadingColors = true;
  bool _isLoadingProducts = true;
  List<CombinationEditData> _currentCombinations = [];
  List<Map<String, dynamic>> _availableColors = [];
  List<Map<String, dynamic>> _availableProducts = [];
  List<String> _selectedProductKeys = [];
  final List<String> _categories = ['Interior', 'Exterior'];

  // Map to hold controllers for combination roles, disposed correctly
  final Map<String, Map<String, TextEditingController>> _combinationRoleControllers = {}; // {comboId: {colorCode: controller}}

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialData?['description'] ?? '');
    _selectedCategory = widget.initialData?['category'];
    _networkMainImageUrl = widget.initialData?['imageUrl'];

    if (widget.initialData?['combinations'] is List) {
      _currentCombinations = (widget.initialData!['combinations'] as List).whereType<Map>().map((comboData) {
        final combo = CombinationEditData.fromJson(Map<String, dynamic>.from(comboData));
        _combinationRoleControllers[combo.id] = {}; // Initialize inner map
        for (var colorMap in combo.colors) {
          if (colorMap['code'] != null) { // Add null check for code
            _combinationRoleControllers[combo.id]![colorMap['code']!] = TextEditingController(text: colorMap['role'] ?? '');
          }
        }
        return combo;
      }).toList();
    } else { _currentCombinations = []; }

    if (widget.initialData?['productsUsed'] is List) { _selectedProductKeys = (widget.initialData!['productsUsed'] as List).whereType<String>().toList(); }
    else { _selectedProductKeys = []; }

    _fetchColorCatalogue();
    _fetchAvailableProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    // Dispose all dynamically created role controllers
    for (var controllerMap in _combinationRoleControllers.values) {
      for (var controller in controllerMap.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _fetchColorCatalogue() async {
    if (!mounted) return;
    setState(() => _isLoadingColors = true);
    try {
      final snapshot = await FirebaseDatabase.instance.ref('colorCategories').get();
      if (!mounted) return;
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final List<Map<String, dynamic>> colors = [];
        data.forEach((categoryKey, shadesData) {
          if (shadesData is Map) {
            shadesData.forEach((shadeCode, shadeDetails) {
              if (shadeDetails is Map) {
                colors.add({ 'code': shadeCode, 'name': shadeDetails['name']?.toString() ?? 'Unnamed', 'hex': shadeDetails['hex']?.toString() ?? '#FFFFFF' });
              }
            });
          }
        });
        colors.sort((a,b) => (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase()));
        if (mounted) setState(() { _availableColors = colors; _isLoadingColors = false; });
      } else { if (mounted) setState(() => _isLoadingColors = false); }
    } catch (e) { debugPrint("Error fetching color catalogue: $e"); if (mounted) setState(() => _isLoadingColors = false); }
  }

  Future<void> _fetchAvailableProducts() async {
    if (!mounted) return;
    setState(() => _isLoadingProducts = true);
    try {
      final snapshot = await FirebaseDatabase.instance.ref('products').orderByChild('name').get();
      if (!mounted) return;
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final List<Map<String, dynamic>> products = [];
        data.forEach((key, value) { if (value is Map) { products.add({'key': key, 'name': value['name']?.toString() ?? 'Unnamed'}); } });
        products.sort((a,b) => (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase()));
        if (mounted) setState(() { _availableProducts = products; _isLoadingProducts = false; });
      } else { if (mounted) setState(() => _isLoadingProducts = false); }
    } catch (e) { debugPrint("Error fetching products: $e"); if (mounted) setState(() => _isLoadingProducts = false); }
  }

  Future<void> _pickMainImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null && mounted) { setState(() => _mainImageFile = File(pickedFile.path)); }
  }

  Future<String> _uploadFile(File file, String folderPath) async {
    String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    Reference storageRef = FirebaseStorage.instance.ref().child('$folderPath/$fileName');
    try {
      await storageRef.putFile(file);
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) { throw Exception("File upload failed: $e"); }
  }

  Map<String, String>? _getColorDetails(String code) {
    try {
      final colorData = _availableColors.firstWhere((c) => c['code'] == code);
      return {
        'code': code,
        'name': colorData['name'] as String? ?? 'No Name',
        'hex': colorData['hex'] as String? ?? '#FFFFFF',
      };
    } catch (e) {
      debugPrint("Color code $code not found in available list.");
      return null;
    }
  }

  Future<void> _saveTexture() async {
    if (!_formKey.currentState!.validate()) return;

    // --- FIXED: Show error if no main image ---
    if (_mainImageFile == null && _networkMainImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a main image for the texture.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      String finalMainImageUrl = _networkMainImageUrl ?? '';
      List<String> oldMainImageToDelete = [];
      if (_mainImageFile != null) { if(_networkMainImageUrl != null && _networkMainImageUrl!.isNotEmpty) { oldMainImageToDelete.add(_networkMainImageUrl!); } finalMainImageUrl = await _uploadFile(_mainImageFile!, 'textures/main'); }

      List<Map<String, dynamic>> finalCombinationsData = [];
      List<Future<void>> uploadFutures = []; // Changed to Future<void>
      List<String> oldComboImagesToDelete = [];
      List<String> initialComboIds = widget.initialData?['combinations'] is List ? (widget.initialData!['combinations'] as List).whereType<Map>().map((c) => c['id'] as String? ?? '').where((id)=> id.isNotEmpty).toList() : [];
      List<String> currentComboIds = _currentCombinations.map((c) => c.id).toList();
      List<String> removedComboIds = initialComboIds.where((id) => !currentComboIds.contains(id)).toList();
      if (widget.initialData?['combinations'] is List) { (widget.initialData!['combinations'] as List).whereType<Map>().forEach((comboData) { if (removedComboIds.contains(comboData['id']?.toString() ?? '') && comboData['imageUrl'] != null && comboData['imageUrl'].isNotEmpty) { oldComboImagesToDelete.add(comboData['imageUrl']); } }); }

      for (var i = 0; i < _currentCombinations.length; i++) { // Use index for safe modification
        var combo = _currentCombinations[i];
        String comboImageUrl = combo.networkImageUrl ?? '';
        bool needsUpload = combo.imageFile != null;

        // Read roles from controllers right before creating JSON
        List<Map<String, String>> updatedColors = combo.colors.map((cMap) {
          String? code = cMap['code'];
          String role = '';
          if (code != null && _combinationRoleControllers[combo.id]?[code] != null) {
            role = _combinationRoleControllers[combo.id]![code]!.text.trim();
          }
          return {
            "role": role,
            "code": code ?? '', // Ensure code is not null
            "name": cMap['name'] ?? '', // Ensure name is not null
          };
        }).toList();
        // Update the combo object's colors in the main list
        _currentCombinations[i].colors = updatedColors;
        combo = _currentCombinations[i]; // Re-assign combo after update


        if (needsUpload) {
          if (widget.textureKey != null && combo.networkImageUrl != null && combo.networkImageUrl!.isNotEmpty) { oldComboImagesToDelete.add(combo.networkImageUrl!); }
          // Add upload task
          uploadFutures.add(
              _uploadFile(combo.imageFile!, 'textures/combinations').then((url) {
                // Add data using the final URL, using the updated combo object
                finalCombinationsData.add(combo.toJson(url));
              }).catchError((e) { debugPrint("Error uploading combo image ${combo.id}: $e"); })
          );
        } else if (comboImageUrl.isNotEmpty) {
          // If no new image, add data with existing URL and updated colors
          finalCombinationsData.add(combo.toJson(comboImageUrl));
        }
      }
      await Future.wait(uploadFutures);

      // Sort final data based on the possibly updated _currentCombinations order
      finalCombinationsData.sort((a,b) {
        int indexA = _currentCombinations.indexWhere((c) => c.id == a['id']);
        int indexB = _currentCombinations.indexWhere((c) => c.id == b['id']);
        return indexA.compareTo(indexB);
      });

      final textureData = {
        'name': _nameController.text.trim(), 'description': _descriptionController.text.trim(), 'category': _selectedCategory,
        'imageUrl': finalMainImageUrl, 'combinations': finalCombinationsData, 'productsUsed': _selectedProductKeys,
      };

      // Save to RTDB
      final dbRef = FirebaseDatabase.instance.ref('textures');
      if (widget.textureKey == null) { await dbRef.push().set(textureData); }
      else { await dbRef.child(widget.textureKey!).update(textureData); }

      // Delete old images from Storage
      for (String urlToDelete in oldMainImageToDelete) { try { await FirebaseStorage.instance.refFromURL(urlToDelete).delete(); } catch (e) { debugPrint("Error deleting old main image: $e"); } }
      for (String urlToDelete in oldComboImagesToDelete) { try { await FirebaseStorage.instance.refFromURL(urlToDelete).delete(); } catch (e) { debugPrint("Error deleting old combo image: $e"); } }

      // --- FIXED: Replaced /* Success */ with a real SnackBar ---
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Texture saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSave();
      }

    } catch (e) {
      // --- FIXED: Replaced /* Error */ with a real SnackBar ---
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error saving texture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    finally { if (mounted) setState(() => _isUploading = false); }
  }


  // --- Combination Management UI ---
  void _showAddEditCombinationDialog({CombinationEditData? existingCombination}) {
    File? dialogImageFile = existingCombination?.imageFile;
    String? dialogNetworkImageUrl = existingCombination?.networkImageUrl;
    final GlobalKey<FormState> sheetFormKey = GlobalKey<FormState>();
    Map<String, TextEditingController> dialogRoleControllers = {}; // Local map for this dialog instance
    List<Map<String, String>> dialogSelectedColors = List.from(existingCombination?.colors ?? []);
    String tempComboId = existingCombination?.id ?? Uuid().v4(); // Use existing or temp ID

    // Populate local controllers based on dialogSelectedColors
    for (var colorMap in dialogSelectedColors) {
      if (colorMap['code'] != null) {
        dialogRoleControllers[colorMap['code']!] = TextEditingController(text: colorMap['role'] ?? '');
      }
    }


    showModalBottomSheet(
        context: context, isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return StatefulBuilder(
              builder: (BuildContext sheetContext, StateSetter setSheetState) { // Use sheetContext
                Future<void> pickCombinationImage() async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 60);
                  if (picked != null) { setSheetState(() { dialogImageFile = File(picked.path); dialogNetworkImageUrl = null; }); }
                }

                void showInnerColorPicker() {
                  if (_isLoadingColors) return;
                  // --- FIXED: Show SnackBar if colors are empty ---
                  if (_availableColors.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Color catalogue is still loading or is empty.')),
                    );
                    return;
                  }

                  List<String> currentCodesInDialog = dialogSelectedColors.map((c) => c['code']!).toList();
                  TextEditingController searchController = TextEditingController();
                  String innerSearchQuery = '';

                  showDialog(
                      context: ctx, // Use sheet context for dialog
                      builder: (dCtx) => StatefulBuilder(
                          builder: (dialogContext, setInnerDialogState) {

                            // --- FIXED: Implemented search filter logic ---
                            final filteredAvailableColors = _availableColors.where((color) {
                              final name = (color['name'] as String? ?? '').toLowerCase();
                              return name.contains(innerSearchQuery);
                            }).toList();

                            return AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text("Select Colors"),
                              // --- FIXED: Replaced /* ... */ with full UI ---
                              content: SizedBox(
                                width: double.maxFinite,
                                height: MediaQuery.of(context).size.height * 0.5, // Constrain height
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Search Bar
                                    TextField(
                                      controller: searchController,
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        hintText: 'Search colors...',
                                        prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                      onChanged: (value) {
                                        setInnerDialogState(() {
                                          innerSearchQuery = value.toLowerCase();
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    // List of Colors
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: filteredAvailableColors.length,
                                        itemBuilder: (liCtx, index) {
                                          final color = filteredAvailableColors[index];
                                          final code = color['code'] as String? ?? '';
                                          final name = color['name'] as String? ?? 'No Name';
                                          final hex = color['hex'] as String? ?? '#CCCCCC';
                                          final bool isSelected = currentCodesInDialog.contains(code);

                                          return CheckboxListTile(
                                            title: Text(name),
                                            subtitle: Text(code),
                                            controlAffinity: ListTileControlAffinity.leading,
                                            secondary: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: hexToColor(hex),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                            ),
                                            value: isSelected,
                                            onChanged: (bool? value) {
                                              setInnerDialogState(() {
                                                if (value == true) {
                                                  currentCodesInDialog.add(code);
                                                } else {
                                                  currentCodesInDialog.remove(code);
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text("Cancel")),
                                ElevatedButton(
                                    onPressed: () {
                                      setSheetState(() { // Update SHEET state
                                        List<String> codesToRemove = [];
                                        // Find colors to remove
                                        for (var c in dialogSelectedColors) {
                                          if (!currentCodesInDialog.contains(c['code'])) {
                                            codesToRemove.add(c['code']!);
                                          }
                                        }
                                        // Remove them and their controllers
                                        for (var code in codesToRemove) {
                                          dialogSelectedColors.removeWhere((c) => c['code'] == code);
                                          // Dispose ONLY the controller from the *dialog* map
                                          dialogRoleControllers[code]?.dispose();
                                          dialogRoleControllers.remove(code);
                                        }

                                        // Add new colors
                                        for (String newCode in currentCodesInDialog) {
                                          if (!dialogSelectedColors.any((c) => c['code'] == newCode)) {
                                            final details = _getColorDetails(newCode); // Use helper
                                            if (details != null) {
                                              dialogSelectedColors.add({"role": "", "code": newCode, "name": details['name'] ?? ''});
                                              // Add new controller to DIALOG map
                                              dialogRoleControllers[newCode] = TextEditingController();
                                            }
                                          }
                                        }
                                        // --- FIXED: Completed the sort function ---
                                        dialogSelectedColors.sort((a,b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
                                      });
                                      Navigator.pop(dCtx); // Close inner dialog
                                    },
                                    child: const Text("Confirm")
                                )
                              ],
                            );
                          }
                      )
                  );
                } // End of showInnerColorPicker

                // --- Bottom Sheet UI ---
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  child: Form(
                    key: sheetFormKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Header ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                existingCombination == null ? 'Add Combination' : 'Edit Combination',
                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                        IconButton(
                          icon: const Icon(Iconsax.close_circle),
                          onPressed: () {
                            // Pop the dialog FIRST
                            Navigator.pop(ctx);

                            // Dispose the controllers *after* the pop animation
                            Future.delayed(const Duration(milliseconds: 300), () {
                              for (var c in dialogRoleControllers.values) {
                                c.dispose();
                              }
                            });
                          },
                        )
                            ],
                          ),
                          const SizedBox(height: 16),

                          // --- Image Picker ---
                          _buildSectionHeader("Combination Image", "Tap to change the image"),
                          const SizedBox(height: 8),
                          Center(
                            child: _buildImagePicker(
                              file: dialogImageFile,
                              networkUrl: dialogNetworkImageUrl,
                              onTap: pickCombinationImage,
                              width: double.infinity,
                              height: 180,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --- Color Selector ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader("Colors Used", "Roles for each color"),
                              TextButton.icon(
                                icon: Icon(_isLoadingColors ? Icons.sync : Iconsax.colorfilter, size: 18),
                                label: Text(_isLoadingColors ? "Loading..." : "Select Colors"),
                                onPressed: _isLoadingColors ? null : showInnerColorPicker,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // --- List of Selected Colors ---
                          if (dialogSelectedColors.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(child: Text("No colors selected.", style: TextStyle(color: Colors.grey))),
                            ),
                          if (dialogSelectedColors.isNotEmpty)
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dialogSelectedColors.length,
                              separatorBuilder: (c, i) => const Divider(height: 16),
                              itemBuilder: (c, index) {
                                final colorMap = dialogSelectedColors[index];
                                final code = colorMap['code'] ?? '';
                                final name = colorMap['name'] ?? 'No Name';
                                // Get the controller from the dialog's local map
                                final controller = dialogRoleControllers[code];
                                if (controller == null) return const SizedBox.shrink(); // Should not happen

                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text(code, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 4,
                                      child: TextFormField(
                                        controller: controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Role (e.g., "Top")',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Role required' : null,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                          const SizedBox(height: 24),

                          // --- Save Button ---
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                              icon: const Icon(Iconsax.save_2, size: 20),
                              label: const Text("Save Combination"),
                              onPressed: () {
                                // Validate image
                                if (dialogImageFile == null && (dialogNetworkImageUrl == null || dialogNetworkImageUrl!.isEmpty)) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please select an image for the combination.'), backgroundColor: Colors.orange));
                                  return;
                                }
                                // Validate colors
                                if (dialogSelectedColors.isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please select at least one color.'), backgroundColor: Colors.orange));
                                  return;
                                }
                                // Validate roles
                                if (!sheetFormKey.currentState!.validate()) {
                                  return;
                                }

                                // --- Save Logic ---
                                // 1. Read all roles from dialog controllers
                                final List<Map<String, String>> finalColors = dialogSelectedColors.map((cMap) {
                                  final code = cMap['code']!;
                                  final name = cMap['name']!;
                                  final role = dialogRoleControllers[code]?.text.trim() ?? '';
                                  return {"role": role, "code": code, "name": name};
                                }).toList();

                                // 2. Create/Update the CombinationEditData object in the *main* form's state
                                setState(() {
                                  if (existingCombination != null) {
                                    // Update existing
                                    int index = _currentCombinations.indexWhere((c) => c.id == existingCombination.id);
                                    if (index != -1) {
                                      _currentCombinations[index].imageFile = dialogImageFile;
                                      _currentCombinations[index].networkImageUrl = dialogImageFile == null ? dialogNetworkImageUrl : null; // Clear network URL if new file
                                      _currentCombinations[index].colors = finalColors;

                                      // Update the main controller map
                                      _combinationRoleControllers[existingCombination.id]?.values.forEach((c) => c.dispose()); // Dispose old
                                      _combinationRoleControllers[existingCombination.id] = {}; // Re-init
                                      for (var c in finalColors) {
                                        _combinationRoleControllers[existingCombination.id]![c['code']!] = TextEditingController(text: c['role']);
                                      }
                                    }
                                  } else {
                                    // Add new
                                    final newCombo = CombinationEditData(
                                      id: tempComboId,
                                      imageFile: dialogImageFile,
                                      networkImageUrl: dialogNetworkImageUrl, // Will be null if file was picked
                                      colors: finalColors,
                                    );
                                    _currentCombinations.add(newCombo);

                                    // Add controllers to the main map
                                    _combinationRoleControllers[newCombo.id] = {};
                                    for (var c in finalColors) {
                                      _combinationRoleControllers[newCombo.id]![c['code']!] = TextEditingController(text: c['role']);
                                    }
                                  }
                                });

                                // 3. Close sheet FIRST
                                Navigator.pop(ctx);

                                // 4. Dispose local dialog controllers *after* the pop animation
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  for (var c in dialogRoleControllers.values) {
                                    c.dispose();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24), // Padding for keyboard
                        ],
                      ),
                    ),
                  ),
                );
              }
          );
        }
    );
  }

  // --- Form UI Helper: Image Picker ---
  Widget _buildImagePicker({
    required File? file,
    required String? networkUrl,
    required VoidCallback onTap,
    double width = 120,
    double height = 120,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.5), // Slightly less than container
          child: file != null
              ? Image.file(file, fit: BoxFit.cover)
              : networkUrl != null && networkUrl.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: networkUrl,
            fit: BoxFit.cover,
            placeholder: (c, u) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (c, u, e) => const Icon(Iconsax.gallery_slash, color: Colors.grey),
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.gallery_add, color: Colors.grey.shade600, size: 30),
                const SizedBox(height: 4),
                Text("Select Image", style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Form UI Helper: Section Header ---
  Widget _buildSectionHeader(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ],
    );
  }

  // --- Form UI Helper: Combination Card ---
  Widget _buildCombinationCard(CombinationEditData combo, int index) {
    return Card(
      key: ValueKey(combo.id),
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Colors
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                _buildImagePicker(
                  file: combo.imageFile,
                  networkUrl: combo.networkImageUrl,
                  onTap: () => _showAddEditCombinationDialog(existingCombination: combo),
                ),
                const SizedBox(width: 12),
                // Colors List
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (combo.colors.isEmpty) const Text("No colors assigned", style: TextStyle(color: Colors.grey)),
                      ...combo.colors.map((colorMap) {
                        final name = colorMap['name'] ?? 'No Name';
                        final role = colorMap['role'] ?? 'No Role';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text.rich(
                            TextSpan(
                              text: "$role: ",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: name,
                                  style: const TextStyle(fontWeight: FontWeight.normal),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Iconsax.edit, size: 18),
                  label: const Text("Edit"),
                  onPressed: () => _showAddEditCombinationDialog(existingCombination: combo),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                  icon: const Icon(Iconsax.trash, size: 18),
                  label: const Text("Remove"),
                  onPressed: () {
                    setState(() {
                      _combinationRoleControllers[combo.id]?.values.forEach((c) => c.dispose());
                      _combinationRoleControllers.remove(combo.id);
                      _currentCombinations.removeAt(index);
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ---
  // --- THIS ENTIRE 'build' METHOD WAS MISSING ---
  // ---
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Stack(
        children: [
          // Main scrollable form content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding for save button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Main Image ---
                _buildSectionHeader("Main Texture Image", "The primary display image"),
                const SizedBox(height: 12),
                Center(
                  child: _buildImagePicker(
                    file: _mainImageFile,
                    networkUrl: _networkMainImageUrl,
                    onTap: _pickMainImage,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 24),

                // --- Basic Details ---
                _buildSectionHeader("Basic Details", "Name, category, and description"),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Texture Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Iconsax.pen_add),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter a name" : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Iconsax.folder_2),
                  ),
                  items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                  validator: (value) => value == null ? "Please select a category" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Iconsax.document_text),
                  ),
                  minLines: 3,
                  maxLines: 5,
                  validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter a description" : null,
                ),
                const SizedBox(height: 24),

                // --- Color Combinations ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader("Color Combinations", "Different color variations"),
                    FilledButton.tonal(
                      onPressed: () => _showAddEditCombinationDialog(),
                      child: const Text("Add New"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_currentCombinations.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: Center(
                      child: Text("No combinations added yet.", style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  ),
                if (_currentCombinations.isNotEmpty)
                  ListView.builder(
                    itemCount: _currentCombinations.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _buildCombinationCard(_currentCombinations[index], index);
                    },
                  ),
                const SizedBox(height: 24),

                // --- Products Used ---
                _buildSectionHeader("Products Used", "Select relevant products"),
                const SizedBox(height: 12),
                if (_isLoadingProducts) const Center(child: CircularProgressIndicator()),
                if (!_isLoadingProducts && _availableProducts.isEmpty)
                  const Center(child: Text("No products found in database.")),
                if (!_isLoadingProducts && _availableProducts.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Wrap(
                      spacing: 6.0,
                      runSpacing: 0.0,
                      children: _availableProducts.map((product) {
                        final key = product['key'] as String;
                        final name = product['name'] as String;
                        final isSelected = _selectedProductKeys.contains(key);

                        return FilterChip(
                          label: Text(name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedProductKeys.add(key);
                              } else {
                                _selectedProductKeys.remove(key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Floating Save Button
          if (!_isUploading)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Iconsax.save_2, color: Colors.white),
                label: Text(widget.textureKey == null ? "Save Texture" : "Update Texture", style: const TextStyle(color: Colors.white)),
                onPressed: _saveTexture,
              ),
            ),

          // Loading Overlay
          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.deepOrange),
                          SizedBox(height: 16),
                          Text("Saving Texture...", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}