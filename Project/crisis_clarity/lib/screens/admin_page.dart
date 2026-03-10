import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: const Center(
        child: Text(
          'Welcome to the Admin Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
        ),
      ),
    );
  }
}
