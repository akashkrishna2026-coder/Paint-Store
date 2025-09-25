import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IndigoPaintsExteriorPage extends StatelessWidget {
  const IndigoPaintsExteriorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Indigo Paints - Exterior", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: Center(
        child: Text(
          "Indigo Exterior Products Coming Soon!",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}