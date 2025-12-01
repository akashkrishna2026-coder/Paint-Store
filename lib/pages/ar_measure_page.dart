import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:permission_handler/permission_handler.dart';
import 'package:ar_flutter_plugin_updated/widgets/ar_view.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';

enum MeasureMode { autoDetect, manualOutline }

class ARMeasurePage extends StatefulWidget {
  const ARMeasurePage({super.key});

  @override
  State<ARMeasurePage> createState() => _ARMeasurePageState();
}

class _ARMeasurePageState extends State<ARMeasurePage> {
  ARSessionManager? _session;
  ARObjectManager? _objectManager;
  
  MeasureMode _mode = MeasureMode.autoDetect;
  
  // Auto-detect mode
  double? _wallWidth;
  double? _wallHeight;
  // Cache last emitted values to prevent redundant UI rebuilds
  double? _lastEmittedWallWidth;
  double? _lastEmittedWallHeight;
  
  // Manual outline mode
  final List<vm.Vector3> _outlinePoints = [];
  double? _outlineWidth;
  double? _outlineHeight;
  
  String _status = 'Move device to scan for walls';
  bool _cameraGranted = false;
  bool _arReady = false;
  String? _arError;
  Key _arViewKey = UniqueKey();
  
  Timer? _planeCheckTimer;
  bool _isProcessing = false;
  // Throttle status updates
  DateTime _lastStatusUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  // Minimum interval between plane checks
  static const Duration _planeCheckInterval = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureCameraPermission();
    });
  }

  @override
  void dispose() {
    _planeCheckTimer?.cancel();
    _cleanupARSession();
    super.dispose();
  }

  void _cleanupARSession() {
    try {
      _session?.dispose();
      _session = null;
      _objectManager = null;
    } catch (e) {
      debugPrint('Error during AR cleanup: $e');
    }
  }

  Future<void> _ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (mounted) setState(() => _cameraGranted = true);
      return;
    }
    final req = await Permission.camera.request();
    if (mounted) {
      setState(() => _cameraGranted = req.isGranted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _cleanupARSession();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // AR View
            if (_cameraGranted)
              // PlatformView: keep isolated to avoid unnecessary repaints
              RepaintBoundary(
                child: ARView(
                  key: _arViewKey,
                  onARViewCreated: _onARViewCreated,
                  planeDetectionConfig: PlaneDetectionConfig.vertical,
                ),
              )
            else
              _buildPermissionPrompt(),
            
            // Top bar with back button and mode toggle
            const RepaintBoundary(child: SizedBox()),
            RepaintBoundary(child: _buildTopBar()),
            
            // Status and measurements overlay
            RepaintBoundary(child: _buildMeasurementOverlay()),
            
            // Bottom action buttons
            RepaintBoundary(child: _buildBottomActions()),
            
            // Instructions overlay
            if (!_arReady && _arError == null)
              RepaintBoundary(child: _buildLoadingOverlay()),
            
            // Error overlay
            if (_arError != null)
              RepaintBoundary(child: _buildErrorOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionPrompt() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, size: 80, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              Text(
                'Camera Access Required',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'AR measurement needs camera access to detect walls and measure dimensions',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  await _ensureCameraPermission();
                  if (!_cameraGranted) {
                    await openAppSettings();
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: Text('Grant Camera Access', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Back button
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  _cleanupARSession();
                  Navigator.of(context).pop();
                },
              ),
            ),
            const Spacer(),
            // Mode toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModeButton(
                    icon: Icons.auto_awesome,
                    label: 'Auto',
                    isActive: _mode == MeasureMode.autoDetect,
                    onTap: () => _switchMode(MeasureMode.autoDetect),
                  ),
                  const SizedBox(width: 4),
                  _buildModeButton(
                    icon: Icons.edit,
                    label: 'Outline',
                    isActive: _mode == MeasureMode.manualOutline,
                    onTap: () => _switchMode(MeasureMode.manualOutline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.deepOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementOverlay() {
    if (!_arReady) return const SizedBox.shrink();
    
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _mode == MeasureMode.autoDetect ? Icons.auto_awesome : Icons.edit,
                  color: Colors.deepOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (_mode == MeasureMode.autoDetect && (_wallWidth != null || _wallHeight != null)) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              _buildDimensionRow('Width', _wallWidth),
              const SizedBox(height: 8),
              _buildDimensionRow('Height', _wallHeight),
            ],
            if (_mode == MeasureMode.manualOutline && _outlinePoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              _buildDimensionRow('Width', _outlineWidth),
              const SizedBox(height: 8),
              _buildDimensionRow('Height', _outlineHeight),
              const SizedBox(height: 8),
              Text(
                'Points: ${_outlinePoints.length}',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionRow(String label, double? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value != null ? '${value.toStringAsFixed(2)} m' : '--',
            style: GoogleFonts.poppins(
              color: Colors.deepOrange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    if (!_arReady) return const SizedBox.shrink();
    
    final hasData = _mode == MeasureMode.autoDetect 
        ? (_wallWidth != null && _wallHeight != null)
        : (_outlineWidth != null && _outlineHeight != null);
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Row(
            children: [
              // Reset button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: Text('Reset', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Use measurement button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: hasData ? _useMeasurement : null,
                  icon: const Icon(Icons.check_circle),
                  label: Text('Use Measurement', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: hasData ? 4 : 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Colors.deepOrange,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing AR...',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Move your device slowly to help detection',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
              const SizedBox(height: 24),
              Text(
                'AR Error',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _arError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _cleanupARSession();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: Text('Go Back', style: GoogleFonts.poppins()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _retryAR,
                    icon: const Icon(Icons.refresh),
                    label: Text('Retry', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

    try {
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
      
      // Start periodic plane checking for auto-detect mode
      _startPlaneDetection();
      
      if (mounted) {
        setState(() {
          _arReady = true;
          _arError = null;
          _updateStatus();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _arError = 'Failed to initialize AR: ${e.toString()}\n\nPlease ensure ARCore is installed and updated.';
          _arReady = false;
        });
      }
    }
  }

  void _startPlaneDetection() {
    _planeCheckTimer?.cancel();
    if (_mode == MeasureMode.autoDetect) {
      _planeCheckTimer = Timer.periodic(_planeCheckInterval, (_) {
        if (mounted) _checkForWalls();
      });
    }
  }

  Future<void> _checkForWalls() async {
    if (_isProcessing || !_arReady || _mode != MeasureMode.autoDetect) return;
    
    _isProcessing = true;
    
    try {
      final dynamic sessionDynamic = _session;
      if (sessionDynamic == null) return;
      
      // Try to get all detected planes
      List<dynamic>? planes;
      try {
        planes = await sessionDynamic.getAllPlanes?.call();
      } catch (e) {
        debugPrint('Error getting planes: $e');
      }
      
      if (planes != null && planes.isNotEmpty) {
        // Find the largest vertical plane (likely a wall)
        dynamic bestWall;
        double maxArea = 0;
        
        for (var plane in planes) {
          try {
            // Check if it's vertical by examining the normal vector
            final normal = _getPlaneNormal(plane);
            if (normal != null && _isVerticalPlane(normal)) {
              final area = _estimatePlaneArea(plane);
              if (area > maxArea) {
                maxArea = area;
                bestWall = plane;
              }
            }
          } catch (e) {
            debugPrint('Error processing plane: $e');
          }
        }
        
        if (bestWall != null && mounted) {
          _calculateWallDimensions(bestWall);
        }
      }
    } catch (e) {
      debugPrint('Error in wall detection: $e');
    } finally {
      _isProcessing = false;
    }
  }

  vm.Vector3? _getPlaneNormal(dynamic plane) {
    try {
      final transform = plane.transform;
      if (transform != null) {
        final m = transform.storage;
        // Normal is typically in the third column of the rotation matrix
        return vm.Vector3(m[8], m[9], m[10]).normalized();
      }
    } catch (e) {
      debugPrint('Error getting plane normal: $e');
    }
    return null;
  }

  bool _isVerticalPlane(vm.Vector3 normal) {
    // A vertical plane has a normal that's mostly horizontal (low Y component)
    // Check if the Y component is small (near zero) and X or Z is significant
    final absY = normal.y.abs();
    final horizontalMag = math.sqrt(normal.x * normal.x + normal.z * normal.z);
    return absY < 0.3 && horizontalMag > 0.7; // Adjusted thresholds
  }

  double _estimatePlaneArea(dynamic plane) {
    try {
      final extent = plane.extentX ?? 0.0;
      final extentZ = plane.extentZ ?? 0.0;
      return extent * extentZ;
    } catch (e) {
      return 0.0;
    }
  }

  void _calculateWallDimensions(dynamic wall) {
    try {
      // Get plane extents
      double width = wall.extentX?.abs() ?? 0.0;
      double height = wall.extentZ?.abs() ?? 0.0;
      
      // Ensure reasonable dimensions (swap if needed)
      if (width < height) {
        final temp = width;
        width = height;
        height = temp;
      }
      
      // Only update if dimensions are reasonable (between 0.5m and 20m)
      if (width > 0.5 && width < 20 && height > 0.5 && height < 20) {
        // Avoid frequent tiny updates; only emit if change > 1 cm
        final changed = (_lastEmittedWallWidth == null || (_lastEmittedWallWidth! - width).abs() > 0.01) ||
            (_lastEmittedWallHeight == null || (_lastEmittedWallHeight! - height).abs() > 0.01);
        if (changed && mounted) {
          _wallWidth = width;
          _wallHeight = height;
          _lastEmittedWallWidth = width;
          _lastEmittedWallHeight = height;
          // Once we have a stable detection, stop plane polling to reduce GPU/CPU load
          _planeCheckTimer?.cancel();
          // Throttle status text updates to at most every 500ms
          final now = DateTime.now();
          if (now.difference(_lastStatusUpdate) > const Duration(milliseconds: 500)) {
            _lastStatusUpdate = now;
            setState(() {
              _status = 'Wall detected! (locked) Width: ${width.toStringAsFixed(2)}m, Height: ${height.toStringAsFixed(2)}m';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating wall dimensions: $e');
    }
  }

  Future<void> _onTap(List<ARHitTestResult> results) async {
    if (_mode != MeasureMode.manualOutline || results.isEmpty) return;
    
    final hit = results.first;
    final m = hit.worldTransform.storage;
    final point = vm.Vector3(m[12], m[13], m[14]);
    
    setState(() {
      _outlinePoints.add(point);
      
      if (_outlinePoints.length >= 3) {
        _calculateOutlineDimensions();
      }
      
      _updateStatus();
    });
  }

  void _calculateOutlineDimensions() {
    if (_outlinePoints.length < 2) return;
    
    // Find bounding box of all points
    double minX = _outlinePoints[0].x;
    double maxX = _outlinePoints[0].x;
    double minY = _outlinePoints[0].y;
    double maxY = _outlinePoints[0].y;
    
    for (var point in _outlinePoints) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }
    
    final width = (maxX - minX).abs();
    final height = (maxY - minY).abs();
    
    setState(() {
      _outlineWidth = width;
      _outlineHeight = height;
    });
  }

  void _switchMode(MeasureMode newMode) {
    if (_mode == newMode) return;
    
    setState(() {
      _mode = newMode;
      _reset();
    });
    
    if (newMode == MeasureMode.autoDetect) {
      _startPlaneDetection();
    } else {
      _planeCheckTimer?.cancel();
    }
    
    _updateStatus();
  }

  void _updateStatus() {
    String newStatus;
    
    if (_mode == MeasureMode.autoDetect) {
      if (_wallWidth != null && _wallHeight != null) {
        newStatus = 'Wall detected! Tap "Use Measurement" to continue';
      } else {
        newStatus = 'Point camera at a wall. Move slowly for better detection';
      }
    } else {
      if (_outlinePoints.isEmpty) {
        newStatus = 'Tap on the wall to mark corner points';
      } else if (_outlinePoints.length < 4) {
        newStatus = 'Mark ${4 - _outlinePoints.length} more points to complete outline';
      } else {
        newStatus = 'Outline complete! Tap "Use Measurement" or add more points';
      }
    }
    
    if (mounted && newStatus != _status) {
      setState(() => _status = newStatus);
    }
  }

  void _reset() {
    setState(() {
      _wallWidth = null;
      _wallHeight = null;
      _outlinePoints.clear();
      _outlineWidth = null;
      _outlineHeight = null;
      _updateStatus();
    });
  }

  void _useMeasurement() {
    Map<String, double> result;
    
    if (_mode == MeasureMode.autoDetect && _wallWidth != null && _wallHeight != null) {
      result = {
        'width': _wallWidth!,
        'height': _wallHeight!,
        'area': _wallWidth! * _wallHeight!,
      };
    } else if (_mode == MeasureMode.manualOutline && _outlineWidth != null && _outlineHeight != null) {
      result = {
        'width': _outlineWidth!,
        'height': _outlineHeight!,
        'area': _outlineWidth! * _outlineHeight!,
      };
    } else {
      return;
    }
    
    _cleanupARSession();
    Navigator.pop(context, result);
  }

  void _retryAR() {
    _cleanupARSession();
    setState(() {
      _arReady = false;
      _arError = null;
      _arViewKey = UniqueKey();
    });
  }
}
