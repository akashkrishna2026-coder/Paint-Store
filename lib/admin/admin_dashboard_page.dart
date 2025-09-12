import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'manager_requests_page.dart'; // <-- Renamed file
import 'all_users_page.dart';        // <-- New file
import '../product/manage_products_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.deepOrange,
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
            // UPDATED CARD
            _buildDashboardCard(
              context: context,
              icon: Icons.person_add_alt_1,
              title: 'Manager Requests',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageUsersPage()), // This is your original page, now renamed
                );
              },
            ),
            // NEW CARD
            _buildDashboardCard(
              context: context,
              icon: Icons.people_alt,
              title: 'All Users',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllUsersPage()),
                );
              },
            ),
            _buildDashboardCard(
              context: context,
              icon: Icons.inventory,
              title: 'Manage Products',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageProductsPage()),
                );
              },
            ),
            _buildDashboardCard(
              context: context,
              icon: Icons.bar_chart,
              title: 'Analytics',
              onTap: () {
                // TODO: Navigate to Analytics Page
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
    // ... Card widget code remains the same
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.deepOrange),
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