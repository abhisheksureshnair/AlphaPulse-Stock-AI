import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color electricRed = Color(0xFFFF3131);
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color mutedGrey = Color(0xFF8C8C8C);
  static const Color borderGlow = Color(0x3339FF14);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.neonGreen,
      colorScheme: ColorScheme.dark(
        primary: AppColors.neonGreen,
        secondary: AppColors.neonBlue,
        error: AppColors.electricRed,
        surface: AppColors.cardBackground,
      ),
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.mutedGrey,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.neonGreen,
        unselectedItemColor: AppColors.mutedGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
