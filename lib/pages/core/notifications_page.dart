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
  final bool _animatedOnce = false;
  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markNotificationsAsRead(FirebaseDatabase.instance
            .ref('users/${currentUser.uid}/notifications'));
      });
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
        title: Text("Clear All Notifications?",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content:
            Text("This action cannot be undone.", style: GoogleFonts.poppins()),
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

    final db = FirebaseDatabase.instance.ref();
    final DatabaseReference notificationsRef = db.child('users/${currentUser.uid}/notifications');
    final DatabaseReference userRef = db.child('users/${currentUser.uid}');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Notifications",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
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
      body: FutureBuilder<DataSnapshot>(
        future: userRef.get(),
        builder: (context, userSnap) {
          final userType = (userSnap.data?.value is Map)
              ? (Map<String, dynamic>.from(userSnap.data!.value as Map)['userType'] ?? '').toString()
              : '';

          final bool isManager = userType == 'Manager';
          final bool isAdmin = userType == 'Admin';

          final globalManagersRef = db.child('notifications/globalForManagers');
          final globalAdminsRef = db.child('notifications/globalForAdmins');

          return StreamBuilder<DatabaseEvent>(
            stream: notificationsRef.orderByChild('timestamp').onValue,
            builder: (context, personalSnap) {
              final List<MapEntry<String, Map<String, dynamic>>> personal = [];
              if (personalSnap.hasData && personalSnap.data!.snapshot.value is Map) {
                final m = Map<String, dynamic>.from(personalSnap.data!.snapshot.value as Map);
                personal.addAll(m.entries.map((e) => MapEntry(e.key, Map<String, dynamic>.from(e.value))));
              }

              if (!isManager && !isAdmin) {
                return _buildList(context, notificationsRef, personal);
              }

              // For Manager/Admin, also include global channel
              final globalRef = isAdmin ? globalAdminsRef : globalManagersRef;
              return StreamBuilder<DatabaseEvent>(
                stream: globalRef.orderByChild('timestamp').onValue,
                builder: (context, globalSnap) {
                  final List<MapEntry<String, Map<String, dynamic>>> global = [];
                  if (globalSnap.hasData && globalSnap.data!.snapshot.value is Map) {
                    final m = Map<String, dynamic>.from(globalSnap.data!.snapshot.value as Map);
                    global.addAll(m.entries.map((e) => MapEntry(e.key, Map<String, dynamic>.from(e.value))));
                  }

                  // Merge and sort by timestamp desc
                  final merged = [...personal, ...global];
                  merged.sort((a, b) {
                    final at = (a.value['timestamp'] ?? 0) as int;
                    final bt = (b.value['timestamp'] ?? 0) as int;
                    return bt.compareTo(at);
                  });
                  return _buildList(context, notificationsRef, merged);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, DatabaseReference personalRef, List<MapEntry<String, Map<String, dynamic>>> items) {
    if (items.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      cacheExtent: 800,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final notificationKey = items[index].key;
        final notificationData = items[index].value;
        final tsValue = notificationData['timestamp'];
        final timestamp = tsValue is int ? DateTime.fromMillisecondsSinceEpoch(tsValue) : null;
        final formattedDate = timestamp != null ? DateFormat('MMM d, yyyy - h:mm a').format(timestamp) : '';

        final itemCard = Dismissible(
          key: Key(notificationKey + index.toString()),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            personalRef.child(notificationKey).remove();
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
            shadowColor: Colors.black.withValues(alpha: 0.05),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.deepOrange,
                child: Icon(Iconsax.message_text_1, color: Colors.white, size: 20),
              ),
              title: Text(notificationData['message'] ?? 'New Notification', style: GoogleFonts.poppins()),
              subtitle: Text(formattedDate, style: GoogleFonts.poppins(fontSize: 12)),
            ),
          ),
        );

        if (!_animatedOnce) {
          return itemCard
              .animate()
              .fade(duration: 400.ms, delay: (80 * index).ms)
              .slideY(begin: 0.15, curve: Curves.easeOut);
        } else {
          return itemCard;
        }
      },
    );
  }
}
