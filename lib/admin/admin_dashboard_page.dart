import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import 'all_users_page.dart';
import '../pages/core/report_issue_page.dart';
import '../product/manage_products_page.dart';
// ⭐ FIX: This import path must exactly match the location of your file.
// Make sure your file is saved at 'lib/pages/manage_color_catalogue_page.dart'.
import '../pages/manage_color_catalogue_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
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
              icon: Iconsax.flag,
              title: 'View Reports',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewReportsPage()));
              },
            ),
            _buildDashboardCard(
              context: context,
              icon: Icons.people_alt,
              title: 'All Users',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AllUsersPage()));
              },
            ),
            _buildDashboardCard(
              context: context,
              icon: Iconsax.box,
              title: 'Manage Products',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageProductsPage()));
              },
            ),
            _buildDashboardCard(
              context: context,
              icon: Iconsax.color_swatch,
              title: 'Manage Catalogue',
              onTap: () {
                // This line will now work correctly with the right import.
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageColorCataloguePage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.red.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
