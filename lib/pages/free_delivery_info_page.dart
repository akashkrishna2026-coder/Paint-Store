import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:geocoding/geocoding.dart'; // Import geocoding
import 'package:iconsax/iconsax.dart'; // For icons

// Rename the page to better reflect its purpose
class DeliveryLocationPage extends StatefulWidget {
  const DeliveryLocationPage({super.key});

  @override
  State<DeliveryLocationPage> createState() => _DeliveryLocationPageState();
}

class _DeliveryLocationPageState extends State<DeliveryLocationPage> {
  String? _currentAddress; // To store the fetched address
  Position? _currentPosition; // To store lat/lon
  bool _isLoading = false; // To show loading indicator
  String _permissionStatus = 'Checking permissions...'; // To display status

  @override
  void initState() {
    super.initState();
    _handleLocationPermission(); // Check/request permission when page loads
  }

  // Check and request location permission
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      setState(() => _permissionStatus = 'Location services are disabled. Please enable them.');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable the services')));
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      setState(() => _permissionStatus = 'Permission denied. Tap button to request.');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied && mounted) {
        setState(() => _permissionStatus = 'Location permissions are denied.');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever && mounted) {
      setState(() => _permissionStatus = 'Permissions denied forever. Open settings to enable.');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      // Optionally open app settings
      // await Geolocator.openAppSettings();
      return false;
    }

    // Permissions are granted
    if(mounted) setState(() => _permissionStatus = 'Permission granted. Tap button to get location.');
    return true;
  }

  // Get current location and convert to address
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // First, ensure permissions are still granted
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission && mounted) {
      setState(() => _isLoading = false);
      return; // Stop if permission issue arises
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium)); // Medium accuracy is often enough for address
      if (!mounted) return; // Check after await

      setState(() {
        _currentPosition = position;
        _permissionStatus = 'Fetching address...'; // Update status
      });
      await _getAddressFromLatLng(position);

    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        setState(() {
          _permissionStatus = 'Error getting location: ${e.toString()}';
          _currentAddress = null; // Clear address on error
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not get location: ${e.toString()}', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Convert Lat/Lon to a readable address string
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        setState(() {
          // Construct a detailed address
          _currentAddress =
          '${place.street ?? ''}${place.street != null ? ', ' : ''}'
              '${place.subLocality ?? ''}${place.subLocality != null ? ', ' : ''}\n' // Add subLocality
              '${place.locality ?? ''}${place.locality != null ? ', ' : ''}'
              '${place.postalCode ?? ''}\n'
              '${place.administrativeArea ?? ''}${place.administrativeArea != null ? ', ' : ''}'
              '${place.country ?? ''}';
          _permissionStatus = 'Address Found!'; // Update status
        });
      } else if (mounted) {
        setState(() {
          _currentAddress = "Could not determine address.";
          _permissionStatus = 'Address not found.';
        });
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
      if (mounted) {
        setState(() {
          _currentAddress = "Error finding address: ${e.toString()}";
          _permissionStatus = 'Error finding address.';
        });
      }
    }
  }

  // Function to proceed (needs implementation)
  void _confirmAndProceed() {
    if (_currentAddress == null || _currentAddress!.contains("Error") || _currentAddress!.contains("Could not")) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fetch a valid delivery address first.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    // TODO: Implement navigation to the next step (e.g., PaymentPage)
    // Pass the _currentAddress and potentially _currentPosition
    debugPrint("Confirmed Address: $_currentAddress");
    debugPrint("Position: Lat: ${_currentPosition?.latitude}, Lon: ${_currentPosition?.longitude}");

    // Example Navigation (replace with your actual navigation logic):
    // Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage(deliveryAddress: _currentAddress!)));

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Address confirmed! Proceeding to next step... (Implement Navigation)'),
      backgroundColor: Colors.green,
    ));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Delivery Location",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton( // Use a standard back button or close icon
          icon: const Icon(Iconsax.arrow_left_2, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center( // Center content vertically
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons horizontally
            children: [
              Icon(Iconsax.location, size: 80, color: Colors.deepOrange.shade300),
              const SizedBox(height: 24),
              Text(
                'Confirm Your Delivery Location',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap the button below to use your current location for delivery.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Button to Get Location
              ElevatedButton.icon(
                icon: const Icon(Iconsax.location_tick),
                label: Text('Use Current Location', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                onPressed: _isLoading ? null : _getCurrentLocation, // Disable while loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Display Area for Status and Address
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300)
                  ),
                  constraints: const BoxConstraints(minHeight: 100), // Ensure minimum height
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _permissionStatus,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                      if (_currentAddress != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _currentAddress!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ]
                    ],
                  )
              ),
              const SizedBox(height: 32),

              // Confirm Button (conditionally enabled)
              ElevatedButton(
                onPressed: (_currentAddress != null && !_isLoading) ? _confirmAndProceed : null, // Enabled only if address exists and not loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16),
                  disabledBackgroundColor: Colors.grey.shade300, // Style for disabled state
                ),
                child: Text('Confirm Address & Proceed', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
              const Spacer(), // Pushes content towards center if less content
            ],
          ),
        ),
      ),
    );
  }
}