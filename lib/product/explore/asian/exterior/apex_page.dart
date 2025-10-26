import 'package:flutter/material.dart';
import 'package:c_h_p/product/explore/product_display_page.dart';

class ApexPage extends StatelessWidget {
  const ApexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProductDisplayPage(
      title: 'Apex Exterior Emulsions',
      category: 'Exterior',
      subCategory: 'Apex Exterior Emulsions',
      brand: 'Asian Paints',
    );
  }
}