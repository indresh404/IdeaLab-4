import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryRed = Color(0xFFE12D39);
  static const Color lightRed = Color(0xFFFCE8E9);
  static const Color darkRed = Color(0xFFB71C1C);
  static const Color white = Color(0xFFFFFFFF);
  static const Color sewaaInputBg = Color(0xFFEFEFEF);

  static final ThemeData themeData = ThemeData(
    primaryColor: primaryRed,
    scaffoldBackgroundColor: white,
    fontFamily: 'Inter', // Default sans-serif or adapt to preferred font
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryRed,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryRed,
      selectedItemColor: white,
      unselectedItemColor: lightRed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: primaryRed,
        backgroundColor: white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
