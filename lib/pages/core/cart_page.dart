import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
// Remove incorrect ProductDetailPage imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/app/providers.dart';

// Ensure these import paths match your project structure
import '../../model/product_model.dart';
import 'checkout_form_page.dart';
import '../../product/explore_product.dart'; // For browsing
import '../../product/explore/interior_page.dart';
import '../../product/explore/exterior_page.dart';
import '../../product/latest_colors_page.dart';

// CORRECTED Import for ProductDetailPage using relative path
import '../../product/product_detail_page.dart';

// Helper class to hold combined Cart Item and Product details
class CartItemDetails {
  final String productKey;
  final Map<String, dynamic> cartData;
  final Product? productDetails;

  CartItemDetails({
    required this.productKey,
    required this.cartData,
    this.productDetails,
  });

  String get name =>
      cartData['name'] ?? productDetails?.name ?? 'Unknown Product';
  String get imageUrl =>
      cartData['mainImageUrl'] ?? productDetails?.mainImageUrl ?? '';
  int get quantity => cartData['quantity'] ?? 0;
  String get selectedSize => cartData['selectedSize'] ?? '';
  String get selectedPrice => cartData['selectedPrice'] ?? '0';
  List<PackSize> get availableSizes => productDetails?.packSizes ?? [];
}

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Cache product details to avoid re-fetching on every quantity change
  Map<String, Product?> _productCache = {};
  String _lastKeysSignature = '';
  bool _justQuantityChange = false;
  final Map<String, Timer> _qtyDebounce = {};

  double _parsePrice(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^0-9\.]'), '');
    return double.tryParse(sanitized) ?? 0.0;
  }

  // Debounced typed quantity updater
  void _scheduleTypedQtyUpdate(String productKey, String raw,
      {required int availableStock}) {
    // sanitize input
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    int? parsed = int.tryParse(digits);
    if (parsed == null) {
      return; // ignore until a number appears
    }
    if (availableStock > 0) {
      if (parsed < 1) parsed = 1;
      if (parsed > availableStock) parsed = availableStock;
    } else {
      if (parsed < 1) parsed = 1;
    }

    // debounce per product
    _qtyDebounce[productKey]?.cancel();
    _qtyDebounce[productKey] = Timer(const Duration(milliseconds: 400), () {
      _updateQuantity(productKey, parsed!);
    });
  }

  // --- Cart Modification Functions ---
  void _updateQuantity(String productKey, int newQuantity) {
    if (_auth.currentUser == null) return;
    _justQuantityChange = true;
    if (newQuantity > 0) {
      ref
          .read(cartVMProvider.notifier)
          .updateQuantity(productKey: productKey, quantity: newQuantity);
    } else {
      ref.read(cartVMProvider.notifier).removeItem(productKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Item removed"), duration: Duration(seconds: 1)));
      }
    }
  }

  // Helper to update quantity with known stock clamp from UI (prevents exceeding stock)
  void _incrementWithStockClamp(CartItemDetails item) {
    final stock = item.productDetails?.stock ?? 0;
    if (stock <= 0) return; // nothing available
    final nextQty = (item.quantity + 1) > stock ? stock : (item.quantity + 1);
    if (nextQty == item.quantity) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Only $stock in stock'),
              duration: const Duration(seconds: 1)),
        );
      }
      return;
    }
    _updateQuantity(item.productKey, nextQty);
  }

  void _updateSelectedSize(String productKey, PackSize newPackSize) {
    if (_auth.currentUser == null) return;
    ref.read(cartVMProvider.notifier).changeSize(
          productKey: productKey,
          size: newPackSize.size,
          price: newPackSize.price,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Size updated to ${newPackSize.size}"),
            duration: Duration(seconds: 1)),
      );
    }
  }

  void _clearCart() {
    if (_auth.currentUser == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Clear Cart",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Remove all items from your cart?",
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(ctx).pop()),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text("Clear All"),
            onPressed: () {
              ref.read(cartVMProvider.notifier).clearCart();
              Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Cart cleared"),
                      backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // AppBar is built dynamically
      body: currentUser == null
          ? _buildLoggedOutState()
          : Builder(builder: (context) {
              final cartState = ref.watch(cartVMProvider);
              if (cartState.loading && cartState.items.isEmpty) {
                return Scaffold(
                    appBar: _buildAppBar(false),
                    body: _buildCartLoadingShimmer(3));
              }
              if (cartState.error != null) {
                return Scaffold(
                    appBar: _buildAppBar(false),
                    body: Center(
                        child: Text("Error: ${cartState.error}",
                            style: TextStyle(color: Colors.red))));
              }
              final cartMap = cartState.items;
              final bool isCartEmpty = cartMap.isEmpty;
              if (isCartEmpty) {
                return Scaffold(
                    appBar: _buildAppBar(false), body: _buildEmptyCart());
              }
              final productKeys = cartMap.keys.toList();
              return FutureBuilder<Map<String, Product?>>(
                future: _getProductDetailsCached(productKeys),
                builder: (context, productDetailsSnapshot) {
                  Widget bodyContent;
                  List<CartItemDetails> cartItemsWithDetails = [];

                  if (productDetailsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    bodyContent = _buildCartLoadingShimmer(cartMap.length);
                  } else if (productDetailsSnapshot.hasError) {
                    bodyContent = Center(
                        child: Text("Error: ${productDetailsSnapshot.error}",
                            style: TextStyle(color: Colors.red)));
                  } else {
                    final productDetailsMap = productDetailsSnapshot.data ?? {};
                    cartItemsWithDetails = cartMap.entries
                        .map((entry) {
                          return CartItemDetails(
                            productKey: entry.key,
                            cartData: Map<String, dynamic>.from(entry.value),
                            productDetails: productDetailsMap[entry.key],
                          );
                        })
                        .where((item) => item.productDetails != null)
                        .toList();

                    if (cartItemsWithDetails.isEmpty && cartMap.isNotEmpty) {
                      bodyContent = Center(
                          child: Text("Items may have been removed.",
                              style: TextStyle(color: Colors.orange.shade800)));
                    } else if (cartItemsWithDetails.isEmpty) {
                      bodyContent = _buildEmptyCart();
                    } else {
                      bodyContent = _buildCartContent(cartItemsWithDetails);
                    }
                  }

                  return Scaffold(
                    backgroundColor: Colors.grey.shade100,
                    appBar: _buildAppBar(
                      cartItemsWithDetails.isNotEmpty && !isCartEmpty,
                      itemCount: cartItemsWithDetails.isNotEmpty
                          ? cartItemsWithDetails.length
                          : null,
                    ),
                    body: bodyContent,
                  );
                },
              );
            }),
    );
  }

  // --- Helper to build AppBar ---
  AppBar _buildAppBar(bool showClearButton, {int? itemCount}) {
    final countText = itemCount != null ? '  ($itemCount)' : '';
    return AppBar(
      centerTitle: true,
      title: Text(
        "My Cart$countText",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.grey.shade800),
      actions: showClearButton
          ? [
              IconButton(
                icon: const Icon(Iconsax.trash),
                onPressed: _clearCart,
                tooltip: 'Clear Cart',
              ),
            ]
          : [],
    );
  }

  // --- Helper to Fetch Product Details ---
  Future<Map<String, Product?>> _fetchAllProductDetails(
      List<String> productKeys) async {
    final Map<String, Product?> detailsMap = {};
    // Fire all reads in parallel to reduce total wait time.
    final futures = productKeys.map((key) async {
      try {
        final snapshot = await _dbRef.child('products/$key').get();
        if (snapshot.exists && snapshot.value != null) {
          detailsMap[key] = Product.fromMap(
              key, Map<String, dynamic>.from(snapshot.value as Map));
        } else {
          detailsMap[key] = null;
        }
      } catch (e) {
        debugPrint("Error fetching details for product $key: $e");
        detailsMap[key] = null;
      }
    }).toList();
    await Future.wait(futures);
    return detailsMap;
  }

  // Cached fetch: reuse details when product keys set hasn't changed
  Future<Map<String, Product?>> _getProductDetailsCached(
      List<String> productKeys) async {
    final sorted = List<String>.from(productKeys)..sort();
    final signature = sorted.join('|');
    if (_lastKeysSignature == signature && _productCache.isNotEmpty) {
      return _productCache;
    }
    final fetched = await _fetchAllProductDetails(productKeys);
    _lastKeysSignature = signature;
    _productCache = fetched;
    return fetched;
  }

  // --- UI Building Widgets ---
  Widget _buildLoggedOutState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.login, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text("Please log in to view your cart.",
              style: GoogleFonts.poppins(
                  fontSize: 16, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.shopping_cart, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("Your Cart is Empty",
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800)),
            const SizedBox(height: 8),
            Text("Add items you want to buy.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Iconsax.shop, size: 20),
              label: Text("Start Shopping",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExploreProductPage()),
                    (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
            Text("Maybe check these out?",
                style: GoogleFonts.poppins(
                    fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ActionChip(
                  label: const Text("Interior Paints"),
                  avatar: Icon(Iconsax.home,
                      size: 16, color: Colors.deepOrange.shade300),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const InteriorPage()));
                  },
                ),
                ActionChip(
                  label: const Text("Exterior Emulsions"),
                  avatar: Icon(Iconsax.building_4,
                      size: 16, color: Colors.blue.shade300),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ExteriorPage()));
                  },
                ),
                ActionChip(
                  label: const Text("New Arrivals"),
                  avatar: Icon(Iconsax.star,
                      size: 16, color: Colors.amber.shade400),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LatestColorsPage()));
                  },
                ),
              ],
            )
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }

  Widget _buildCartContent(List<CartItemDetails> items) {
    double subtotal = 0;
    for (var item in items) {
      final price = _parsePrice(item.selectedPrice);
      subtotal += price * item.quantity;
    }
    // Suppress animations if this rebuild was triggered by quantity change
    final animateItems = !_justQuantityChange;
    if (_justQuantityChange) {
      // reset flag in next microtask to allow future animations
      Future.microtask(() => _justQuantityChange = false);
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            cacheExtent: 600,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final card = _buildCartItem(item);
              if (!animateItems) return card;
              return card
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (100 * index).ms)
                  .moveY(begin: 20, curve: Curves.easeOutCubic);
            },
          ),
        ),
        _buildOrderSummary(subtotal, items),
      ],
    );
  }

  // Builds a single cart item card
  Widget _buildCartItem(CartItemDetails item) {
    // --- Determine Selected Pack Size ---
    PackSize? currentSelectedPackSizeObject;
    if (item.productDetails != null && item.availableSizes.isNotEmpty) {
      try {
        currentSelectedPackSizeObject = item.availableSizes
            .firstWhere((ps) => ps.size == item.selectedSize);
      } catch (e) {
        try {
          currentSelectedPackSizeObject = item.availableSizes.firstWhere((ps) =>
              ps.price.isNotEmpty && ps.price != '0' && ps.price != 'N/A');
        } catch (e2) {/* remains null */}
      }
    }
    final PackSize currentSelectedPackSize = currentSelectedPackSizeObject ??
        PackSize(size: item.selectedSize, price: item.selectedPrice);
    // --- Calculate Line Item Total ---
    final double itemPrice = _parsePrice(currentSelectedPackSize.price);
    final double lineTotal = item.quantity * itemPrice;

    final int availableStock = item.productDetails?.stock ?? 0;
    final bool atMax = availableStock > 0 && item.quantity >= availableStock;

    return Dismissible(
      key: Key(item.productKey + currentSelectedPackSize.size),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        ref.read(cartVMProvider.notifier).removeItem(item.productKey);
      },
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(16)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Icon(Iconsax.trash, color: Colors.white),
          SizedBox(width: 8),
          Text('Remove',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
        ]),
      ),
      child: Container(
        // Card Content
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image ---
            RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    memCacheWidth: 160,
                    fadeInDuration: const Duration(milliseconds: 120),
                    fadeOutDuration: const Duration(milliseconds: 80),
                    placeholder: (c, u) => Container(
                        width: 80, height: 80, color: Colors.grey.shade200),
                    errorWidget: (c, u, e) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Iconsax.gallery_slash))),
              ),
            ),
            const SizedBox(width: 16),
            // --- Details Column ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Product Name (Tappable) ---
                  GestureDetector(
                    onTap: item.productDetails != null
                        ? () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ProductDetailPage(
                                        product: item.productDetails!)));
                          }
                        : null,
                    child: Text(
                      item.name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: item.productDetails != null
                              ? Colors.black87
                              : Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // --- Pack Size ---
                  if (item.productDetails != null &&
                      item.availableSizes
                              .where((p) =>
                                  p.price.isNotEmpty &&
                                  p.price != '0' &&
                                  p.price != 'N/A')
                              .length >
                          1)
                    DropdownButtonHideUnderline(
                      child: DropdownButton<PackSize>(
                        value: currentSelectedPackSize,
                        isDense: true,
                        items: item.availableSizes
                            .where((pack) =>
                                pack.price.isNotEmpty &&
                                pack.price != '0' &&
                                pack.price != 'N/A')
                            .map((PackSize packSize) =>
                                DropdownMenuItem<PackSize>(
                                    value: packSize,
                                    child: Text(
                                        '${packSize.size} - ₹${packSize.price}',
                                        style:
                                            GoogleFonts.poppins(fontSize: 14))))
                            .toList(),
                        onChanged: (PackSize? newValue) {
                          if (newValue != null &&
                              newValue.size != currentSelectedPackSize.size) {
                            _updateSelectedSize(item.productKey, newValue);
                          }
                        },
                      ),
                    )
                  else
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                            '${currentSelectedPackSize.size} - ₹${currentSelectedPackSize.price}',
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.grey.shade700))),
                  const SizedBox(height: 10),
                  // --- Quantity and Line Total ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        // Quantity Controls
                        height: 35,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              icon: const Icon(Iconsax.minus, size: 16),
                              onPressed: item.quantity > 1
                                  ? () => _updateQuantity(
                                      item.productKey, item.quantity - 1)
                                  : null,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              constraints: const BoxConstraints(),
                              splashRadius: 18,
                              tooltip: 'Decrease quantity'),
                          SizedBox(
                            width: 48,
                            child: TextFormField(
                              key: ValueKey('qty_${item.productKey}'),
                              initialValue: item.quantity.toString(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 6),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                _scheduleTypedQtyUpdate(item.productKey, val,
                                    availableStock: availableStock);
                              },
                              onFieldSubmitted: (val) {
                                // immediate commit on submit
                                final digits =
                                    val.replaceAll(RegExp(r'[^0-9]'), '');
                                int parsed =
                                    int.tryParse(digits) ?? item.quantity;
                                if (availableStock > 0) {
                                  if (parsed < 1) {
                                    parsed = 1;
                                  }
                                  if (parsed > availableStock) {
                                    parsed = availableStock;
                                  }
                                } else {
                                  if (parsed < 1) {
                                    parsed = 1;
                                  }
                                }
                                _qtyDebounce[item.productKey]?.cancel();
                                _updateQuantity(item.productKey, parsed);
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Iconsax.add,
                                size: 16,
                                color: atMax ? Colors.grey : Colors.deepOrange),
                            onPressed: atMax
                                ? null
                                : () => _incrementWithStockClamp(item),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(),
                            splashRadius: 18,
                            tooltip: atMax
                                ? 'Reached available stock'
                                : 'Increase quantity',
                          ),
                        ]),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${lineTotal.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          if (availableStock > 0)
                            Text('Max $availableStock in stock',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: atMax
                                        ? Colors.redAccent
                                        : Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the order summary section at the bottom
  Widget _buildOrderSummary(double subtotal, List<CartItemDetails> items) {
    double deliveryCharge = (subtotal > 0 && subtotal < 500) ? 50.0 : 0.0;
    double total = subtotal + deliveryCharge;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -5))
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Price Summary ---
          _buildSummaryRow('Subtotal', subtotal),
          _buildSummaryRow('Delivery Charge', deliveryCharge),
          const Divider(height: 24, thickness: 0.5),
          _buildSummaryRow('Total', total, isTotal: true),

          // --- Estimated Delivery ---
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Iconsax.truck_fast, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text("Est. Delivery within 48 hours",
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade600)),
            ]),
          ),

          // --- Checkout Button ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: subtotal > 0
                  ? () {
                      // Validate stock before proceeding
                      for (final it in items) {
                        final stock = it.productDetails?.stock ?? 0;
                        if (stock > 0 && it.quantity > stock) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Reduce quantity of "${it.name}" to $stock or less (in stock).'),
                                backgroundColor: Colors.orange),
                          );
                          return;
                        }
                      }
                      final int amountPaise = (total * 100).round();
                      if (amountPaise < 100) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text(
                              'Order total must be at least ₹1 to proceed.'),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CheckoutFormPage(
                                  totalAmountPaise: amountPaise)));
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey.shade300,
                textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 16),
              ),
              child: Text('Proceed to Checkout'),
            ),
          )
        ],
      ),
    );
  }

  // Helper for summary rows
  Widget _buildSummaryRow(String label, double amount,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: isTotal ? 18 : 15,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: Colors.grey.shade700)),
          Text(
            '${isDiscount ? '-' : ''}₹${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
                fontSize: isTotal ? 20 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: isDiscount
                    ? Colors.green.shade700
                    : (isTotal ? Colors.deepOrange : Colors.black87)),
          ),
        ],
      ),
    );
  }

  // Builds the shimmer loading placeholder
  Widget _buildCartLoadingShimmer(int itemCount) {
    return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: itemCount > 0 ? itemCount : 3,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(/* ... Shimmer item layout ... */),
            ),
          );
        });
  }
} // End _CartPageState
