import 'package:flutter/material.dart';
import 'package:c_h_p/pages/view_painters_page.dart';
import 'package:c_h_p/pages/color_catalogue_page.dart';
import 'package:c_h_p/product/latest_colors_page.dart';
import 'package:c_h_p/pages/paint_calculator_page.dart';
import 'package:c_h_p/product/explore_product.dart';

class HomeCoordinator {
  void onCarouselTap(BuildContext context, Map<String, String> item) {
    final title = item['title'];
    Widget page;
    switch (title) {
      case 'Painting Services':
        page = const ViewPaintersPage();
        break;
      case 'Latest Colors':
        page = const LatestColorsPage();
        break;
      case 'Paint Calculator':
        page = const PaintCalculatorPage();
        break;
      case 'Seasonal Offers':
        // Previously proxied to Color Catalogue as a placeholder
        page = const ColorCataloguePage();
        break;
      default:
        page = const ExploreProductPage();
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}
