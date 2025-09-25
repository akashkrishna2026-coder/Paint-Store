import 'package:c_h_p/admin/add_product_page.dart';
import 'package:c_h_p/product/edit_product_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../model/product_model.dart';

class ManageInventoryPage extends StatelessWidget {
  const ManageInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('products');

    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Inventory", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No products found. Add one to get started!"));
          }

          final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final productsList = productsMap.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Space for the FAB
            itemCount: productsList.length,
            itemBuilder: (context, index) {
              final productKey = productsList[index].key;
              final productData = Map<String, dynamic>.from(productsList[index].value);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(productData['imageUrl'] ?? ''),
                  ),
                  title: Text(productData['name'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text('Stock: ${productData['stock'] ?? 0}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Iconsax.edit, color: Colors.blue),
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
                        onPressed: () => dbRef.child(productKey).remove(),
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductPage()));
        },
        backgroundColor: Colors.pink.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}