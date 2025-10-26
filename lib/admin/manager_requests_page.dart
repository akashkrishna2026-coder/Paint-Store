import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://smart-paint-shop-default-rtdb.firebaseio.com',
  ).ref();

  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    final snapshot = await _dbRef.child('users').get();
    List<Map<String, dynamic>> requests = [];

    if (snapshot.exists) {
      final users = Map<String, dynamic>.from(snapshot.value as Map);
      users.forEach((uid, userData) {
        final user = Map<String, dynamic>.from(userData);
        if (user['requestedRole'] == 'Manager' && user['status'] == 'pending') {
          requests.add(user);
        }
      });
    }

    setState(() {
      _pendingRequests = requests;
      _isLoading = false;
    });
  }

  Future<void> _approveRequest(String uid) async {
    await _dbRef.child('users').child(uid).update({
      "userType": "Manager",
      "status": "approved",
    });
    if (!mounted) return;
    await _fetchPendingRequests();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Manager request approved")),
    );
  }

  Future<void> _denyRequest(String uid) async {
    await _dbRef.child('users').child(uid).update({
      "requestedRole": null,
      "status": "denied",
      "userType": "Customer",
    });
    if (!mounted) return;
    await _fetchPendingRequests();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Manager request denied")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Users", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.deepOrange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRequests.isEmpty
          ? Center(
        child: Text(
          "No pending manager requests",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final user = _pendingRequests[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(user['name'] ?? 'Unknown',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text(user['email'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 13)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _approveRequest(user['uid']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _denyRequest(user['uid']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
