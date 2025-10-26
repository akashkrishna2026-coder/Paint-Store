import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> _updateOrderStatus({
    required String orderId,
    required String userId,
    required String status,
    String? eta,
    String? notes,
  }) async {
    final updates = {
      'manager/status': status,
      if (eta != null) 'manager/eta': eta,
      if (notes != null && notes.isNotEmpty) 'manager/notes': notes,
    };
    await _db.child('orders/$orderId').update(updates);
    await _db.child('users/$userId/orders/$orderId').update(updates);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order $orderId updated to "$status"'), duration: const Duration(seconds: 1)),
    );
  }

  void _showUpdateDialog(Map<String, dynamic> order) {
    final statusController = TextEditingController(text: (order['manager']?['status'] ?? '').toString());
    final etaController = TextEditingController(text: (order['manager']?['eta'] ?? '').toString());
    final notesController = TextEditingController(text: (order['manager']?['notes'] ?? '').toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Order', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: statusController, decoration: const InputDecoration(labelText: 'Status (e.g., processing, out_for_delivery, delivered)')),
            const SizedBox(height: 8),
            TextField(controller: etaController, decoration: const InputDecoration(labelText: 'ETA (e.g., Today 5 PM or 2025-10-25 17:00)')),
            const SizedBox(height: 8),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateOrderStatus(
                orderId: order['orderId'] ?? '',
                userId: order['userId'] ?? '',
                status: statusController.text.trim().isEmpty ? 'processing' : statusController.text.trim(),
                eta: etaController.text.trim().isEmpty ? null : etaController.text.trim(),
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Orders', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.pink.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _db.child('orders').orderByChild('timestamp').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.snapshot.value;
          if (data == null || data is! Map) {
            return Center(child: Text('No orders yet', style: GoogleFonts.poppins()));
          }
          final orders = Map<String, dynamic>.from(data).values
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
              .toList()
            ..sort((a, b) => ((b['timestamp'] ?? 0) as int).compareTo((a['timestamp'] ?? 0) as int));

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final o = orders[i];
              final items = (o['items'] is List) ? List<String>.from(o['items']) : <String>[];
              final manager = (o['manager'] is Map) ? Map<String, dynamic>.from(o['manager']) : {};
              final status = (manager['status'] ?? 'pending').toString();
              final eta = (manager['eta'] ?? '').toString();
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Iconsax.receipt, color: Colors.pink),
                  title: Text('Order: ${o['orderId'] ?? ''}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'User: ${o['customer']?['name'] ?? o['userId']}\n' 
                    'Total: ₹${(o['orderTotal'] ?? 0).toString()}\n' 
                    'Status: $status${eta.isNotEmpty ? ' | ETA: $eta' : ''}\n'
                    'Items: ${items.join(', ')}',
                    style: GoogleFonts.poppins(height: 1.3),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Iconsax.edit),
                    onPressed: () => _showUpdateDialog(o),
                    tooltip: 'Update status / ETA',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
