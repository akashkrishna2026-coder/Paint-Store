import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Keep for contact section
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../product/explore_product.dart'; // Keep for hero section button
import 'package:iconsax/iconsax.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange),
      ),
    );
  }
}

class GetInTouchSection extends StatelessWidget {
  const GetInTouchSection({super.key});

  static const String phoneNumber = '+919744345394';
  static const String whatsappNumber = '919744345394';
  static const String emailAddress = 'chandrapaints2025@gmail.com';
  static const String mapsUrl = 'https://maps.app.goo.gl/YsqSXgvtwZmEzuSH6';

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1A12), Color(0xFF3B2419)],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Need Expert Advice?',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Our color consultants are here to help you transform your space. Get free guidance today.',
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          // Call Now
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFFFF3D00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _launchExternal('tel:$phoneNumber'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                icon: const Icon(Icons.phone),
                label: Text('Call Now',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Chat Support
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final url =
                    'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent('Hello Chandra Paints! I need assistance.')}';
                _launchExternal(url);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B3A30),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text('Chat Support',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          // Social icons
          Row(children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => _launchExternal(
                    "https://www.facebook.com/share/16yJaRAd2U/"),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child:
                      Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => _launchExternal(
                    "https://www.instagram.com/chandrapaints2025?igsh=cG82Y3c5azM1eThw"),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Iconsax.instagram,
                      color: Color(0xFFE4405F), size: 24),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
          const SizedBox(height: 12),
          // Themed contact info
          _contactRow(
              icon: Iconsax.location,
              text: 'Kuttikkattupadi, Kerala',
              onTap: () => _launchExternal(mapsUrl)),
          const SizedBox(height: 8),
          _contactRow(
              icon: Iconsax.call,
              text: '+91 9744345394',
              onTap: () => _launchExternal('tel:$phoneNumber')),
          const SizedBox(height: 8),
          _contactRow(
              icon: Iconsax.sms,
              text: emailAddress,
              onTap: () => _launchExternal('mailto:$emailAddress')),
        ],
      ),
    );
  }

  Widget _contactRow(
      {required IconData icon, required String text, VoidCallback? onTap}) {
    final row = Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
        ),
      ],
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: row,
      ),
    );
  }
}

class PopularTrendsSection extends StatefulWidget {
  const PopularTrendsSection({super.key});

  @override
  State<PopularTrendsSection> createState() => _PopularTrendsSectionState();
}

class _PopularTrendsSectionState extends State<PopularTrendsSection> {
  late final Future<List<Map<String, dynamic>>> _trendsFuture;

  @override
  void initState() {
    super.initState();
    _trendsFuture = _fetchTrends();
  }

  Future<List<Map<String, dynamic>>> _fetchTrends() async {
    final snap = await FirebaseDatabase.instance.ref('trends').get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    final List<Map<String, dynamic>> items = [];
    map.forEach((key, value) {
      try {
        final m = Map<String, dynamic>.from(value);
        items.add({
          'key': key,
          'title': (m['title'] ?? '').toString(),
          'imageUrl': (m['imageUrl'] ?? '').toString(),
          'pdfUrl': (m['pdfUrl'] ?? '').toString(),
        });
      } catch (_) {}
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Popular Trends'),
        SizedBox(
          height: 150,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _trendsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, __) => _skeletonCard(),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: 4,
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('No trends yet',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final it = items[index];
                  return _trendCard(context, it['title'] as String,
                      it['imageUrl'] as String, it['pdfUrl'] as String);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _skeletonCard() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _trendCard(
      BuildContext context, String title, String imageUrl, String pdfUrl) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final uri = Uri.parse(pdfUrl);
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open PDF')),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              width: 200,
              height: double.infinity,
              color: Colors.white,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 600,
                placeholder: (c, u) => Container(color: Colors.grey.shade200),
                errorWidget: (c, e, s) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Iconsax.gallery_slash)),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xCC000000),
                      Color(0x33000000),
                      Colors.transparent
                    ],
                  ),
                ),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
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
          colors: [
            Colors.deepOrange.withValues(alpha: 0.8),
            Colors.orange.shade100
          ],
        ),
      ),
      child: Column(
        children: [
          Text("Transforming Spaces with Color",
              style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text("Premium quality paints for your home and business",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ExploreProductPage())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 5,
            ),
            child: Text("Explore Products",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class ExpertAdviceSection extends StatelessWidget {
  const ExpertAdviceSection({super.key});

  static const String phoneNumber = '+919744345394';
  static const String whatsappNumber =
      '919744345394'; // wa.me requires country code without +

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1A12), Color(0xFF3B2419)],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Need Expert Advice?',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Our color consultants are here to help you transform your space. Get free guidance today.',
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          // Call Now button
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFFFF3D00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Prime the dialer, do not auto-call
                  _launchExternal('tel:$phoneNumber');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                icon: const Icon(Icons.phone),
                label: Text('Call Now',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Chat Support button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final url =
                    'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent('Hello Chandra Paints! I need assistance.')}';
                _launchExternal(url);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B3A30),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text('Chat Support',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => _launchExternal(
                      "https://www.facebook.com/share/16yJaRAd2U/"),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.facebook,
                        color: Color(0xFF1877F2), size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => _launchExternal(
                      "https://www.instagram.com/chandrapaints2025?igsh=cG82Y3c5azM1eThw"),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Iconsax.instagram,
                        color: Color(0xFFE4405F), size: 24),
                  ),
                ),
              ),
            ],
          ),
        ],
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
        _buildFeatureItem(context,
            icon: Icons.verified_user,
            title: "Quality Assurance",
            description: "All our paints undergo rigorous quality testing"),
        _buildFeatureItem(context,
            icon: Iconsax.tree,
            title: "Eco-Friendly",
            description: "Low VOC paints for healthier living"), // Changed icon
      ]),
    );
  }

  // Helper function remains the same, just the onTap call is updated above
  Widget _buildFeatureItem(BuildContext context,
      {required IconData icon,
      required String title,
      required String description,
      VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) /
            2, // Calculate width for two columns
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
          border: onTap != null
              ? Border.all(color: Colors.deepOrange.shade100, width: 0.5)
              : null, // Subtle border if tappable
        ),
        child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center content vertically
            children: [
              Icon(icon, color: Colors.deepOrange, size: 32),
              const SizedBox(height: 10),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  textAlign: TextAlign.center), // Centered title
              const SizedBox(height: 6),
              Text(description,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                  textAlign: TextAlign.center), // Centered description
            ]),
      ),
    );
  }
}

// ... (TestimonialsSection, ContactSection, FooterSection remain unchanged) ...

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
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                for (int i = 0; i < 5; i++)
                  Icon(
                      i < testimonial["rating"]
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16),
                const Spacer(),
                Icon(Iconsax.quote_up_circle,
                    color: Colors.deepOrange.withValues(alpha: 0.3),
                    size: 32), // Changed icon
              ]),
              const SizedBox(height: 8),
              Expanded(
                // Allow comment to expand
                child: Text(testimonial["comment"],
                    style: GoogleFonts.poppins(
                        fontStyle: FontStyle.italic, fontSize: 14, height: 1.4),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis),
              ),
              // const Spacer(), // Removed spacer to allow text expansion
              Text("- ${testimonial["name"]}",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.deepOrange)),
            ]),
          );
        },
      ),
    );
  }
}

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  // Helper function to launch URLs safely
  Future<void> _launchUrlHelper(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Could show a snackbar here if needed: ScaffoldMessenger.of(context)...
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Contact Us",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.deepOrange)),
        const SizedBox(height: 16),
        _buildContactInfoItem(
          Iconsax.location,
          "📍 Location: Kuttikkattupadi, Kerala",
          onTap: () =>
              _launchUrlHelper("https://maps.app.goo.gl/YsqSXgvtwZmEzuSH6"),
        ),
        _buildContactInfoItem(Iconsax.call, "📞 Phone: +91 9744345394"),
        _buildContactInfoItem(
            Iconsax.sms, "✉ Email: chandrapaints2025@gmail.com"),
        const SizedBox(height: 16),
        Text("Business Hours:",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        Text("Monday - Saturday: 9:00 AM - 6:00 PM",
            style: GoogleFonts.poppins(fontSize: 12)),
        Text("Sunday: 10:00 AM - 2:00 PM",
            style: GoogleFonts.poppins(fontSize: 12)),
        const SizedBox(height: 16),
        Text("Follow Us:",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(children: [
          // Use Material widget for InkWell splash effect on Icons
          Material(
            color: Colors.transparent,
            child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => _launchUrlHelper(
                    "https://www.facebook.com/share/16yJaRAd2U/"),
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Padding for tap area
                  child:
                      Icon(Icons.facebook, color: Color(0xFF1877F2), size: 28),
                )),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => _launchUrlHelper(
                    "https://www.instagram.com/chandrapaints2025?igsh=cG82Y3c5azM1eThw"),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Iconsax.instagram,
                      color: Color(0xFFE4405F), size: 28), // Instagram icon
                )),
          ),
          // Add more social links if needed
        ]),
      ]),
    );
  }

  Widget _buildContactInfoItem(IconData icon, String text,
      {VoidCallback? onTap}) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            color: Colors.deepOrange.shade400,
            size: 20), // Slightly lighter icon
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style:
                    GoogleFonts.poppins(fontSize: 14))), // Slightly larger text
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: onTap == null
          ? row
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: row,
                ),
              ),
            ),
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
      color: Colors.grey.shade800, // Darker footer
      child: Column(children: [
        Text("Chandra Paints",
            style: GoogleFonts.pacifico(fontSize: 22, color: Colors.white)),
        const SizedBox(height: 8),
        Text("© ${DateTime.now().year} All Rights Reserved",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
      ]),
    );
  }
}
