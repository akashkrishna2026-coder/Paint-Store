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
  bool _animatedOnce = false;
  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markNotificationsAsRead(FirebaseDatabase.instance
            .ref('users/${currentUser.uid}/notifications'));
        if (mounted) setState(() => _animatedOnce = true);
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
    final DatabaseReference notificationsRef =
        db.child('users/${currentUser.uid}/notifications');
    final DatabaseReference userRef = db.child('users/${currentUser.uid}');
    final DatabaseReference dismissedRef =
        db.child('users/${currentUser.uid}/dismissedNotifications');

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
              ? (Map<String, dynamic>.from(
                          userSnap.data!.value as Map)['userType'] ??
                      '')
                  .toString()
              : '';

          final bool isManager = userType == 'Manager';
          final bool isAdmin = userType == 'Admin';

          final globalManagersRef = db.child('notifications/globalForManagers');
          final globalAdminsRef = db.child('notifications/globalForAdmins');

          return StreamBuilder<DatabaseEvent>(
            stream: dismissedRef.onValue,
            builder: (context, dismissedSnap) {
              final Set<String> dismissed = {};
              if (dismissedSnap.hasData &&
                  dismissedSnap.data!.snapshot.value is Map) {
                final m = Map<String, dynamic>.from(
                    dismissedSnap.data!.snapshot.value as Map);
                dismissed.addAll(m.keys.map((k) => k.toString()));
              }

              return StreamBuilder<DatabaseEvent>(
                stream: notificationsRef
                    .orderByChild('timestamp')
                    .limitToLast(100)
                    .onValue,
                builder: (context, personalSnap) {
                  final List<Map<String, dynamic>> personal = [];
                  if (personalSnap.hasData &&
                      personalSnap.data!.snapshot.value is Map) {
                    final m = Map<String, dynamic>.from(
                        personalSnap.data!.snapshot.value as Map);
                    personal.addAll(
                      m.entries.map((e) => {
                            'key': e.key,
                            'data': Map<String, dynamic>.from(e.value),
                            'ref': notificationsRef,
                            'src': 'p',
                          }),
                    );
                  }

                  if (!isManager && !isAdmin) {
                    // Filter out any personal notifications that match dismissed signature (unlikely but safe)
                    final filtered = personal.where((it) {
                      final data = it['data'] as Map<String, dynamic>;
                      final sig =
                          '${(data['type'] ?? '').toString()}|${(data['timestamp'] ?? 0).toString()}|${(data['message'] ?? '').toString()}';
                      return !dismissed.contains(sig);
                    }).toList()
                      ..sort((a, b) {
                        final at =
                            ((a['data'] as Map<String, dynamic>)['timestamp'] ??
                                0) as int;
                        final bt =
                            ((b['data'] as Map<String, dynamic>)['timestamp'] ??
                                0) as int;
                        return bt.compareTo(at);
                      });
                    return _buildList(context, filtered, dismissedRef);
                  }

                  // For Manager/Admin, also include global channel
                  final globalRef =
                      isAdmin ? globalAdminsRef : globalManagersRef;
                  return StreamBuilder<DatabaseEvent>(
                    stream: globalRef
                        .orderByChild('timestamp')
                        .limitToLast(100)
                        .onValue,
                    builder: (context, globalSnap) {
                      final List<Map<String, dynamic>> global = [];
                      if (globalSnap.hasData &&
                          globalSnap.data!.snapshot.value is Map) {
                        final m = Map<String, dynamic>.from(
                            globalSnap.data!.snapshot.value as Map);
                        global.addAll(
                          m.entries.map((e) => {
                                'key': e.key,
                                'data': Map<String, dynamic>.from(e.value),
                                'ref': globalRef,
                                'src': 'g',
                              }),
                        );
                      }

                      // Merge, de-duplicate by signature, filter dismissed, and sort by timestamp desc
                      final List<Map<String, dynamic>> merged = [];
                      final Set<String> seen = {};
                      void addAllDedup(List<Map<String, dynamic>> src) {
                        for (final it in src) {
                          final data = it['data'] as Map<String, dynamic>;
                          final ts = (data['timestamp'] ?? 0).toString();
                          final msg = (data['message'] ?? '').toString();
                          final type = (data['type'] ?? '').toString();
                          final sig = '$type|$ts|$msg';
                          if (seen.add(sig) && !dismissed.contains(sig)) {
                            merged.add(it);
                          }
                        }
                      }

                      addAllDedup(personal);
                      addAllDedup(global);
                      merged.sort((a, b) {
                        final at =
                            ((a['data'] as Map<String, dynamic>)['timestamp'] ??
                                0) as int;
                        final bt =
                            ((b['data'] as Map<String, dynamic>)['timestamp'] ??
                                0) as int;
                        return bt.compareTo(at);
                      });
                      return _buildList(context, merged, dismissedRef);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> items,
      DatabaseReference dismissedRef) {
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
        final notificationKey = items[index]['key'] as String;
        final notificationData =
            Map<String, dynamic>.from(items[index]['data'] as Map);
        final itemRef = items[index]['ref'] as DatabaseReference;
        final src = (items[index]['src'] as String? ?? 'p');
        final tsValue = notificationData['timestamp'];
        final timestamp = tsValue is int
            ? DateTime.fromMillisecondsSinceEpoch(tsValue)
            : null;
        final formattedDate = timestamp != null
            ? DateFormat('MMM d, yyyy - h:mm a').format(timestamp)
            : '';

        final itemCard = Dismissible(
          key: ValueKey<String>('${src}_$notificationKey'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            try {
              final data = notificationData;
              final sig =
                  '${(data['type'] ?? '').toString()}|${(data['timestamp'] ?? 0).toString()}|${(data['message'] ?? '').toString()}';
              if (src == 'g') {
                await dismissedRef.child(sig).set(true);
              } else {
                await itemRef.child(notificationKey).remove();
              }
              return true;
            } catch (_) {
              return false;
            }
          },
          onDismissed: (direction) {
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
          child: RepaintBoundary(
            child: _buildNotificationCard(
              notificationData: notificationData,
              formattedDate: formattedDate,
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

  Widget _buildNotificationCard({
    required Map<String, dynamic> notificationData,
    required String formattedDate,
  }) {
    final notificationType = (notificationData['type'] ?? '').toString();
    final isOrderNotification = notificationType == 'order';

    if (isOrderNotification && notificationData['orderDetails'] != null) {
      return _buildOrderNotificationCard(notificationData, formattedDate);
    } else {
      return _buildSimpleNotificationCard(notificationData, formattedDate);
    }
  }

  Widget _buildSimpleNotificationCard(Map<String, dynamic> data, String date) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.deepOrange,
          child: Icon(Iconsax.message_text_1, color: Colors.white, size: 20),
        ),
        title: Text(data['message'] ?? 'New Notification',
            style: GoogleFonts.poppins()),
        subtitle: Text(date, style: GoogleFonts.poppins(fontSize: 12)),
      ),
    );
  }

  Widget _buildOrderNotificationCard(Map<String, dynamic> data, String date) {
    final orderDetails = Map<String, dynamic>.from(data['orderDetails'] ?? {});
    final products = orderDetails['products'] is List
        ? List<String>.from(orderDetails['products'])
        : <String>[];
    final totalAmount = (orderDetails['totalAmount'] ?? 0.0).toString();
    final deliveryAddress =
        (orderDetails['deliveryAddress'] ?? 'Not specified').toString();
    final location = orderDetails['location'] is Map
        ? Map<String, dynamic>.from(orderDetails['location'])
        : null;
    final customer = orderDetails['customer'] is Map
        ? Map<String, dynamic>.from(orderDetails['customer'])
        : {};

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.shopping_bag,
                      color: Colors.green.shade600, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['message'] ?? 'New Order',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        date,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹$totalAmount',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Products
            if (products.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.box, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Products:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          products.join(', '),
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Customer Info
            if (customer.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.user, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer['name'] ?? 'N/A',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        if (customer['phone'] != null &&
                            customer['phone'] != 'N/A')
                          Text(
                            '📱 ${customer['phone']}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Delivery Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Iconsax.location, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Address:',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deliveryAddress,
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),

                      // Location coordinates if available
                      if (location != null &&
                          location['lat'] != null &&
                          location['lng'] != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.gps,
                                  size: 14, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Lat: ${location['lat']}, Lng: ${location['lng']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
