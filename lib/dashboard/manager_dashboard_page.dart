import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'manage_inventory_page.dart'; // ⭐ IMPORT THE NEW PAGE ⭐

// Import other pages as you build them
// import 'view_orders_page.dart';

class ManagerDashboardPage extends StatelessWidget {
  const ManagerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manager Panel", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.teal,
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
              icon: Icons.receipt_long,
              title: 'View Orders',
              onTap: () {
                // TODO: Navigate to ViewOrdersPage
              },
            ),
            // ⭐ UPDATE THIS CARD'S ONTAP ⭐
            _buildDashboardCard(
              context: context,
              icon: Icons.inventory_2,
              title: 'Manage Inventory',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageInventoryPage()),
                );
              },
            ),
            _buildDashboardCard(
              context: context,
              icon: Icons.group,
              title: 'Staff Details',
              onTap: () {
                // TODO: Navigate to StaffDetailsPage
              },
            ),
            _buildDashboardCard(
              context: context,
              icon: Icons.assessment,
              title: 'Generate Reports',
              onTap: () {
                // TODO: Navigate to ReportsPage
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.teal),
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
