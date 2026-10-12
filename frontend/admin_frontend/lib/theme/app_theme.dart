import 'package:flutter/material.dart';

import 'admin_font.dart';

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration toastDuration = Duration(seconds: 3);
}

class AppTheme {
  // Change this selection to preview a font across the admin.
  static const AdminFont font = AdminFont.sourceSerif4;

  // Colors from CSS variables
  static const Color primary = Color(0xFF171717);
  static const Color secondary = Color(0xFF525252);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F8F8);
  static const Color border = Color(0xFFE5E5E5);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color text = Color(0xFF171717);
  static const Color textSecondary = Color(0xFF737373);
  static const Color textMuted = Color(0xFFA3A3A3);

  // Status colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: font.style().fontFamily,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: background,
        error: danger,
      ),
      textTheme: font.textTheme().copyWith(
        displayLarge: font.style(color: text, fontWeight: FontWeight.w600),
        displayMedium: font.style(color: text, fontWeight: FontWeight.w600),
        displaySmall: font.style(color: text, fontWeight: FontWeight.w600),
        headlineMedium: font.style(color: text, fontWeight: FontWeight.w600),
        headlineLarge: font.style(color: text, fontWeight: FontWeight.w600),
        headlineSmall: font.style(color: text, fontWeight: FontWeight.w600),
        titleLarge: font.style(color: text, fontWeight: FontWeight.w600),
        titleMedium: font.style(
          color: text,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        titleSmall: font.style(
          color: text,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        bodyLarge: font.style(
          color: text,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        bodyMedium: font.style(
          color: text,
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        bodySmall: font.style(
          color: textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        labelLarge: font.style(
          color: text,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelMedium: font.style(
          color: text,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        labelSmall: font.style(
          color: textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: text),
        titleTextStyle: font.style(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      cardTheme: CardThemeData(
        color: background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: font.style(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: font.style(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
    );
  }
}
