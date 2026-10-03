import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.secondary,
    cardColor: AppColors.cardBackground,
    
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.accent,
    ),
    
    textTheme: TextTheme(
      headlineSmall: GoogleFonts.poppins(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.roboto(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.roboto(
        color: AppColors.textPrimary,
      ),
      bodySmall: GoogleFonts.roboto(
        color: AppColors.textSecondary,
      ),
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.secondary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
  );
  
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCard,
     colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.lightBackground,
      error: AppColors.accent,
    ),
     textTheme: TextTheme(
      headlineSmall: GoogleFonts.poppins(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.roboto(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
         fontSize: 16,
      ),
      bodyMedium: GoogleFonts.roboto(
        color: AppColors.lightTextPrimary,
      ),
      bodySmall: GoogleFonts.roboto(
        color: AppColors.lightTextSecondary,
      ),
    ),
     appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
       centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
       iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
    ),
  );
}
