import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AcePage extends StatelessWidget {
  const AcePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'Ace_card', // Make sure the tag matches
      child: Scaffold(
        appBar: AppBar(
          title: Text("Ace Emulsions", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ),
        body: const Center(
          child: Text("Content for Ace Page goes here."),
        ),
      ),
    );
  }
}