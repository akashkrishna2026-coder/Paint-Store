import 'package:flutter/material.dart';
import 'package:c_h_p/product/explore/product_display_page.dart';

class IndigoPaintsWaterproofingPage extends StatelessWidget {
  const IndigoPaintsWaterproofingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Directly show Indigo Waterproofing products
    return const ProductDisplayPage(
      title: 'Indigo Waterproofing',
      category: 'Waterproofing',
      brand: 'Indigo',
    );
  }
}