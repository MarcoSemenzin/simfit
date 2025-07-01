import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simfit/providers/user_provider.dart';
import 'package:simfit/screens/home.dart';
import 'package:simfit/screens/login.dart';
import 'package:simfit/screens/profile.dart';
import 'package:profile_photo/profile_photo.dart';
import 'package:simfit/screens/info.dart';
import 'package:simfit/screens/training.dart';

/// A navigation drawer that provides access to key pages within the app
/// and displays a welcome message with the user's name and avatar.
class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the UserProvider to retrieve name and gender
    final userProvider = Provider.of<UserProvider>(context);

    return Drawer(
      child: Column(
        children: <Widget>[
          // Header with greeting and profile photo
          SizedBox(
            width: double.infinity,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Hi ${userProvider.name ?? 'User'}!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                  ),
                  ProfilePhoto(
                    totalWidth: 90,
                    cornerRadius: 90,
                    color: Theme.of(context).secondaryHeaderColor,
                    image: AssetImage(
                      userProvider.gender == 'female'
                          ? 'assets/female-avatar.png'
                          : 'assets/male-avatar.png',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation options
          _buildNavTile(
            context,
            icon: Icons.home_filled,
            label: 'Home',
            onTap: () => _navigateTo(context, const Home(), replace: true),
          ),
          _buildNavTile(
            context,
            icon: Icons.account_circle,
            label: 'Profile',
            onTap: () => _navigateTo(context, const Profile(), replace: true),
          ),
          _buildNavTile(
            context,
            icon: Icons.trending_up,
            label: 'Training',
            onTap: () => _navigateTo(context, const Training(), replace: true),
          ),
          _buildNavTile(
            context,
            icon: Icons.info_rounded,
            label: 'About SimFit',
            onTap: () => _navigateTo(context, const Info(), replace: false),
          ),

          // Spacer pushes the logout button to the bottom
          const Spacer(),

          // Log out button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
            child: ElevatedButton(
              onPressed: () => _logoutAndNavigate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).secondaryHeaderColor,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                child: Text(
                  'LOG OUT',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to reduce code repetition for navigation tiles
  Widget _buildNavTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      trailing: Icon(icon, color: Theme.of(context).primaryColor, size: 30),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Theme.of(context).primaryColor,
        ),
      ),
      onTap: onTap,
    );
  }

  /// Navigates to the given page, optionally replacing the current route
  void _navigateTo(BuildContext context, Widget page, {bool replace = false}) {
    final route = MaterialPageRoute(builder: (_) => page);
    if (replace) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  /// Clears stored user credentials and navigates to the login screen
  Future<void> _logoutAndNavigate(BuildContext context) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('username');
    await sp.remove('password');
    await sp.remove('access');
    await sp.remove('refresh');
    _navigateTo(context, const Login(), replace: true);
  }
}