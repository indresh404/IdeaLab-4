import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Dashboard'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: const Center(
        child: Text(
          'Welcome to the User Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
        ),
      ),
    );
  }
}
