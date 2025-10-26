import 'package:c_h_p/admin/add_product_page.dart';
import 'package:c_h_p/product/edit_product_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';

// You can rename this class to ManageProductsPage if you'd like
class ManageInventoryPage extends StatefulWidget {
  const ManageInventoryPage({super.key});

  @override
  State<ManageInventoryPage> createState() => _ManageInventoryPageState();
}

class _ManageInventoryPageState extends State<ManageInventoryPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref('products');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _showDeleteDialog(String key, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              dbRef.child(key).remove();
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ⭐ RENAMED: Title is now more specific
        title: Text("Manage Products", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Iconsax.search_normal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          // --- PRODUCT LIST ---
          Expanded(
            child: StreamBuilder(
              stream: dbRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Center(child: Text("No products found."));
                }
                final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

                final filteredList = productsMap.entries.where((entry) {
                  final data = Map<String, dynamic>.from(entry.value);
                  return data['name']?.toLowerCase().contains(_searchQuery) ?? false;
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Text("No products match your search."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final productKey = filteredList[index].key;
                    final productData = Map<String, dynamic>.from(filteredList[index].value);
                    return _buildItemCard(
                      imageUrl: productData['imageUrl'] ?? '',
                      name: productData['name'] ?? 'No Name',
                      subtitle: 'Stock: ${productData['stock'] ?? 0}',
                      onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductPage(productKey: productKey, productData: productData))),
                      onDelete: () => _showDeleteDialog(productKey, productData['name'] ?? 'this item'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // ⭐ UPDATED: FAB now only has one purpose
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductPage()));
        },
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: const Text("Add Product", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// Reusable card widget, no changes needed here
Widget _buildItemCard({
  required String imageUrl,
  required String name,
  required String subtitle,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey.shade200),
            errorWidget: (context, url, error) => const Icon(Iconsax.gallery_slash),
          ),
        ),
        title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Iconsax.edit, color: Colors.blue), onPressed: onEdit, tooltip: 'Edit'),
            IconButton(icon: const Icon(Iconsax.trash, color: Colors.red), onPressed: onDelete, tooltip: 'Delete'),
          ],
        ),
      ),
    ),
  );
}