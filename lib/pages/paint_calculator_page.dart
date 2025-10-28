import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:permission_handler/permission_handler.dart';
import 'paint_results_page.dart';
import 'package:ar_flutter_plugin_updated/widgets/ar_view.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';

class PaintCalculatorPage extends StatefulWidget {
  const PaintCalculatorPage({super.key});

  @override
  State<PaintCalculatorPage> createState() => _PaintCalculatorPageState();
}

class _PaintCalculatorPageState extends State<PaintCalculatorPage> {
  ARSessionManager? _session;
  ARObjectManager? _objectManager;
  vm.Vector3? _p1;
  vm.Vector3? _p2;
  bool _measuringWidth = true;
  double? _widthM;
  double? _heightM;
  String _status = 'Move device to detect a plane, then tap two points for WIDTH.';
  bool _showHelp = true;
  // New: units and measurement helpers (display only)
  final bool _useMetric = true; // true: meters, false: feet/inches display
  bool _cameraReady = false;
  final bool _wallMode = true; // when true, vertical-only plane detection (auto wall mode)
  bool _manualMode = false; // fallback UI when AR fails or user prefers manual
  bool _arCreated = false; // prevent double initialization
  final TextEditingController _manualW = TextEditingController();
  final TextEditingController _manualH = TextEditingController();
  // Screen-space tap markers (visual aid). Not world-anchored but helps feedback.
  final List<Offset> _tapOffsets = [];
  Offset? _lastPointer;

  @override
  void initState() {
    super.initState();
    // Auto-hide help to avoid blocking AR interaction
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 6));
      if (mounted) setState(() => _showHelp = false);
    });
    _ensureCameraPermission();
  }
  @override
  void dispose() {
    // Dispose AR resources to release camera and overlays
    try {
      _session?.dispose();
    } catch (_) {}
    _manualW.dispose();
    _manualH.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Extra safety: ensure AR session is stopped when page is no longer active
    try {
      _session?.dispose();
    } catch (_) {}
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    // Simple measure UI: show width/height and push to results

    return Scaffold(
      body: Stack(
        children: [
          // Capture pointer positions without blocking AR gestures
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (ev) { _lastPointer = ev.position; },
            ),
          ),
          if (_cameraReady && !_manualMode)
            ARView(
              onARViewCreated: _onARViewCreated,
              planeDetectionConfig: _wallMode
                  ? PlaneDetectionConfig.vertical
                  : PlaneDetectionConfig.horizontalAndVertical,
            )
          else if (!_cameraReady)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 56),
                    const SizedBox(height: 12),
                    const Text('Camera permission needed for AR'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _ensureCameraPermission,
                      child: const Text('Grant permission'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _manualMode = true),
                      child: const Text('Use manual input instead'),
                    ),
                  ],
                ),
              ),
            ),
          if (_manualMode)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          // Center reticle (non-blocking)
          if (_cameraReady && !_manualMode)
          IgnorePointer(
            ignoring: true,
            child: Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
              ),
            ),
          ),
          // Tap markers (screen space)
          ..._tapOffsets.map((o) => Positioned(
                left: o.dx - 6,
                top: o.dy - 6,
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(color: Theme.of(context).colorScheme.tertiary, width: 2),
                    ),
                  ),
                ),
              )),
          // Status chip (non-blocking)
          IgnorePointer(
            ignoring: true,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Text(_cameraReady ? _status : 'Awaiting camera permission…', style: Theme.of(context).textTheme.labelMedium),
                  ),
                ),
              ),
            ),
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
          // Manual toggle (top-right)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: FilterChip(
                  label: const Text('Manual'),
                  selected: _manualMode,
                  onSelected: (v) => setState(() => _manualMode = v),
                  avatar: const Icon(Icons.edit, size: 18),
                ),
              ),
            ),
          ),
          if (_showHelp)
            Positioned(
              left: 12,
              right: 12,
              top: 12,
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
                        Text('How to use AR calculator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('• Move your phone to detect a flat surface (plane)', style: TextStyle(color: Colors.white)),
                        Text('• Tap two points for WIDTH, then two points for HEIGHT', style: TextStyle(color: Colors.white)),
                        Text('• Adjust coverage and buffer if needed', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: _manualMode
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enter dimensions (${_useMetric ? 'meters' : 'feet'})'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _manualW,
                                  decoration: const InputDecoration(labelText: 'Width', border: OutlineInputBorder()),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _manualH,
                                  decoration: const InputDecoration(labelText: 'Height', border: OutlineInputBorder()),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              TextButton(onPressed: () => setState((){ _manualW.clear(); _manualH.clear(); }), child: const Text('Clear')),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  final w = double.tryParse(_manualW.text.trim());
                                  final h = double.tryParse(_manualH.text.trim());
                                  if (w != null && h != null && w > 0 && h > 0) {
                                    final wm = _useMetric ? w : w / 3.28084;
                                    final hm = _useMetric ? h : h / 3.28084;
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PaintResultsPage(
                                          initialWalls: [ Wall(widthM: wm, heightM: hm, name: 'Wall 1') ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Add to Results'),
                              ),
                            ],
                          )
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Width: ${_formatLen(_widthM)}'),
                                Text('Height: ${_formatLen(_heightM)}'),
                              ],
                            ),
                          ),
                          TextButton(onPressed: _reset, child: const Text('Reset')),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: (_widthM != null && _heightM != null)
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PaintResultsPage(
                                          initialWalls: [
                                            Wall(widthM: _widthM!, heightM: _heightM!, name: 'Wall 1'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: const Text('Add to Results'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Permissions
  Future<void> _ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (mounted) setState(() => _cameraReady = true);
      return;
    }
    final req = await Permission.camera.request();
    if (req.isGranted) {
      if (mounted) setState(() => _cameraReady = true);
    } else if (req.isPermanentlyDenied) {
      if (mounted) setState(() => _cameraReady = false);
      await openAppSettings();
    } else {
      if (mounted) setState(() => _cameraReady = false);
    }
  }

  void _onARViewCreated(
    ARSessionManager session,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    if (_arCreated) return; // prevent double init from hot reloads/layouts
    _arCreated = true;
    _session = session;
    _objectManager = objectManager;

    _initializeAR().then((_) {
      _session!.onPlaneOrPointTap = _onTap;
      if (mounted) setState(() => _status = 'Tap two points to measure WIDTH.');
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _status = 'AR failed to initialize. Use Manual mode.';
          _manualMode = true;
        });
      }
    });
  }

  Future<void> _initializeAR() async {
    if (_session == null || _objectManager == null) return;
    try {
      await _session!.onInitialize(
        showFeaturePoints: true,
        showPlanes: true,
        // Use a high-contrast texture from assets to make detected planes clearer
        customPlaneTexturePath: 'assets/calc.webp',
        showWorldOrigin: false,
        handleTaps: true,
        handlePans: false,
      );
      await _objectManager!.onInitialize();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _onTap(List<ARHitTestResult> results) async {
    if (results.isEmpty) return;
    final m = results.first.worldTransform.storage;
    final point = vm.Vector3(m[12], m[13], m[14]);
    // Heuristic distance band gating (approximate) to improve reliability
    final distance = point.length; // May approximate camera distance if origin ~ initial camera
    if (distance.isFinite && (distance < 0.5 || distance > 3.5)) {
      setState(() {
        _status = distance < 0.5
            ? 'Too close to wall (< 0.5 m). Step back slightly.'
            : 'Too far from wall (> 3.5 m). Move closer.';
      });
      return;
    }

    if (_p1 == null) {
      setState(() {
        _p1 = point;
        _status = _measuringWidth ? 'First point set for WIDTH. Tap second point.' : 'First point set for HEIGHT. Tap second point.';
        if (_lastPointer != null) {
          _tapOffsets.add(_lastPointer!);
          if (_tapOffsets.length > 4) _tapOffsets.removeAt(0);
        }
      });
      return;
    }

    if (_p2 == null) {
      final dx = _p1!.x - point.x;
      final dy = _p1!.y - point.y;
      final dz = _p1!.z - point.z;

      // Precision improvements: constrain along expected axes on a vertical wall
      double d;
      if (_measuringWidth) {
        // WIDTH should be horizontal along the wall: ignore vertical component
        final horizontal = math.sqrt(dx * dx + dz * dz);
        // If the two taps differ too much in height, ask user to retap
        if (dy.abs() > 0.20) {
          setState(() {
            _status = 'Keep both WIDTH taps at similar height (vertical diff < 20 cm). Try again.';
            _p1 = null; _p2 = null;
          });
          return;
        }
        d = horizontal;
      } else {
        // HEIGHT should be vertical: use only vertical component
        final horizontal = math.sqrt(dx * dx + dz * dz);
        // If horizontal drift is large, ask user to retap
        if (horizontal > 0.20) {
          setState(() {
            _status = 'Keep HEIGHT taps vertically aligned (horizontal drift < 20 cm). Try again.';
            _p1 = null; _p2 = null;
          });
          return;
        }
        d = dy.abs();
      }

      setState(() {
        _p2 = point;
        if (_measuringWidth) {
          _widthM = d;
          _measuringWidth = false;
          _status = 'Width set (${_widthM!.toStringAsFixed(2)} m). Now tap two points for HEIGHT.';
        } else {
          _heightM = d;
          _status = 'Height set (${_heightM!.toStringAsFixed(2)} m). Add to Results or Reset to re-measure.';
        }
        _p1 = null;
        _p2 = null;
        if (_lastPointer != null) {
          _tapOffsets.add(_lastPointer!);
          if (_tapOffsets.length > 4) _tapOffsets.removeAt(0);
        }
      });
      return;
    }
  }


  void _reset() {
    setState(() {
      _p1 = null;
      _p2 = null;
      _widthM = null;
      _heightM = null;
      _measuringWidth = true;
      _status = 'Tap two points to measure WIDTH.';
      _tapOffsets.clear();
    });
    
  }

  // Helpers
  String _formatLen(double? m) {
    if (m == null || !m.isFinite) return '--';
    if (_useMetric) return '${m.toStringAsFixed(2)} m';
    final feet = m * 3.28084;
    final f = feet.floor();
    final inch = (feet - f) * 12;
    return "${f.toString()} ft ${inch.toStringAsFixed(1)} in";
    }
}


