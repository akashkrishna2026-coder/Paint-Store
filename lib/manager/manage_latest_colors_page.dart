import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ManageLatestColorsPage extends StatefulWidget {
  const ManageLatestColorsPage({super.key});

  @override
  State<ManageLatestColorsPage> createState() => _ManageLatestColorsPageState();
}

class _ManageLatestColorsPageState extends State<ManageLatestColorsPage> {
  final _db = FirebaseDatabase.instance.ref();
  final TextEditingController _catalogSearch = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _catalogSearch.addListener(() => setState(() => _query = _catalogSearch.text.trim()));
  }

  Future<void> _addShade(Map<String, String> shade) async {
    final code = shade['code'] ?? '';
    if (code.isEmpty) return;
    try {
      await _db.child('latestColors/$code').set({
        'name': shade['name'] ?? '',
        'hex': shade['hex'] ?? '#FFFFFF',
        'code': code,
        'timestamp': ServerValue.timestamp,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Latest Colors')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _deleteShade(String code) async {
    try {
      await _db.child('latestColors/$code').remove();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _replaceShade(String code) async {
    // pick a new shade from catalogue (bottom sheet)
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final search = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.8,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: search,
                        decoration: const InputDecoration(prefixIcon: Icon(Iconsax.search_normal), hintText: 'Search shade by code or name'),
                        onChanged: (_) => setSt(() {}),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<DatabaseEvent>(
                        stream: _db.child('colorCategories').onValue,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                            return const Center(child: Text('No catalogue'));
                          }
                          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                          final List<Map<String, String>> shades = [];
                          data.forEach((categoryKey, shadesData) {
                            if (shadesData is Map) {
                              final family = Map<String, dynamic>.from(shadesData);
                              family.forEach((shadeCode, shadeDetails) {
                                if (shadeDetails is Map) {
                                  final m = Map<String, dynamic>.from(shadeDetails);
                                  final s = {
                                    'code': shadeCode.toString(),
                                    'name': (m['name'] ?? '').toString(),
                                    'hex': (m['hex'] ?? '#FFFFFF').toString(),
                                  };
                                  final q = search.text.trim().toLowerCase();
                                  if (q.isEmpty || s['code']!.toLowerCase().contains(q) || s['name']!.toLowerCase().contains(q)) {
                                    shades.add(s);
                                  }
                                }
                              });
                            }
                          });
                          shades.sort((a, b) => a['name']!.compareTo(b['name']!));
                          return ListView.separated(
                            itemCount: shades.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final s = shades[i];
                              return ListTile(
                                leading: Container(width: 24, height: 24, decoration: BoxDecoration(color: _hexToColor(s['hex']!), borderRadius: BorderRadius.circular(6))),
                                title: Text('${s['name']} (${s['code']})', style: GoogleFonts.poppins()),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  final messenger = ScaffoldMessenger.of(context);
                                  await _db.child('latestColors/$code').set({
                                    'name': s['name'],
                                    'hex': s['hex'],
                                    'code': s['code'],
                                    'timestamp': ServerValue.timestamp,
                                  });
                                  if (!mounted) return;
                                  messenger.showSnackBar(const SnackBar(content: Text('Updated')));
                                },
                              );
                            },
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Latest Colors', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.pink.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Add from Catalogue
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _catalogSearch,
              decoration: InputDecoration(
                hintText: 'Add from catalogue by code or name',
                prefixIcon: const Icon(Iconsax.search_normal),
                suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.close), onPressed: () { _catalogSearch.clear(); }) : null,
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: StreamBuilder<DatabaseEvent>(
              stream: _db.child('colorCategories').onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No catalogue'));
                }
                final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final List<Map<String, String>> shades = [];
                data.forEach((categoryKey, shadesData) {
                  if (shadesData is Map) {
                    final family = Map<String, dynamic>.from(shadesData);
                    family.forEach((shadeCode, shadeDetails) {
                      if (shadeDetails is Map) {
                        final m = Map<String, dynamic>.from(shadeDetails);
                        final s = {
                          'code': shadeCode.toString(),
                          'name': (m['name'] ?? '').toString(),
                          'hex': (m['hex'] ?? '#FFFFFF').toString(),
                        };
                        final q = _query.toLowerCase();
                        if (q.isEmpty || s['code']!.toLowerCase().contains(q) || s['name']!.toLowerCase().contains(q)) {
                          shades.add(s);
                        }
                      }
                    });
                  }
                });
                shades.sort((a, b) => a['name']!.compareTo(b['name']!));
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: shades.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final s = shades[i];
                    return GestureDetector(
                      onTap: () => _addShade(s),
                      child: Container(
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(color: _hexToColor(s['hex']!), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s['name']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(s['code']!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                    Text(s['hex']!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ]),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Current latest list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Current Latest', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox.shrink(),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _db.child('latestColors').orderByChild('timestamp').onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No latest colors'));
                }
                final list = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map).entries.toList()
                  ..sort((a, b) => ((b.value['timestamp'] ?? 0) as int).compareTo((a.value['timestamp'] ?? 0) as int));

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final v = Map<String, dynamic>.from(list[i].value);
                    final name = (v['name'] ?? '').toString();
                    final hex = (v['hex'] ?? v['hexCode'] ?? '#CCCCCC').toString();
                    final code = (v['code'] ?? '').toString();
                    return Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: ListTile(
                        leading: Container(width: 28, height: 28, decoration: BoxDecoration(color: _hexToColor(hex), borderRadius: BorderRadius.circular(6))),
                        title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Text('$code   $hex', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(tooltip: 'Replace', icon: const Icon(Iconsax.refresh_circle), onPressed: () => _replaceShade(code)),
                            IconButton(tooltip: 'Delete', icon: const Icon(Iconsax.trash), onPressed: () => _deleteShade(code)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String code) {
    try {
      final hex = code.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFCCCCCC);
    }
  }
}
