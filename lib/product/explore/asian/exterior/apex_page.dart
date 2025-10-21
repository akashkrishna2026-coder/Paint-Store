import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ApexPage extends StatelessWidget {
  const ApexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'Apex_card', // Make sure the tag matches
      child: Scaffold(
        appBar: AppBar(
          title: Text("Apex Emulsions", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ),
        body: const Center(
          child: Text("Content for Apex Page goes here."),
        ),
      ),
    );
  }
}