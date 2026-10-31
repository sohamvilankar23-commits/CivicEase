import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color secondaryColor = Color(0xFF1F2937);
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFF374151);

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: secondaryColor,
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 16,
          color: textColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E3A8A), // Purple background
        selectedItemColor: Color(0xFFFFFFFF), // White for selected item
        unselectedItemColor: Color(0xFFB0BEC5), // Gray for unselected items
        selectedLabelStyle: TextStyle(color: Color(0xFFFFFFFF)), // White label
        unselectedLabelStyle: TextStyle(color: Color(0xFFB0BEC5)), // Gray label
        showSelectedLabels: true, // Ensure selected labels are shown
        showUnselectedLabels: true, // Ensure unselected labels are shown
      ),
    );
  }
}