import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light {
    final baseTextTheme = GoogleFonts.openSansTextTheme();

    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: GoogleFonts.openSans(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Color(0xFF202D85),
        ),
      ),

      primaryColor: Color(0xFF202D85),
      scaffoldBackgroundColor: Colors.white,
      textTheme: baseTextTheme.copyWith(
        // Заголовки (bold)
        headlineLarge: GoogleFonts.openSans(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineMedium: GoogleFonts.openSans(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Color(0xFF202D85),
        ),

        // Текст над инпутами (semi-bold → label)
        titleMedium: GoogleFonts.openSans(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),

        // Текст внутри инпутов (regular)
        bodyLarge: GoogleFonts.openSans(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        bodyMedium: GoogleFonts.openSans(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        constraints: BoxConstraints(minHeight: 41),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        labelStyle: GoogleFonts.openSans(
          fontWeight: FontWeight.w700, // semi-bold для лейблов
          fontSize: 14,
          color: Colors.grey,
        ),
        hintStyle: GoogleFonts.openSans(
          fontWeight: FontWeight.w400, // regular для hint
          fontSize: 14,
          color: Color(0xFF6E6E6E),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFD9D9D9)),
        ),
      ),
    );
  }
}
