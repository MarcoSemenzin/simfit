import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simfit/providers/user_provider.dart';
import 'package:simfit/server/impact.dart';
import 'package:simfit/screens/home.dart';
import 'package:simfit/screens/profile.dart';

/// Login screen that handles user authentication.
/// Uses the `flutter_login` package for UI and manages login logic,
/// token storage, and post-login navigation.
class Login extends StatefulWidget {
  const Login({super.key});

  static const routename = 'Login';

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  /// Instance of the class managing backend communication for auth.
  final Impact impact = Impact();

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'SimFit',
      theme: LoginTheme(
        pageColorLight: Theme.of(context).primaryColor,
        primaryColor: Theme.of(context).primaryColor,
        titleStyle: TextStyle(
          color: Theme.of(context).secondaryHeaderColor,
          fontWeight: FontWeight.bold,
        ),
        buttonStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      // Triggered when the user submits the login form.
      onLogin: _userLogin,

      // Password recovery is not implemented.
      onRecoverPassword: _recoverPassword,

      // Skips the "forgot password" button.
      hideForgotPasswordButton: true,

      // UI configuration
      userType: LoginUserType.name,
      messages: LoginMessages(
        userHint: 'Username',
        passwordHint: 'Password',
        loginButton: 'LOG IN',
      ),

      // Field validators
      userValidator: _validateUsername,
      passwordValidator: _validatePassword,

      // Called when the animation completes (i.e., after login).
      onSubmitAnimationCompleted: () => _checkFirstLogin(context),
    );
  }

  /// Validates the username field.
  String? _validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'The username field is empty!';
    }
    return null;
  }

  /// Validates the password field.
  String? _validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'The password field is empty!';
    }
    return null;
  }

  /// Authenticates the user with the backend and stores credentials locally.
  Future<String> _userLogin(LoginData data) async {
    // Credentials:
    // username: gMQWqcZXKO
    // password: 12345678!

    final result = await impact.getAndStoreTokens(data.name, data.password);
    if (result == 200) {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('username', data.name);
      await sp.setString('password', data.password);
      return ''; // success
    }
    return 'Wrong Credentials';
  }

  /// Placeholder for password recovery (not implemented).
  Future<String> _recoverPassword(String email) async {
    return 'This function is not currently implemented';
  }

  /// Navigates to the Home screen.
  void _toHomePage(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Home()),
    );
  }

  /// Navigates to the Profile screen for onboarding on first login.
  void _toProfilePage(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Profile()),
    );
  }

  /// Checks whether the current login is the user's first.
  /// Redirects accordingly.
  void _checkFirstLogin(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    if (userProv.firstLogin == true) {
      _toProfilePage(context);
    } else {
      _toHomePage(context);
    }
  }
}