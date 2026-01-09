import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/app/providers.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _animatedOnce = false;
  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Start VM and mark all as read
        ref.read(notificationsVMProvider.notifier).start(currentUser.uid);
        ref.read(notificationsVMProvider.notifier).markAllRead(currentUser.uid);
        if (mounted) setState(() => _animatedOnce = true);
      });
    }
  }

  // ⭐ NEW: Function to clear all notifications with confirmation
  Future<void> _clearAllNotifications(String uid) async {
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
      await ref.read(notificationsVMProvider.notifier).clearAll(uid);
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

    final uid = currentUser.uid;
    final state = ref.watch(notificationsVMProvider);

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
            onPressed: () => _clearAllNotifications(uid),
          ),
        ],
      ),
      body: _buildList(context, state.entries, uid),
    );
  }

  Widget _buildList(BuildContext context, List entries, String uid) {
    if (entries.isEmpty) {
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
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final it = entries[index];
        final notificationKey = it.key as String;
        final Map<String, dynamic> notificationData =
            it.data as Map<String, dynamic>;
        final String src = it.src as String? ?? 'p';
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
              if (src == 'g') {
                final data = notificationData;
                final sig =
                    '${(data['type'] ?? '').toString()}|${(data['timestamp'] ?? 0).toString()}|${(data['message'] ?? '').toString()}';
                await ref
                    .read(notificationsVMProvider.notifier)
                    .dismissGlobal(uid, sig);
              } else {
                await ref
                    .read(notificationsVMProvider.notifier)
                    .deletePersonal(uid, notificationKey);
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
