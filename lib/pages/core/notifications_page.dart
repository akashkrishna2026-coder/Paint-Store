import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Mark as read when the page is first opened
      _markNotificationsAsRead(FirebaseDatabase.instance.ref('users/${currentUser.uid}/notifications'));
    }
  }

  void _markNotificationsAsRead(DatabaseReference ref) {
    ref.orderByChild('isRead').equalTo(false).get().then((snapshot) {
      if (snapshot.exists) {
        final Map<String, dynamic> updates = {};
        for (var child in snapshot.children) {
          updates['${child.key}/isRead'] = true;
        }
        ref.update(updates);
      }
    });
  }

  // ⭐ NEW: Function to clear all notifications with confirmation
  Future<void> _clearAllNotifications(DatabaseReference ref) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Notifications?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("This action cannot be undone.", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Clear", style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      await ref.remove();
    }
  }


  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: const Center(child: Text("Please log in to see notifications.")),
      );
    }

    final DatabaseReference notificationsRef = FirebaseDatabase.instance.ref('users/${currentUser.uid}/notifications');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Notifications", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
        // ⭐ NEW: Action button to clear all notifications
        actions: [
          IconButton(
            icon: const Icon(Iconsax.trash),
            tooltip: 'Clear All Notifications',
            onPressed: () => _clearAllNotifications(notificationsRef),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: notificationsRef.orderByChild('timestamp').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.notification, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text("No notifications yet.", style: GoogleFonts.poppins()),
                ],
              ),
            );
          }

          final notificationsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final notificationsList = notificationsMap.entries.toList().reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: notificationsList.length,
            itemBuilder: (context, index) {
              final notificationEntry = notificationsList[index];
              final notificationKey = notificationEntry.key;
              final notificationData = Map<String, dynamic>.from(notificationEntry.value);
              final timestamp = notificationData['timestamp'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(notificationData['timestamp'])
                  : null;
              final formattedDate = timestamp != null ? DateFormat('MMM d, yyyy - h:mm a').format(timestamp) : '';

              // ⭐ MODIFIED: Wrapped the Card with a Dismissible widget
              return Dismissible(
                key: Key(notificationKey),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  // Remove the item from the database when dismissed
                  notificationsRef.child(notificationKey).remove();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notification dismissed")),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Iconsax.trash, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.05),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.deepOrange,
                      child: Icon(Iconsax.message_text_1, color: Colors.white, size: 20),
                    ),
                    title: Text(notificationData['message'] ?? 'New Notification', style: GoogleFonts.poppins()),
                    subtitle: Text(formattedDate, style: GoogleFonts.poppins(fontSize: 12)),
                  ),
                ),
              ).animate()
                  .fade(duration: 500.ms, delay: (100 * index).ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut);
            },
          );
        },
      ),
    );
  }
}