import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/app/providers.dart';

class VisualizerPage extends ConsumerStatefulWidget {
  const VisualizerPage({super.key});

  @override
  ConsumerState<VisualizerPage> createState() => _VisualizerPageState();
}

class _VisualizerPageState extends ConsumerState<VisualizerPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selected;

  Future<void> _pickFromGallery() async {
    try {
      final img = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 92);
      if (img != null) {
        setState(() {
          _selected = img;
        });
        ref.read(visualizerVMProvider.notifier).clearResult();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open gallery: $e')),
      );
    }
  }

  Future<void> _visualize() async {
    if (_selected == null) return;
    await ref
        .read(visualizerVMProvider.notifier)
        .visualize(File(_selected!.path), scene: 'auto');
  }

  Future<void> _captureFromCamera() async {
    try {
      final img =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 92);
      if (img != null) {
        setState(() {
          _selected = img;
        });
        ref.read(visualizerVMProvider.notifier).clearResult();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open camera: $e')),
      );
    }
  }

  void _openColorPicker() async {
    final vm = ref.read(visualizerVMProvider.notifier);
    final current = ref.read(visualizerVMProvider).color;
    Color temp = current;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Choose Color',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            hexInputBar: true,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                vm.setColor(temp);
                Navigator.pop(ctx);
              },
              child: const Text('Apply')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(visualizerVMProvider);
    final imageWidget = vmState.resultUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(vmState.resultUrl!, fit: BoxFit.contain),
          )
        : _selected == null
            ? Center(
                child: Text(
                  'Select a photo of a room or house',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(_selected!.path), fit: BoxFit.contain),
              );

    return Scaffold(
      appBar: AppBar(
        title: Text('Color Visualizer',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.color_swatch),
            tooltip: 'Pick Color',
            onPressed: _openColorPicker,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: vmState.processing
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    child: vmState.error != null
                        ? Text(
                            vmState.error!,
                            style: GoogleFonts.poppins(color: Colors.red),
                            textAlign: TextAlign.center,
                          )
                        : imageWidget,
                  ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: FloatingActionButton.small(
                  heroTag: 'gallery',
                  onPressed: vmState.processing ? null : _pickFromGallery,
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  child: const Icon(Iconsax.gallery, color: Colors.black87),
                ),
              ),
              FloatingActionButton(
                heroTag: 'camera',
                onPressed: vmState.processing ? null : _captureFromCamera,
                backgroundColor: Colors.deepOrange,
                child: const Icon(Iconsax.camera, color: Colors.white),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: FilledButton.icon(
                  onPressed: (_selected != null && !vmState.processing)
                      ? _visualize
                      : null,
                  icon: const Icon(Iconsax.brush_2),
                  label: const Text('Visualize'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
