import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/painter_model.dart';

class ViewPaintersPage extends StatelessWidget {
  const ViewPaintersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference paintersRef = FirebaseDatabase.instance.ref('painters');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Our Professional Painters", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder(
        stream: paintersRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.user_search, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text("No painters are available at the moment.", style: GoogleFonts.poppins()),
                ],
              ),
            );
          }

          final paintersMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          final List<Painter> paintersList = [];
          paintersMap.forEach((key, value) {
            paintersList.add(Painter.fromMap(key, value));
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paintersList.length,
            itemBuilder: (context, index) {
              final painter = paintersList[index];
              final phone = painter.phone;

              // ⭐ UI: Replaced the custom Column with a more professional ListTile inside the Card.
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade200,
                      // ⭐ UI: Using CachedNetworkImage for better performance and placeholders.
                      child: painter.imageUrl != null && painter.imageUrl!.isNotEmpty
                          ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: painter.imageUrl!,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2.0),
                          errorWidget: (context, url, error) => const Icon(Iconsax.user, color: Colors.grey, size: 30),
                        ),
                      )
                          : const Icon(Iconsax.user, color: Colors.grey, size: 30),
                    ),
                    title: Text(painter.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Iconsax.location, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(painter.location, style: GoogleFonts.poppins()),
                        ]),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Iconsax.wallet_money, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('₹${painter.dailyFare} / day', style: GoogleFonts.poppins()),
                        ]),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: (phone != null && phone.isNotEmpty)
                        ? IconButton(
                      icon: const Icon(Iconsax.call, color: Colors.green, size: 28),
                      tooltip: "Call ${painter.name}",
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final Uri launchUri = Uri(scheme: 'tel', path: phone);
                        final ok = await canLaunchUrl(launchUri);
                        if (ok) {
                          await launchUrl(launchUri);
                        } else {
                          messenger.showSnackBar(const SnackBar(content: Text("Could not place the call.")));
                        }
                      },
                    )
                        : null,
                  ),
                ),
              ) // ⭐ UI: Added smooth fade-in and slide animation to each card.
                  .animate()
                  .fade(duration: 500.ms, delay: (100 * index).ms)
                  .slideY(begin: 0.3, curve: Curves.easeOut);
            },
          );
        },
      ),
    );
  }
}