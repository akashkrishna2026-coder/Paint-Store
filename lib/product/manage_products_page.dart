import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin/add_product_page.dart'; // We will create this next

class ManageProductsPage extends StatefulWidget {
  const ManageProductsPage({super.key});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('products');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Products", style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No products found."));
          }

          final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final productsList = productsMap.entries.toList();

          return ListView.builder(
            itemCount: productsList.length,
            itemBuilder: (context, index) {
              final productKey = productsList[index].key;
              final productData = Map<String, dynamic>.from(productsList[index].value);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(productData['imageUrl'] ?? ''),
                    backgroundColor: Colors.grey[200],
                  ),
                  title: Text(productData['name'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Text('\$${productData['price'] ?? ''}', style: GoogleFonts.poppins()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _dbRef.child(productKey).remove(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
        },
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
      ),
    );
  }
}