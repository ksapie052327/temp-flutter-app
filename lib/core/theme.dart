import 'package:flutter/material.dart';
import 'constants.dart';

class KTheme {
  KTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBlack,
        primaryColor: kGold,
        colorScheme: const ColorScheme.dark(
          primary: kGold,
          secondary: kGold,
          background: kBlack,
          surface: kSurface,
          onPrimary: kBlack,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBlack,
          foregroundColor: kGold,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: kGold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          iconTheme: IconThemeData(color: kGold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kGold,
            foregroundColor: kBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface,
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[800]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[800]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kGold),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        useMaterial3: true,
      );

  // ── Text Styles ──────────────────────────────────
  static const TextStyle heading = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subheading = TextStyle(
    color: Colors.white70,
    fontSize: 14,
  );

  static const TextStyle label = TextStyle(
    color: kGold,
    fontSize: 11,
    letterSpacing: 2,
    fontWeight: FontWeight.w600,
  );
}
