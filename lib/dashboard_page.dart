import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatelessWidget {
  final String role; // "admin" or "customer"

  const DashboardPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard", style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: role == "admin"
            ? Text("Welcome Admin!", style: GoogleFonts.poppins(fontSize: 24))
            : Text("Welcome Customer!", style: GoogleFonts.poppins(fontSize: 24)),
      ),
    );
  }
}
