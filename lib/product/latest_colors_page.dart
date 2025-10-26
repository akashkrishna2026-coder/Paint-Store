import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/product/product_detail_page.dart';

Color hexToColor(String code) {
  try {
    final c = code.trim();
    final hex = c.startsWith('#') ? c.substring(1) : c;
    return Color(int.parse(hex, radix: 16) + 0xFF000000);
  } catch (_) {
    return const Color(0xFFCCCCCC);
  }
}

class LatestColorsPage extends StatefulWidget {
  const LatestColorsPage({super.key});

  @override
  State<LatestColorsPage> createState() => _LatestColorsPageState();
}

class _LatestColorsPageState extends State<LatestColorsPage> {
  final _db = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Latest Colors', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.pink.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _db.child('latestColors').orderByChild('timestamp').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.snapshot.value;
          if (data == null || data is! Map) {
            return Center(child: Text('No latest colors added yet', style: GoogleFonts.poppins(color: Colors.grey)));
          }
          final items = Map<String, dynamic>.from(data).entries.toList()
            ..sort((a, b) => ((b.value['timestamp'] ?? 0) as int).compareTo((a.value['timestamp'] ?? 0) as int));

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final v = Map<String, dynamic>.from(items[i].value);
              final name = (v['name'] ?? '').toString();
              final hex = (v['hex'] ?? v['hexCode'] ?? '#CCCCCC').toString();
              final color = hexToColor(hex);
              final code = (v['code'] ?? '').toString();
              return GestureDetector(
                onTap: () async {
                  if (code.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shade code missing for this color')));
                    return;
                  }
                  try {
                    final linkSnap = await _db.child('shadeLinks/$code').get();
                    if (linkSnap.exists && linkSnap.value is Map) {
                      final link = Map<String, dynamic>.from(linkSnap.value as Map);
                      final String? productId = link['productId']?.toString();
                      if (productId != null && productId.isNotEmpty) {
                        final prodSnap = await _db.child('products/$productId').get();
                        if (prodSnap.exists && prodSnap.value is Map) {
                          final product = Product.fromMap(productId, Map<String, dynamic>.from(prodSnap.value as Map));
                          if (!context.mounted) return;
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)));
                          return;
                        }
                      }
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No product linked to this shade yet')));
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open: $e')));
                  }
                },
                child: _ShadeCard(name: name, code: code, hex: hex, color: color),
              );
            },
          );
        },
      ),
    );
  }
}

class _ShadeCard extends StatelessWidget {
  final String name;
  final String code;
  final String hex;
  final Color color;
  const _ShadeCard({required this.name, required this.code, required this.hex, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Container(decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))))),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(code, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    Text(hex, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

