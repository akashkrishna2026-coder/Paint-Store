//All the other static content sections (Hero, Collections, Testimonials, Contact, etc.) have been grouped together into their own file as simple, efficient StatelessWidgets.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../product/explore_product.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.deepOrange.withOpacity(0.8), Colors.orange.shade100],
        ),
      ),
      child: Column(
        children: [
          Text(
            "Transforming Spaces with Color",
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Premium quality paints for your home and business",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreProductPage())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 5,
            ),
            child: Text("Explore Products", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class HorizontalListSection extends StatelessWidget {
  final List<Map<String, String>> items;
  const HorizontalListSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          double cardWidth = screenWidth * 0.45;
          final item = items[index];
          return Container(
            width: cardWidth,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.white, boxShadow: [
              BoxShadow(color: Colors.orange.shade100, blurRadius: 8, offset: const Offset(2, 4)),
            ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.asset(
                    item["image"]!,
                    height: 120,
                    width: cardWidth,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      width: cardWidth,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item["title"]!, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                      if (item["subtitle"] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(item["subtitle"]!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(spacing: 16, runSpacing: 16, children: [
        _buildFeatureItem(context, icon: Icons.verified_user, title: "Quality Assurance", description: "All our paints undergo rigorous quality testing"),
        _buildFeatureItem(context, icon: Icons.local_shipping, title: "Free Delivery", description: "Free delivery on orders above ₹2000"),
        _buildFeatureItem(context, icon: Icons.color_lens, title: "Color Consultation", description: "Expert advice to choose perfect colors"),
        _buildFeatureItem(context, icon: Icons.eco, title: "Eco-Friendly", description: "Low VOC paints for healthier living"),
      ]),
    );
  }

  Widget _buildFeatureItem(BuildContext context, {required IconData icon, required String title, required String description}) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Column(children: [
        Icon(icon, color: Colors.deepOrange, size: 32),
        const SizedBox(height: 8),
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        Text(description, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
      ]),
    );
  }
}

class TestimonialsSection extends StatelessWidget {
  final List<Map<String, dynamic>> testimonials;
  const TestimonialsSection({super.key, required this.testimonials});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: testimonials.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final testimonial = testimonials[index];
          return Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
            ]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                for (int i = 0; i < 5; i++)
                  Icon(i < testimonial["rating"] ? Icons.star : Icons.star_border, color: Colors.amber, size: 16),
                const Spacer(),
                Icon(Icons.format_quote, color: Colors.deepOrange.withOpacity(0.3), size: 32),
              ]),
              const SizedBox(height: 8),
              Text(testimonial["comment"], style: GoogleFonts.poppins(fontStyle: FontStyle.italic, fontSize: 14), maxLines: 4, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Text("- ${testimonial["name"]}", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.deepOrange)),
            ]),
          );
        },
      ),
    );
  }
}

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Get in Touch", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.deepOrange)),
        const SizedBox(height: 16),
        _buildContactInfoItem(Icons.location_on, "📍 Location: Kuttikkattupadi, Kerala"),
        _buildContactInfoItem(Icons.phone, "📞 Phone: +91 9744345394"),
        _buildContactInfoItem(Icons.email, "✉ Email: chandrapaints2025@gmail.com"),
        const SizedBox(height: 16),
        Text("Business Hours:", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        Text("Monday - Saturday: 9:00 AM - 6:00 PM", style: GoogleFonts.poppins(fontSize: 12)),
        Text("Sunday: 10:00 AM - 2:00 PM", style: GoogleFonts.poppins(fontSize: 12)),
        const SizedBox(height: 16),
        Text("Follow Us:", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(children: [
          IconButton(icon: const Icon(Icons.facebook, color: Colors.blue, size: 28), onPressed: () => launchUrl(Uri.parse("https://www.facebook.com/share/16yJaRAd2U/"))),
          IconButton(icon: const Icon(Icons.camera_alt, color: Colors.purple, size: 28), onPressed: () => launchUrl(Uri.parse("https://www.instagram.com/chandrapaints2025?igsh=cG82Y3c5azM1eThw"))),
        ]),
      ]),
    );
  }

  Widget _buildContactInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.deepOrange, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.poppins())),
      ]),
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.deepOrange.withOpacity(0.9),
      child: Column(children: [
        Text("Chandra Paints", style: GoogleFonts.pacifico(fontSize: 22, color: Colors.white)),
        const SizedBox(height: 8),
        Text("© ${DateTime.now().year} All Rights Reserved", style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
      ]),
    );
  }
}
