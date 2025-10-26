import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// Ensure these paths are correct for your project
import '../admin/admin_dashboard_page.dart';
import '../manager/manager_dashboard_page.dart';
import '../auth/personal_info_page.dart';

class HomeDrawer extends StatelessWidget {
  final User? currentUser;
  final String userRole;
  final VoidCallback onLogout;

  const HomeDrawer({
    super.key,
    required this.currentUser,
    required this.userRole,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(currentUser?.displayName ?? 'Guest User', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(currentUser?.email ?? 'Not logged in', style: GoogleFonts.poppins()),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: (currentUser?.photoURL != null) ? NetworkImage(currentUser!.photoURL!) : null,
              child: (currentUser?.photoURL == null)
                  ? Text(currentUser?.displayName?.substring(0, 1).toUpperCase() ?? 'G', style: const TextStyle(fontSize: 40.0, color: Colors.deepOrange))
                  : null,
            ),
            decoration: const BoxDecoration(color: Colors.deepOrange),
          ),
          _buildDrawerItem(
            icon: Iconsax.home_2,
            title: 'Home',
            onTap: () => Navigator.pop(context), // Just close the drawer
          ),
          _buildDrawerItem(
            icon: Iconsax.user_edit,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              if (currentUser != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoPage()));
              }
            },
          ),
          const Divider(),

          // This logic now works correctly.
          if (userRole == 'Admin')
            _buildDrawerItem(
              icon: Iconsax.security_user,
              title: 'Admin Panel',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
              },
            ),

          if (userRole == 'Manager')
            _buildDrawerItem(
              icon: Iconsax.category,
              title: 'Manager Panel',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerDashboardPage()));
              },
            ),

          if (userRole == 'Admin' || userRole == 'Manager') const Divider(),

          // ⭐ FIX: This now correctly calls the logout function passed from HomePage.
          _buildDrawerItem(
            icon: Iconsax.logout,
            title: 'Logout',
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade800)),
      onTap: onTap,
    );
  }
}