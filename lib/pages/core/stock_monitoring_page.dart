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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Updates the stock for a given product in Firebase.
  Future<void> _updateStock(String productKey, int newStock) async {
    final stockToUpdate = newStock < 0 ? 0 : newStock; // Prevent negative stock
    try {
      await _productsRef.child(productKey).update({'stock': stockToUpdate});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
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

  // Shows a dialog for manually entering a new stock quantity.
  void _showUpdateStockDialog(Product product) {
    final stockController = TextEditingController(text: product.stock.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Update Stock", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: stockController,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "New Quantity for ${product.name}",
                border: const OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a quantity.' : null,
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Monitor Stock", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name...',
                prefixIcon: const Icon(Iconsax.search_normal_1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _productsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No products found."));
          }

          final Map<String, Map<String, List<Product>>> categorizedStock = {};
          final productsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          productsMap.forEach((key, value) {
            final product = Product.fromMap(key, Map<String, dynamic>.from(value));
            if (_searchQuery.isEmpty || product.name.toLowerCase().contains(_searchQuery)) {

              // ⭐ FIX: Provide a default value if category or brand is null
              final String categoryKey = product.category ?? 'Uncategorized';
              final String brandKey = product.brand ?? 'Unbranded';

              categorizedStock.putIfAbsent(categoryKey, () => {});
              categorizedStock[categoryKey]!.putIfAbsent(brandKey, () => []);
              categorizedStock[categoryKey]![brandKey]!.add(product);
            }
          });

          if (categorizedStock.isEmpty && _searchQuery.isNotEmpty) {
            return const Center(child: Text("No products match your search."));
          }

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
    int totalStockInCategory = brandsData.values
        .expand((products) => products)
        .fold(0, (sum, product) => sum + product.stock);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(_getIconForCategory(categoryName), color: Colors.deepOrange),
        title: Text(categoryName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: Chip(
          label: Text("Total: $totalStockInCategory", style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange.shade50,
          labelStyle: const TextStyle(color: Colors.deepOrange),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        children: brandsData.entries.map((brandEntry) {
          int totalStockInBrand = brandEntry.value.fold(0, (sum, product) => sum + product.stock);
          return ExpansionTile(
            title: Text(brandEntry.key, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            trailing: Chip(label: Text("Stock: $totalStockInBrand"), backgroundColor: Colors.grey.shade200),
            children: brandEntry.value.map((product) => _buildProductListItem(product)).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductListItem(Product product) {
    Color stockColor;
    if (product.stock == 0) {
      stockColor = Colors.red.shade700;
    } else if (product.stock <= 10) {
      stockColor = Colors.orange.shade800;
    } else {
      stockColor = Colors.green.shade800;
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              product.subCategory ?? 'General', // Safely handle nullable subCategory
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current Stock", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      product.stock.toString(),
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.box_remove),
                      onPressed: () => _updateStock(product.key, 0),
                      tooltip: "Set to Out of Stock",
                      color: Colors.red.shade400,
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.minus_square),
                      onPressed: () => _updateStock(product.key, product.stock - 1),
                      tooltip: "Decrease Stock",
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.add_square),
                      onPressed: () => _updateStock(product.key, product.stock + 1),
                      tooltip: "Increase Stock",
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.edit),
                      onPressed: () => _showUpdateStockDialog(product),
                      tooltip: "Edit Quantity",
                      color: Colors.blue.shade600,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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