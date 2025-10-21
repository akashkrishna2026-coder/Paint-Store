import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
// ⭐ 1. IMPORT THE DEDICATED PAGES
import '../product/manage_products_page.dart';
import '../product/explore/asian/interior/textures/manage_textures_page.dart';
import '../pages/core/stock_monitoring_page.dart';
import '../pages/painters_management_page.dart';

class ManagerDashboardPage extends StatelessWidget {
  const ManagerDashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manager Panel", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.pink.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardCard(
              context: context,
              icon: Iconsax.box,
              title: 'Manage Products',
              // ⭐ 2. NAVIGATE TO THE DEDICATED PRODUCTS PAGE
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageProductsPage())),
            ),
            _buildDashboardCard(
              context: context,
              icon: Iconsax.brush_3,
              title: 'Manage Textures',
              // ⭐ 3. NAVIGATE TO THE DEDICATED TEXTURES PAGE
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageTexturesPage())),
            ),
            _buildDashboardCard(
              context: context,
              icon: Iconsax.chart_2,
              title: 'Monitor Stock',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockMonitoringPage())),
            ),
            _buildDashboardCard(
              context: context,
              icon: Iconsax.user_edit,
              title: 'Manage Painters',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaintersManagementPage())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({required BuildContext context, required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.pink.shade600),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}