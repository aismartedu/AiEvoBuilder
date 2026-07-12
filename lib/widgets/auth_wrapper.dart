import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../views/auth/login_screen.dart';
import '../views/dashboard/dashboard_screen.dart';
import '../config/constants.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false, _isLoading = true;
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }
  Future<void> _checkLogin() async {
    final token = await storage.read(key: 'auth_token');
    setState(() { _isLoggedIn = token != null; _isLoading = false; });
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _isLoggedIn ? const DashboardScreen() : const LoginScreen();
  }
}
