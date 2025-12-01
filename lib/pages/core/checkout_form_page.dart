import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'payment_page.dart';

class CheckoutFormPage extends StatefulWidget {
  final int totalAmountPaise;
  const CheckoutFormPage({super.key, required this.totalAmountPaise});

  @override
  State<CheckoutFormPage> createState() => _CheckoutFormPageState();
}

class _CheckoutFormPageState extends State<CheckoutFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _loadingProfile = true;
  bool _locLoading = false;
  String _permissionStatus = 'Tap to use current location';
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _prefillFromAuthAndProfile();
  }

  Future<void> _prefillFromAuthAndProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _nameCtrl.text = user.displayName!;
      }
      if (user.email != null && user.email!.isNotEmpty) {
        _emailCtrl.text = user.email!;
      }
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        _phoneCtrl.text = user.phoneNumber!;
      }
      try {
        final profileSnap = await FirebaseDatabase.instance
            .ref('users/${user.uid}/profile')
            .get();
        if (profileSnap.exists && profileSnap.value is Map) {
          final data = Map<String, dynamic>.from(profileSnap.value as Map);
          if ((_nameCtrl.text).isEmpty && data['fullName'] is String) {
            _nameCtrl.text = data['fullName'];
          }
          if ((_phoneCtrl.text).isEmpty && data['phone'] is String) {
            _phoneCtrl.text = data['phone'];
          }
          if ((_emailCtrl.text).isEmpty && data['email'] is String) {
            _emailCtrl.text = data['email'];
          }
          if ((_addressCtrl.text).isEmpty && data['address'] is String) {
            _addressCtrl.text = data['address'];
          }
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loadingProfile = false);
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      setState(() => _permissionStatus = 'Location services are disabled.');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enable location services to continue')));
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied && mounted) {
        setState(() => _permissionStatus = 'Location permission denied.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever && mounted) {
      setState(() =>
          _permissionStatus = 'Permission denied forever. Open settings.');
      return false;
    }
    return true;
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locLoading = true;
      _permissionStatus = 'Fetching location...';
    });
    final ok = await _handleLocationPermission();
    if (!ok) {
      if (mounted) setState(() => _locLoading = false);
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _lat = pos.latitude;
      _lng = pos.longitude;
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address = '${p.street ?? ''}${p.street != null ? ', ' : ''}'
            '${p.subLocality ?? ''}${p.subLocality != null ? ', ' : ''}'
            '${p.locality ?? ''}${p.locality != null ? ', ' : ''}'
            '${p.postalCode ?? ''}\n'
            '${p.administrativeArea ?? ''}${p.administrativeArea != null ? ', ' : ''}'
            '${p.country ?? ''}';
        _addressCtrl.text = address;
        _permissionStatus = 'Address selected';
      } else {
        _permissionStatus = 'Address not found';
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not get location: $e')));
        setState(() {
          _permissionStatus = 'Error getting location';
        });
      }
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  Future<void> _proceedToPayment() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseDatabase.instance
            .ref('users/${user.uid}/profile')
            .update({
          'fullName': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          if (_lat != null && _lng != null)
            'location': {'lat': _lat, 'lng': _lng},
          'updatedAt': ServerValue.timestamp,
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Could not save profile: $e'),
              backgroundColor: Colors.orange));
        }
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          totalAmount: widget.totalAmountPaise,
          deliveryAddress: _addressCtrl.text.trim(),
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          lat: _lat,
          lng: _lng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountInRupees = (widget.totalAmountPaise / 100.0).toStringAsFixed(2);
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Contact Information',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Iconsax.user),
                                labelText: 'Full Name'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter your name'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Iconsax.call),
                                labelText: 'Phone Number'),
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().length < 7)
                                ? 'Enter valid phone'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Iconsax.sms),
                                labelText: 'Email (optional)'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Shipping Address',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressCtrl,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Iconsax.location),
                                labelText: 'Address'),
                            maxLines: 3,
                            validator: (v) => (v == null || v.trim().length < 6)
                                ? 'Enter a valid address'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _locLoading ? null : _useCurrentLocation,
                              icon: const Icon(Iconsax.location_tick),
                              label: Text(
                                  _locLoading
                                      ? 'Fetching location...'
                                      : 'Use Current Location',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_permissionStatus,
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total: ₹$amountInRupees',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          ElevatedButton(
                            onPressed: _proceedToPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              textStyle: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600),
                            ),
                            child: const Text('Proceed to Pay'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }
}
