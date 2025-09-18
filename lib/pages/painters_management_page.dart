import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart'; // ⭐ OPTIMIZATION: Import new package
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../model/painter_model.dart';

class PaintersManagementPage extends StatefulWidget {
  const PaintersManagementPage({super.key});

  @override
  State<PaintersManagementPage> createState() => _PaintersManagementPageState();
}

class _PaintersManagementPageState extends State<PaintersManagementPage> {
  final DatabaseReference _paintersRef = FirebaseDatabase.instance.ref('painters');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fareController = TextEditingController();

  File? _imageFile;
  String? _networkImageUrl;

  void _showPainterForm({Painter? painter}) {
    _imageFile = null;
    _networkImageUrl = null;

    if (painter != null) {
      _nameController.text = painter.name;
      _locationController.text = painter.location;
      _phoneController.text = painter.phone ?? '';
      _fareController.text = painter.dailyFare.toString();
      _networkImageUrl = painter.imageUrl;
    } else {
      _nameController.clear();
      _locationController.clear();
      _phoneController.clear();
      _fareController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isLoading = false;

            Future<void> pickImage() async {
              // ⭐ OPTIMIZATION: Resize image on pick to prevent freezing
              final pickedFile = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 85, // Compress the image slightly
                maxWidth: 800,   // Resize the image to a max width
                maxHeight: 800,  // Resize the image to a max height
              );
              if (pickedFile != null) {
                setModalState(() {
                  _imageFile = File(pickedFile.path);
                });
              }
            }

            Future<void> handleSave() async {
              if (!_formKey.currentState!.validate()) return;
              setModalState(() => isLoading = true);
              await _savePainter(painter?.key);
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(painter == null ? "Add New Painter" : "Edit Painter", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_networkImageUrl != null && _networkImageUrl!.isNotEmpty ? CachedNetworkImageProvider(_networkImageUrl!) : null) as ImageProvider?,
                            child: (_imageFile == null && (_networkImageUrl == null || _networkImageUrl!.isEmpty))
                                ? const Icon(Iconsax.camera, size: 40, color: Colors.grey)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Painter Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Name is required' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Location is required' : null),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone Number (Optional)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _fareController,
                          decoration: const InputDecoration(labelText: 'Fare for One Day', prefixText: '₹', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => v!.isEmpty ? 'Fare is required' : null
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : handleSave,
                          icon: isLoading ? const SizedBox.shrink() : const Icon(Iconsax.save_21),
                          label: isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : Text(painter == null ? 'Save Painter' : 'Update Details'),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _savePainter(String? painterKey) async {
    try {
      String? imageUrl = _networkImageUrl;
      if (_imageFile != null) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(_imageFile!.path)}';
        Reference storageRef = FirebaseStorage.instance.ref().child('painter_images/$fileName');
        TaskSnapshot snapshot = await storageRef.putFile(_imageFile!);
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      final painterData = {
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dailyFare': int.tryParse(_fareController.text.trim()) ?? 0,
        'imageUrl': imageUrl,
      };

      String message;
      if (painterKey == null) {
        await _paintersRef.push().set(painterData);
        message = 'Painter added successfully';
      } else {
        await _paintersRef.child(painterKey).update(painterData);
        message = 'Painter updated successfully';
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Operation failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deletePainter(String painterKey) async {
    // ... delete logic remains the same
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Painters", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.pink.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: _paintersRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No painters added yet."));
          }

          final paintersMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          final List<Painter> paintersList = [];
          paintersMap.forEach((key, value) {
            paintersList.add(Painter.fromMap(key, value));
          });

          return ListView.builder(
            itemCount: paintersList.length,
            itemBuilder: (context, index) {
              final painter = paintersList[index];
              return Dismissible(
                key: Key(painter.key),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => _deletePainter(painter.key),
                background: Container(
                  color: Colors.red.shade700,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Iconsax.trash, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    // ⭐ OPTIMIZATION: Use CachedNetworkImage for smooth scrolling
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: painter.imageUrl != null && painter.imageUrl!.isNotEmpty
                          ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: painter.imageUrl!,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Iconsax.user, color: Colors.grey),
                        ),
                      )
                          : const Icon(Iconsax.user, color: Colors.grey),
                    ),
                    title: Text(painter.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    subtitle: Text(painter.location),
                    trailing: IconButton(
                      icon: const Icon(Iconsax.edit, color: Colors.blue),
                      onPressed: () => _showPainterForm(painter: painter),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPainterForm(),
        backgroundColor: Colors.pink.shade600,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }
}