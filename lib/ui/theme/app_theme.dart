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
        onPrimary: const Color(0xFF003822),
        secondary: const Color(0xFF334155),
        onSecondary: const Color(0xFFF8F9FA),
        surface: const Color(0xFF1E293B),
        onSurface: const Color(0xFFF8F9FA),
        onSurfaceVariant: const Color(0xFF94A3B8),
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
        titleMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE2E8F0),
        ),
        bodyLarge: GoogleFonts.inter(
          color: const Color(0xFFF8F9FA),
        ),
        bodyMedium: GoogleFonts.inter(
          color: const Color(0xFFE2E8F0),
        ),
        bodySmall: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
        ),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF8F9FA),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
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
