import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  String? _expandedOrderId;

  final List<String> _statusOptions = [
    'Pending',
    'Confirmed',
    'Processing',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'out for delivery':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Iconsax.clock;
      case 'confirmed':
        return Iconsax.tick_circle;
      case 'processing':
        return Iconsax.box_time;
      case 'out for delivery':
        return Iconsax.truck_fast;
      case 'delivered':
        return Iconsax.verify;
      case 'cancelled':
        return Iconsax.close_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  Future<void> _updateOrderStatus({
    required String orderId,
    required String userId,
    required String status,
    DateTime? eta,
    String? notes,
  }) async {
    final updates = {
      'manager/status': status,
      if (eta != null) 'manager/eta': eta.toIso8601String(),
      'manager/lastUpdated': DateTime.now().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'manager/notes': notes,
    };

    await _db.child('orders/$orderId').update(updates);
    await _db.child('users/$userId/orders/$orderId').update(updates);

    final notifRef = _db.child('users/$userId/notifications').push();
    final nowStr = DateTime.now().toIso8601String();
    final etaStr =
        eta != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(eta) : '';
    final title = 'Order #$orderId $status';
    final body =
        etaStr.isNotEmpty ? 'ETA: $etaStr' : 'Status updated to $status';
    await notifRef.set({
      'id': notifRef.key,
      'orderId': orderId,
      'type': 'order_status',
      'title': title,
      'message': body,
      'status': status,
      'eta': eta?.toIso8601String(),
      'isRead': false,
      'createdAt': nowStr,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getStatusIcon(status), color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Order updated to "$status"')),
          ],
        ),
        backgroundColor: _getStatusColor(status),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickDateTime(
      BuildContext context, Map<String, dynamic> order) async {
    if (!mounted) return;

    final now = DateTime.now();
    final currentEta = order['manager']?['eta'];
    DateTime initialDate = now;

    if ((currentEta?.toString().isNotEmpty) ?? false) {
      try {
        initialDate = DateTime.parse(currentEta.toString());
      } catch (e) {
        initialDate = now;
      }
    }

    if (!mounted) return;

    // Capture context before async operations
    final BuildContext dialogContext = context;

    final date = await showDatePicker(
      context: dialogContext,
      initialDate: initialDate.isAfter(now) ? initialDate : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.pink.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: dialogContext,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.pink.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null || !mounted) return;

    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    await _updateOrderStatus(
      orderId: order['orderId'] ?? '',
      userId: order['userId'] ?? '',
      status: order['manager']?['status'] ?? 'Pending',
      eta: selectedDateTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Manage Orders',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.pink.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _db.child('orders').orderByChild('timestamp').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.pink));
          }

          final data = snapshot.data?.snapshot.value;
          if (data == null || data is! Map) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.receipt_minus,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No orders yet',
                      style: GoogleFonts.poppins(
                          fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final orders = Map<String, dynamic>.from(data)
              .values
              .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(e as Map))
              .toList()
            ..sort((a, b) => ((b['timestamp'] ?? 0) as int)
                .compareTo((a['timestamp'] ?? 0) as int));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _buildOrderCard(orders[i]),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['orderId'] ?? '';
    final userId = order['userId'] ?? '';
    final items = (order['items'] is List)
        ? List<String>.from(order['items'])
        : <String>[];
    final manager = (order['manager'] is Map)
        ? Map<String, dynamic>.from(order['manager'])
        : {};
    final status = (manager['status'] ?? 'Pending').toString();
    final etaStr = (manager['eta'] ?? '').toString();
    final customerName = order['customer']?['name'] ?? 'Unknown';
    final orderTotal = (order['orderTotal'] ?? 0).toString();
    final timestamp = order['timestamp'] ?? 0;
    final isExpanded = _expandedOrderId == orderId;

    DateTime? eta;
    if (etaStr.isNotEmpty) {
      try {
        eta = DateTime.parse(etaStr);
      } catch (e) {
        eta = null;
      }
    }

    return Card(
      elevation: isExpanded ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedOrderId = isExpanded ? null : orderId;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Iconsax.receipt_text,
                            color: Colors.pink.shade600, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #$orderId',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTimestamp(timestamp),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Customer & Total
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(Iconsax.user, customerName),
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(Iconsax.money_4, '₹$orderTotal',
                          isPrimary: true),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status Badge
                  _buildStatusBadge(status),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items
                  if (items.isNotEmpty) ...[
                    Text(
                      'Items (${items.length})',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: items
                          .map((item) => Chip(
                                label: Text(item,
                                    style: GoogleFonts.poppins(fontSize: 12)),
                                backgroundColor: Colors.grey.shade100,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 0),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Status Dropdown
                  Text(
                    'Order Status',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusOptions.contains(status)
                            ? status
                            : 'Pending',
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        borderRadius: BorderRadius.circular(12),
                        items: _statusOptions
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Row(
                                    children: [
                                      Icon(_getStatusIcon(s),
                                          size: 18, color: _getStatusColor(s)),
                                      const SizedBox(width: 10),
                                      Text(s,
                                          style: GoogleFonts.poppins(
                                              fontSize: 14)),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (newStatus) async {
                          if (newStatus != null) {
                            await _updateOrderStatus(
                              orderId: orderId,
                              userId: userId,
                              status: newStatus,
                              eta: eta,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ETA Picker
                  Text(
                    'Estimated Time of Arrival',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _pickDateTime(context, order),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.calendar,
                              color: Colors.pink.shade600, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              eta != null
                                  ? DateFormat('MMM dd, yyyy - hh:mm a')
                                      .format(eta)
                                  : 'Tap to set ETA',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: eta != null
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Icon(Iconsax.arrow_right_3,
                              color: Colors.grey.shade400, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.pink.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isPrimary ? Colors.pink.shade600 : Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
                color: isPrimary ? Colors.pink.shade700 : Colors.grey.shade800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return 'Unknown date';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today at ${DateFormat('hh:mm a').format(date)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday at ${DateFormat('hh:mm a').format(date)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
