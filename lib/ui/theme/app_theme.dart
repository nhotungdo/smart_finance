import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D1C32),
        primary: const Color(0xFF0D1C32),
        secondary: const Color(0xFF4EDEA3),
        surface: const Color(0xFFF8F9FA),
        error: const Color(0xFFBA1A1A),
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0D1C32),
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0D1C32),
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0D1C32),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0D1C32)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0D1C32),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: const Color(0xFF4EDEA3),
        primary: const Color(0xFF4EDEA3),
        secondary: const Color(0xFF0D1C32),
        surface: const Color(0xFF132847),
        error: const Color(0xFFFF8A8A),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF8F9FA),
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF8F9FA),
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF8F9FA),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFF070F1C),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1C32),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFF8F9FA)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF8F9FA),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
