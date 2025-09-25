import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IndigoPaintsWaterproofingPage extends StatelessWidget {
  const IndigoPaintsWaterproofingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Indigo - Waterproofing", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: Center(
        child: Text(
          "Indigo Waterproofing Products Coming Soon!",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}