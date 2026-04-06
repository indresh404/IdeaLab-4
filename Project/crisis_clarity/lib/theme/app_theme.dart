import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Palette
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color secondaryTeal = Color(0xFF1D9E75);
  static const Color errorRed = Color(0xFFE24B4A);
  static const Color warningAmber = Color(0xFFEF9F27);
  
  // Backgrounds
  static const Color background = Color(0xFFF8F7F2);
  static const Color surface = Color(0xFFFFFFFF);
  
  // Disaster Type Colors
  static const Map<String, Color> disasterColors = {
    'flood': Color(0xFF2E8BC0), // Brighter, more modern
    'storm': Color(0xFF5D39A3),
    'fire': Color(0xFFF25C3C),
    'evacuation': Color(0xFFEDC948),
    'cyclone': Color(0xFF762B44),
    'earthquake': Color(0xFF8C7851),
    'other': Color(0xFF4B8B3B),
  };

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        secondary: secondaryTeal,
        error: errorRed,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.outfitTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 4,
          shadowColor: primaryRed.withOpacity(0.3),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0, // Flat design with subtle borders is more modern
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
