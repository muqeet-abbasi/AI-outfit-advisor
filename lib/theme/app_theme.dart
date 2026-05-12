import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF0F4F8);
  static const Color bgTertiary = Color(0xFFE8EEF4);
  static const Color ink = Color(0xFF0F172A);
  static const Color inkMid = Color(0xFF334155);
  static const Color inkLight = Color(0xFF64748B);
  static const Color inkHint = Color(0xFF94A3B8);
  static const Color ice = Color(0xFF38BDF8);
  static const Color iceDim = Color(0xFFBAE6FD);
  static const Color iceDeep = Color(0xFF0284C7);
  static const Color iceDark = Color(0xFF0369A1);
  static const Color chrome = Color(0xFFCBD5E1);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.light(
      primary: ice,
      secondary: iceDeep,
      surface: bg,
      error: error,
    ),
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(
        color: ink,
        fontSize: 52,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.5,
        height: 1.0,
      ),
      headlineLarge: GoogleFonts.outfit(
        color: ink,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.outfit(
        color: ink,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.outfit(
        color: ink,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.outfit(color: inkMid, fontSize: 15, height: 1.7),
      bodyMedium: GoogleFonts.outfit(
        color: inkLight,
        fontSize: 13,
        height: 1.6,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
