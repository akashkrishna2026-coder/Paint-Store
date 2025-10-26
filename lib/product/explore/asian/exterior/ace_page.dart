import 'package:flutter/material.dart';
import 'package:c_h_p/product/explore/product_display_page.dart';

class AcePage extends StatelessWidget {
  const AcePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProductDisplayPage(
      title: 'Ace Exterior Emulsions',
      category: 'Exterior',
      subCategory: 'Ace Exterior Emulsions',
      brand: 'Asian Paints',
    );
  }
}