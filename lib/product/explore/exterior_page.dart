import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:c_h_p/product/explore/asian/exterior/asian_paints_exterior_page.dart';

import 'package:c_h_p/product/explore/indigo/indigo_paints_exterior_page.dart';


class ExteriorPage extends StatelessWidget {

  const ExteriorPage({super.key});


  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      appBar: AppBar(

        title: Text("Select a Brand", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),

        backgroundColor: Colors.white,

        elevation: 1,

      ),

      body: Container(

        width: double.infinity,

        decoration: BoxDecoration(

          gradient: LinearGradient(

            colors: [Colors.white, Colors.grey.shade100],

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

          ),

        ),

        child: Padding(

          padding: const EdgeInsets.symmetric(horizontal: 24.0),

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              _BuildBrandOption(

                assetLogo: "assets/asian.jpg", // Your new image

                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AsianPaintsExteriorPage())),

              )

                  .animate()

                  .fadeIn(duration: 500.ms, delay: 200.ms)

                  .moveY(begin: 30, curve: Curves.easeOut),


              const SizedBox(height: 20),


              _BuildBrandOption(

                assetLogo: "assets/indigo.jpg", // Your new image

                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IndigoPaintsExteriorPage())),

              )

                  .animate()

                  .fadeIn(duration: 500.ms, delay: 300.ms)

                  .moveY(begin: 30, curve: Curves.easeOut),

            ],

          ),

        ),

      ),

    );

  }

}


class _BuildBrandOption extends StatefulWidget {

  final String assetLogo;

  final VoidCallback onTap;


  const _BuildBrandOption({required this.assetLogo, required this.onTap});


  @override

  State<_BuildBrandOption> createState() => _BuildBrandOptionState();

}


class _BuildBrandOptionState extends State<_BuildBrandOption> {

  bool _isHovering = false;


  @override

  Widget build(BuildContext context) {

    return MouseRegion(

      onEnter: (_) => setState(() => _isHovering = true),

      onExit: (_) => setState(() => _isHovering = false),

      child: AnimatedScale(

        scale: _isHovering ? 1.05 : 1.0,

        duration: 200.ms,

        curve: Curves.easeOut,

        child: Card(

          margin: EdgeInsets.zero,

          elevation: _isHovering ? 10 : 4,

          shadowColor: Colors.black.withOpacity(0.15),

          clipBehavior: Clip.antiAlias,

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

          child: InkWell(

            onTap: widget.onTap,

            child: Container(

              height: 150,

              padding: const EdgeInsets.all(16),

              color: Colors.white,

              child: Center(

                child: Padding(

                  padding: const EdgeInsets.all(12.0),

                  child: Image.asset(

                    widget.assetLogo,

                    fit: BoxFit.contain,

                  ),

                ),

              ),

            ),

          ),

        ),

      ),

    );

  }

}