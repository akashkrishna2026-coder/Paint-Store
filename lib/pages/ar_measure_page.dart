import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:ar_flutter_plugin_updated/widgets/ar_view.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';

class ARMeasurePage extends StatefulWidget {
  const ARMeasurePage({super.key});

  @override
  State<ARMeasurePage> createState() => _ARMeasurePageState();
}

class _ARMeasurePageState extends State<ARMeasurePage> {
  ARSessionManager? _session;
  ARObjectManager? _objectManager;
  vm.Vector3? _p1;
  vm.Vector3? _p2;
  double? _distanceMeters;
  String _status = 'Move device to detect a plane, then tap two points.';
  bool _showHelp = true;
  bool _panelExpanded = false;

  @override
  void initState() {
    super.initState();
    // Auto-hide help after a short delay to avoid blocking AR view
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 6));
      if (mounted) setState(() => _showHelp = false);
    });
  }

  @override
  void dispose() {
    try {
      _session?.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          // Floating back button to avoid a full AppBar taking space
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
          ),
          if (_showHelp)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: IgnorePointer(
                ignoring: true,
                child: Material(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('How to use AR measure', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('• Move your phone left-right to detect planes', style: TextStyle(color: Colors.white)),
                        Text('• Tap once to set the first point', style: TextStyle(color: Colors.white)),
                        Text('• Tap again to set the second point', style: TextStyle(color: Colors.white)),
                        Text('• Use Reset to measure again', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _panelExpanded
                ? Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_status),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _distanceMeters != null
                                      ? 'Distance: ${_distanceMeters!.toStringAsFixed(2)} m'
                                      : 'Distance: --',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.help_outline),
                                onPressed: () => setState(() => _showHelp = !_showHelp),
                                tooltip: 'Show instructions',
                              ),
                              TextButton(onPressed: _reset, child: const Text('Reset')),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _distanceMeters == null
                                    ? null
                                    : () => Navigator.pop(context, _distanceMeters),
                                child: const Text('Use'),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.expand_more),
                              onPressed: () => setState(() => _panelExpanded = false),
                              tooltip: 'Collapse',
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ActionChip(
                        label: Text(
                          _distanceMeters != null
                              ? 'Distance: ${_distanceMeters!.toStringAsFixed(2)} m  •  Details'
                              : 'Details',
                        ),
                        avatar: const Icon(Icons.tune, size: 18),
                        onPressed: () => setState(() => _panelExpanded = true),
                        elevation: 2,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
          )
        ],
      ),
    );
  }

  void _onARViewCreated(
    ARSessionManager session,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) async {
    _session = session;
    _objectManager = objectManager;

    await _session!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handleTaps: true,
      handlePans: false,
    );
    await _objectManager!.onInitialize();

    _session!.onPlaneOrPointTap = _onTap;
    setState(() => _status = 'Tap two points to measure distance');
  }

  Future<void> _onTap(List<ARHitTestResult> results) async {
    if (results.isEmpty) return;
    final hit = results.first;
    final m = hit.worldTransform.storage;
    final point = vm.Vector3(m[12], m[13], m[14]);

    if (_p1 == null) {
      setState(() {
        _p1 = point;
        _status = 'First point set. Tap second point.';
      });
      return;
    }
    if (_p2 == null) {
      final dx = _p1!.x - point.x;
      final dy = _p1!.y - point.y;
      final dz = _p1!.z - point.z;
      final d = math.sqrt(dx * dx + dy * dy + dz * dz);
      setState(() {
        _p2 = point;
        _distanceMeters = d;
        _status = 'Measured. Tap Use to return the value or Reset to measure again.';
      });
      return;
    }
    _reset();
    setState(() {
      _p1 = point;
      _status = 'First point set. Tap second point.';
    });
  }

  void _reset() {
    setState(() {
      _p1 = null;
      _p2 = null;
      _distanceMeters = null;
      _status = 'Tap two points to measure distance';
    });
  }
}
