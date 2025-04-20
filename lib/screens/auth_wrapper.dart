// lib/screens/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'main_screen.dart';
import 'login_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Show loading indicator while determining authentication state
    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: SpinKitCircle(
            color: Colors.blue,
            size: 50.0,
          ),
        ),
      );
    }

    // Redirect based on authentication status
    if (userProvider.isAuthenticated) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}
