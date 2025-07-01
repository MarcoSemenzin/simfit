import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simfit/providers/user_provider.dart';
import 'package:simfit/screens/home.dart';
import 'package:simfit/screens/login.dart';
import 'package:simfit/screens/profile.dart';
import 'package:simfit/screens/onboarding.dart';
import 'package:simfit/server/impact.dart';

/// Splash screen shown at app launch.
/// 
/// Displays a loading animation while checking login status,
/// onboarding completion, and token refresh. Based on the result,
/// it redirects the user to the appropriate screen.
class Splash extends StatelessWidget {
  const Splash({super.key});

  /// Navigates to the Home screen.
  void _toHomePage(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Home()),
    );
  }

  /// Navigates to the Login screen.
  void _toLoginPage(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Login()),
    );
  }

  /// Navigates to the Onboarding screen.
  void _toOnboardingPage(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnBoarding()),
    );
  }

  /// Navigates to the Profile screen.
  void _toProfilePage(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Profile()),
    );
  }

  /// Checks login and onboarding status, refreshes tokens if needed,
  /// and navigates accordingly.
  Future<void> _checkLogin(BuildContext context) async {
    final userProv = Provider.of<UserProvider>(context, listen: false);

    // If user has never completed onboarding, go to onboarding
    if (await userProv.checkOnboarding() == false) {
      _toOnboardingPage(context);
    } else {
      // Try refreshing tokens using the stored refresh token
      final result = await Impact().refreshTokens();

      if (result == 200) {
        // Token refreshed: decide where to go based on first login status
        if (userProv.firstLogin == true) {
          _toProfilePage(context); // User should complete profile first
        } else {
          _toHomePage(context); // User can access the main app
        }
      } else {
        // Refresh token invalid or expired: show login screen
        _toLoginPage(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Delay the login check by 3 seconds to show splash content
    Future.delayed(const Duration(seconds: 3), () => _checkLogin(context));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo
                  Image.asset(
                    'assets/simfit-logo.png',
                    scale: 4,
                  ),
                  const SizedBox(height: 10),
                  // Loading indicator
                  CircularProgressIndicator(
                    strokeWidth: 5,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
