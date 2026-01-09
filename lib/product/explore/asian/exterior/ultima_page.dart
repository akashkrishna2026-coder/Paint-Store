import 'package:flutter/material.dart';
import 'package:c_h_p/product/explore/product_display_page.dart';

class UltimaPage extends StatelessWidget {
  const UltimaPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Delegate to ProductDisplayPage to use the same interior-style list cards,
    // while preserving each product's own main image.
    return const ProductDisplayPage(
      title: 'Ultima Exterior Emulsions',
      category: 'Exterior',
      subCategory: 'Ultima Exterior Emulsions',
      brand: 'Asian Paints',
    );
  }
}
