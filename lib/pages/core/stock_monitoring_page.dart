import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../model/product_model.dart';

class StockMonitoringPage extends StatefulWidget {
  const StockMonitoringPage({super.key});

  @override
  State<StockMonitoringPage> createState() => _StockMonitoringPageState();
}

class _StockMonitoringPageState extends State<StockMonitoringPage> {
  final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('products');

  Future<void> _updateStock(String productKey, int newStock) async {
    try {
      await _productsRef.child(productKey).update({'stock': newStock});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update stock: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showUpdateStockDialog(Product product) {
    final stockController = TextEditingController(text: product.stock.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Stock", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: stockController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "New Quantity for ${product.name}",
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quantity.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newStock = int.tryParse(stockController.text) ?? product.stock;
                  _updateStock(product.key, newStock);
                  Navigator.pop(context);
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Monitor Stock", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _productsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No products found in inventory."));
          }

          final Map<String, Map<String, List<Product>>> categorizedStock = {};
          final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          productsMap.forEach((key, value) {
            final product = Product.fromMap(key, Map<String, dynamic>.from(value));
            categorizedStock.putIfAbsent(product.category, () => {});
            categorizedStock[product.category]!.putIfAbsent(product.brand, () => []);
            categorizedStock[product.category]![product.brand]!.add(product);
          });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: categorizedStock.entries.map((categoryEntry) {
              return _buildCategoryExpansionTile(
                categoryName: categoryEntry.key,
                brandsData: categoryEntry.value,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildCategoryExpansionTile({
    required String categoryName,
    required Map<String, List<Product>> brandsData,
  }) {
    // Calculate total stock for the category
    int totalStockInCategory = brandsData.values
        .expand((products) => products)
        .fold(0, (sum, product) => sum + product.stock);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(_getIconForCategory(categoryName), color: Colors.pink.shade600),
        title: Text(categoryName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        trailing: Chip(
          label: Text("Total Stock: $totalStockInCategory", style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.pink.shade50,
        ),
        children: brandsData.entries.map((brandEntry) {
          int totalStockInBrand = brandEntry.value.fold(0, (sum, product) => sum + product.stock);
          return ExpansionTile(
            title: Text(brandEntry.key, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            trailing: Chip(label: Text("Stock: $totalStockInBrand"), backgroundColor: Colors.grey.shade200),
            children: brandEntry.value.map((product) {
              return ListTile(
                title: Text(product.name),
                subtitle: Text(product.subCategory, style: TextStyle(color: Colors.grey.shade600)),
                trailing: Text("Qty: ${product.stock}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: product.stock > 0 ? Colors.green.shade700 : Colors.red)),
                onTap: () => _showUpdateStockDialog(product),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForCategory(String categoryName) {
    switch (categoryName) {
      case 'Interior':
        return Iconsax.gallery;
      case 'Exterior':
        return Iconsax.building_4;
      case 'Waterproofing':
        return Iconsax.shield_tick;
      case 'Wood Finishes':
        return Iconsax.colorfilter;
      case 'Others':
        return Iconsax.shapes;
      default:
        return Iconsax.box;
    }
  }
}