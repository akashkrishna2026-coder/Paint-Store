import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class ManageTrendsPage extends StatefulWidget {
  const ManageTrendsPage({super.key});

  @override
  State<ManageTrendsPage> createState() => _ManageTrendsPageState();
}

class _CropCoverPage extends StatefulWidget {
  final Uint8List imageBytes;
  const _CropCoverPage({required this.imageBytes});

  @override
  State<_CropCoverPage> createState() => _CropCoverPageState();
}

class _CropCoverPageState extends State<_CropCoverPage> {
  final CropController _controller = CropController();
  bool _cropping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Cover', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          TextButton(
            onPressed: _cropping
                ? null
                : () {
                    setState(() => _cropping = true);
                    _controller.crop(); // onCropped will pop the route
                  },
            child: _cropping
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Done', style: GoogleFonts.poppins(color: Colors.deepOrange, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Crop(
            image: widget.imageBytes,
            controller: _controller,
            aspectRatio: 4 / 3,
            onCropped: (Uint8List bytes) {
              Navigator.of(context).pop(bytes);
            },
            baseColor: Colors.black,
            withCircleUi: false,
            interactive: true,
            maskColor: Colors.black.withValues(alpha: 0.5),
            cornerDotBuilder: (size, edgeAlignment) => Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManageTrendsPageState extends State<ManageTrendsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  final _db = FirebaseDatabase.instance.ref();
  final _picker = ImagePicker();

  File? _coverImage;
  String? _coverPreview;
  File? _pdfFile;
  String? _pdfName;

  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (picked == null) return;
    final originalBytes = await File(picked.path).readAsBytes();

    if (!mounted) return;
    final nav = Navigator.of(context);
    final route = MaterialPageRoute<Uint8List?>(
      builder: (_) => _CropCoverPage(imageBytes: originalBytes),
      fullscreenDialog: true,
    );
    final croppedBytes = await nav.push<Uint8List?>(route);

    if (!mounted) return;
    // Ensure JPEG <= ~1600px on longer side, quality ~85 to keep under 5MB
    final bytesToUse = croppedBytes ?? originalBytes; // fallback if user cancels
    final decoded = img.decodeImage(bytesToUse);
    Uint8List finalJpg;
    if (decoded != null) {
      final longer = decoded.width > decoded.height ? decoded.width : decoded.height;
      final scale = longer > 1600 ? 1600 / longer : 1.0;
      final resized = scale < 1.0
          ? img.copyResize(decoded, width: (decoded.width * scale).round(), height: (decoded.height * scale).round())
          : decoded;
      finalJpg = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } else {
      // If decode failed, fall back to original bytes
      finalJpg = bytesToUse;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/trend_cover_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(finalJpg, flush: true);
    setState(() {
      _coverImage = file;
      _coverPreview = file.path;
    });
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && mounted) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
        _pdfName = result.files.single.name;
      });
    }
  }

  Future<String> _uploadToStorage(File file, String folder, {String? explicitContentType}) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = FirebaseStorage.instance.ref().child('$folder/$name');

    // Determine content type
    String pathLower = file.path.toLowerCase();
    String contentType = explicitContentType ?? (() {
      if (folder.contains('/pdf') || folder.endsWith('pdfs')) return 'application/pdf';
      if (pathLower.endsWith('.png')) return 'image/png';
      if (pathLower.endsWith('.jpg') || pathLower.endsWith('.jpeg')) return 'image/jpeg';
      return 'application/octet-stream';
    })();

    final metadata = SettableMetadata(contentType: contentType);
    final snap = await ref.putFile(file, metadata);
    return await snap.ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverImage == null || _pdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select cover image and PDF')),
      );
      return;
    }

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Check PDF max size 20MB before upload to avoid Storage 403
    try {
      final pdfSize = await _pdfFile!.length();
      if (pdfSize > 20 * 1024 * 1024) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('PDF is larger than 20MB. Please upload a smaller file.')),
        );
        return;
      }
    } catch (_) {}

    // Capture Navigator and Messenger before async gaps

    setState(() => _submitting = true);

    try {
      final imageUrl = await _uploadToStorage(_coverImage!, 'trends/images');
      final pdfUrl = await _uploadToStorage(_pdfFile!, 'trends/pdfs', explicitContentType: 'application/pdf');

      await _db.child('trends').push().set({
        'title': _titleController.text.trim(),
        'imageUrl': imageUrl,
        'pdfUrl': pdfUrl,
        'timestamp': ServerValue.timestamp,
      });

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Trend added')),
      );
      nav.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Trends', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Trend', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              Text('Cover Image *', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickCover,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _coverPreview != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: _coverImage != null
                              ? Image.file(_coverImage!, fit: BoxFit.cover, width: double.infinity)
                              : CachedNetworkImage(imageUrl: _coverPreview!, fit: BoxFit.cover),
                        )
                      : const Center(child: Icon(Icons.image, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 16),
              Text('PDF File *', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickPdf,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pdfName ?? 'Select PDF',
                          style: GoogleFonts.poppins(color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _submitting
                  ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Save Trend', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
