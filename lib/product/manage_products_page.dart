import 'package:c_h_p/admin/add_product_page.dart';
import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/product/edit_product_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Ensure the class name matches your file name and usage
class ManageProductsPage extends StatefulWidget {
  const ManageProductsPage({super.key});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('products');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _showDeleteDialog(String key, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              _dbRef.child(key).remove();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('"$name" has been deleted.'),
                    backgroundColor: Colors.red),
              );
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Manage Products",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by product name...',
                prefixIcon: const Icon(Iconsax.search_normal_1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          // --- PRODUCT LIST ---
          Expanded(
            child: StreamBuilder(
              // Order by name for consistency
              stream: _dbRef.orderByChild('name').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Colors.deepOrange));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error loading products: ${snapshot.error}"));
                }
                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return const Center(
                      child:
                          Text("No products found. Add one to get started!"));
                }

                final productsMap = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map);

                // ⭐ 2. CONVERT DATA TO PRODUCT OBJECTS FIRST
                final List<Product> allProducts =
                    productsMap.entries.map((entry) {
                  try {
                    return Product.fromMap(
                        entry.key, Map<String, dynamic>.from(entry.value));
                  } catch (e) {
                    debugPrint(
                        "Error parsing product ${entry.key} for manage page: $e");
                    // Return a dummy product or handle error appropriately
                    return Product(
                        key: entry.key,
                        name: "Error Parsing",
                        description: "",
                        stock: 0,
                        mainImageUrl: "",
                        backgroundImageUrl: "",
                        benefits: [],
                        packSizes: [],
                        brochureUrl: "");
                  }
                }).toList();

                // Filter based on the Product object's name
                final filteredProducts = allProducts.where((product) {
                  return product.name.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                      child: Text("No products match your search."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      16, 16, 16, 100), // Padding includes FAB space
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    // Still need the raw map for the potentially un-updated EditProductPage
                    final productData = Map<String, dynamic>.from(
                        productsMap[product.key] as Map);
                    return _buildProductCard(
                        product, productData); // Pass both product and raw data
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AddProductPage()));
        },
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: Text("Add Product",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ⭐ 3. UPDATED CARD WIDGET to use Product object
  Widget _buildProductCard(
      Product product, Map<String, dynamic> rawProductData) {
    int stock = product.stock;
    Color stockColor;
    if (stock == 0) {
      stockColor = Colors.red.shade700;
    } else if (stock <= 10) {
      stockColor = Colors.orange.shade800;
    } else {
      stockColor = Colors.green.shade800;
    }

    // Get the price of the first pack size to display
    final priceToShow =
        product.packSizes.isNotEmpty ? product.packSizes.first.price : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: Colors.white,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CachedNetworkImage(
                          // ⭐ Use mainImageUrl from Product object
                          imageUrl: product.mainImageUrl,
                          fit: BoxFit.contain,
                          fadeInDuration: const Duration(milliseconds: 160),
                          memCacheWidth: 220,
                          memCacheHeight: 220,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey.shade200),
                          errorWidget: (context, url, error) =>
                              const Center(child: Icon(Iconsax.gallery_slash)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // ⭐ Use name from Product object
                        product.name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // ⭐ Use brand from Product object
                        "Brand: ${product.brand ?? 'N/A'}",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Stock: $stock",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: stockColor)),
                    // ⭐ Display starting price from pack sizes
                    Text("MRP : ₹$priceToShow",
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.edit,
                          color: Colors.blue, size: 20),
                      onPressed: () => Navigator.push(
                        context,
                        // Pass the raw data map to EditProductPage
                        MaterialPageRoute(
                            builder: (_) => EditProductPage(
                                productKey: product.key,
                                productData: rawProductData)),
                      ),
                      tooltip: 'Edit Product',
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.trash,
                          color: Colors.red, size: 20),
                      // ⭐ Use key and name from Product object
                      onPressed: () =>
                          _showDeleteDialog(product.key, product.name),
                      tooltip: 'Delete Product',
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
}
