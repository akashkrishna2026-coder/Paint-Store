import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../admin/admin_dashboard_page.dart';
import '../auth/login_page.dart';
import '../auth/personal_info_page.dart';
import '../dashboard/manager_dashboard_page.dart';
import '../product/explore_product.dart';

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
    // --- NEW: Logic to determine theme color based on user role ---
    Color headerColor;
    Color iconColor;

    switch (userRole) {
      case 'Admin':
        headerColor = Colors.red.shade700;
        iconColor = Colors.red.shade700;
        break;
      case 'Manager':
        headerColor = Colors.teal;
        iconColor = Colors.teal;
        break;
      default: // Customer and others
        headerColor = Colors.deepOrange;
        iconColor = Colors.deepOrange;
    }

    return Drawer(
      child: Column(
        children: [
          // --- MODIFIED: Drawer header now uses the dynamic theme color ---
          Container(
            color: headerColor,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
                  child: currentUser?.photoURL == null ? Icon(Icons.person, color: iconColor, size: 40) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser != null ? (currentUser!.displayName ?? currentUser!.email ?? "User") : "Welcome Guest",
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (currentUser == null)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: headerColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          icon: const Icon(Icons.login, size: 18),
                          label: Text("Login / Signup", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                        ),
                      if (currentUser != null)
                        Row(
                          children: [
                            Expanded(child: Text(currentUser!.email ?? "", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
                            IconButton(icon: const Icon(Icons.edit, color: Colors.white, size: 18), onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoPage()));
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // --- MODIFIED: ListView is now simplified ---
          Expanded(
            child: ListView(
                padding: const EdgeInsets.only(top: 8.0),
                children: [
                  if (currentUser != null)
                    ListTile(
                      leading: Icon(Icons.dashboard, color: iconColor),
                      title: Text("Dashboard", style: GoogleFonts.poppins()),
                      onTap: () {
                        Navigator.pop(context);
                        Widget destinationPage;
                        switch (userRole) {
                          case 'Admin':
                            destinationPage = const AdminDashboardPage();
                            break;
                          case 'Manager':
                            destinationPage = const ManagerDashboardPage();
                            break;
                          default:
                            destinationPage = const ExploreProductPage();
                        }
                        Navigator.push(context, MaterialPageRoute(builder: (_) => destinationPage));
                      },
                    ),
                  // All other items have been removed as requested.
                ]),
          ),
          if (FirebaseAuth.instance.currentUser != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), minimumSize: const Size(double.infinity, 50)),
                icon: const Icon(Icons.logout, size: 18),
                label: Text("Logout", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                onPressed: onLogout,
              ),
            ),
        ],
      ),
    );
  }
}

