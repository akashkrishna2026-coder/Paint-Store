import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../product/edit_product_page.dart'; // We will create this next

class ManageInventoryPage extends StatefulWidget {
  const ManageInventoryPage({super.key});

  @override
  State<ManageInventoryPage> createState() => _ManageInventoryPageState();
}

class _ManageInventoryPageState extends State<ManageInventoryPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('products');

  void _confirmDelete(BuildContext context, String key, String name) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Confirm Deletion', style: GoogleFonts.poppins()),
          content: Text('Are you sure you want to delete "$name"? This is permanent.', style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              child: Text('Cancel', style: GoogleFonts.poppins()),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete', style: GoogleFonts.poppins()),
              onPressed: () {
                _dbRef.child(key).remove();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Product deleted successfully")),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Manage Inventory", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final productsList = productsMap.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: productsList.length,
            itemBuilder: (context, index) {
              final productKey = productsList[index].key;
              final productData = Map<String, dynamic>.from(productsList[index].value);
              final name = productData['name'] ?? 'No Name';
              final price = productData['price'] ?? '0.00';
              final imageUrl = productData['imageUrl'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Iconsax.gallery_slash),
                    ),
                  ),
                  title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Text('₹$price', style: GoogleFonts.poppins()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Iconsax.edit, color: Colors.blue),
                        tooltip: 'Edit Product',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProductPage(
                                productKey: productKey,
                                productData: productData,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.trash, color: Colors.red),
                        tooltip: 'Delete Product',
                        onPressed: () => _confirmDelete(context, productKey, name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the same page but in "Add" mode (no key/data)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProductPage()),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }
}
