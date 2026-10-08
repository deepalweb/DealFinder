import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// The "Ceylon" design system: grounded in Sri Lanka's spice/gem trade
/// (cinnamon, turmeric, tea, sapphire) rather than a generic discount-app
/// palette. Two hard rules, enforced by convention at call sites since Dart
/// has no way to check color combinations at compile time:
///   1. Turmeric and Chili never appear in the same component — Turmeric
///      means "look, save money," Chili means "act now or lose it."
///   2. Betel Green is reserved for trust/status (Verified, Open Now) only —
///      never repurposed as a generic "success" color elsewhere.
class AppColors {
  static const ceylonInk = Color(0xFF12312C);
  static const turmeric = Color(0xFFE2A33B);
  static const chili = Color(0xFFC24A3C);
  static const betelGreen = Color(0xFF4C8C6B);
  static const sand = Color(0xFFF6F3EA);
  static const charcoal = Color(0xFF26241F);
  static const ash = Color(0xFF8C8A80);

  static const textPrimary = charcoal;
  static const textSecondary = ash;
  static const textTertiary = Color(0xFFB5B2A6);

  static const surfaceLight = sand;
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE3DFD1);
  static const borderSubtle = Color(0xFFEAE6D9);

  // Dark mode inverts to Ceylon Ink as background, Sand as text.
  static const surfaceDark = Color(0xFF0C201C);
  static const cardDark = Color(0xFF16332D);
  static const borderDark = Color(0xFF25453D);
  static const textPrimaryDark = sand;
  static const textSecondaryDark = Color(0xFFAFC4BC);

  // Translucent bar fills, meant to sit behind a BackdropFilter blur.
  static const barBackgroundLight = Color(0xCCF6F3EA);
  static const barBackgroundDark = Color(0xCC0C201C);

  static const error = chili;
}

class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
}

/// Ceylon design system mobile type scale. Display roles (Fraunces) are for
/// hero moments only — the hero savings amount, section headers like "Why
/// visit?", empty-state headlines. Never used for body text or buttons; use
/// [AppTheme]'s TextTheme.displayLarge/displayMedium explicitly at those call
/// sites rather than letting it leak into default body/button styles.
class AppTypeScale {
  static const displayL = 32.0; // 32/38, Fraunces 600 — hero savings amount
  static const displayS = 22.0; // 22/28, Fraunces 500 — section headers
  static const title = 17.0; // 17/22, Jakarta 600 — merchant name, deal title
  static const body = 15.0; // 15/21, Jakarta 400 — descriptions
  static const label = 13.0; // 13/16, Jakarta 500 — badges, pills, metadata
  static const caption = 11.0; // 11/14, Jakarta 500 — timestamps, fine print
}

/// Single CTA button style app-wide — filled Ceylon Ink, no gradient — per
/// the design system's "one button style throughout" rule.
class AppButtonStyles {
  static ButtonStyle primary({Color? background, Color? foreground}) {
    return ElevatedButton.styleFrom(
      backgroundColor: background ?? AppColors.ceylonInk,
      foregroundColor: foreground ?? AppColors.sand,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      textStyle: GoogleFonts.plusJakartaSans(fontSize: AppTypeScale.title, fontWeight: FontWeight.w600),
    );
  }
}

class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 22.0;
  static const pill = 999.0;
}

class AppOpacity {
  static const subtle = 0.04;
  static const light = 0.05;
  static const medium = 0.12;
  static const strong = 0.34;
  static const overlay = 0.7;
  static const glass = 0.9;
}

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ceylonInk,
        primary: AppColors.ceylonInk,
        secondary: AppColors.turmeric,
        tertiary: AppColors.betelGreen,
        surface: AppColors.surfaceLight,
        surfaceContainerHighest: AppColors.cardLight,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: AppColors.surfaceLight,
      splashFactory: NoSplash.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: AppColors.ceylonInk,
        scaffoldBackgroundColor: AppColors.surfaceLight,
        barBackgroundColor: AppColors.barBackgroundLight,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.ceylonInk,
          textStyle: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: AppTypeScale.body),
          navTitleTextStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: AppTypeScale.title,
            fontWeight: FontWeight.w600,
          ),
          navLargeTitleTextStyle: GoogleFonts.fraunces(
            color: AppColors.textPrimary,
            fontSize: AppTypeScale.displayL,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.barBackgroundLight,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ceylonInk,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: AppTypeScale.title,
          fontWeight: FontWeight.w600,
          color: AppColors.ceylonInk,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: AppColors.ceylonInk),
        actionsIconTheme: const IconThemeData(color: AppColors.ceylonInk),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shadowColor: Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
          side: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.ceylonInk,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: AppTypeScale.label,
          fontWeight: FontWeight.w500,
          color: AppColors.charcoal,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: AppTypeScale.label,
          fontWeight: FontWeight.w500,
          color: AppColors.sand,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.ash, width: 1)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          borderSide: BorderSide(color: AppColors.ceylonInk, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtonStyles.primary()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ceylonInk,
          side: const BorderSide(color: AppColors.ash, width: 1),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ceylonInk,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.ceylonInk,
        unselectedItemColor: AppColors.ash,
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.ceylonInk,
        foregroundColor: AppColors.sand,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.charcoal,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: AppColors.sand),
        actionTextColor: AppColors.turmeric,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
      ),
      textTheme: _ceylonTypeScale(GoogleFonts.plusJakartaSansTextTheme(), AppColors.charcoal, AppColors.ash),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ceylonInk,
        primary: AppColors.betelGreen,
        secondary: AppColors.turmeric,
        tertiary: AppColors.betelGreen,
        surface: AppColors.surfaceDark,
        surfaceContainerHighest: AppColors.cardDark,
        error: AppColors.error,
        brightness: Brightness.dark,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: AppColors.surfaceDark,
      splashFactory: NoSplash.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: AppColors.turmeric,
        scaffoldBackgroundColor: AppColors.surfaceDark,
        barBackgroundColor: AppColors.barBackgroundDark,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.turmeric,
          textStyle: GoogleFonts.plusJakartaSans(color: AppColors.textPrimaryDark, fontSize: AppTypeScale.body),
          navTitleTextStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimaryDark,
            fontSize: AppTypeScale.title,
            fontWeight: FontWeight.w600,
          ),
          navLargeTitleTextStyle: GoogleFonts.fraunces(
            color: AppColors.textPrimaryDark,
            fontSize: AppTypeScale.displayL,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.barBackgroundDark,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryDark,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: AppTypeScale.title,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: AppColors.turmeric),
        actionsIconTheme: const IconThemeData(color: AppColors.turmeric),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shadowColor: Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
          side: BorderSide(color: AppColors.borderDark),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.turmeric,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: AppTypeScale.label,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: AppTypeScale.label,
          fontWeight: FontWeight.w500,
          color: AppColors.ceylonInk,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.textSecondaryDark, width: 1)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          borderSide: BorderSide(color: AppColors.turmeric, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textSecondaryDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppButtonStyles.primary(background: AppColors.turmeric, foreground: AppColors.ceylonInk),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.turmeric,
          side: const BorderSide(color: AppColors.textSecondaryDark, width: 1),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.turmeric,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.turmeric,
        unselectedItemColor: AppColors.textSecondaryDark,
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.turmeric,
        foregroundColor: AppColors.ceylonInk,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardDark,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: AppColors.textPrimaryDark),
        actionTextColor: AppColors.turmeric,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
      ),
      textTheme: _ceylonTypeScale(
        GoogleFonts.plusJakartaSansTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
        AppColors.textPrimaryDark,
        AppColors.textSecondaryDark,
      ),
    );
  }

  /// Maps Plus Jakarta Sans (via [base]) onto the Ceylon type scale's Title/
  /// Body/Label/Caption roles, and Fraunces onto displayLarge/displayMedium
  /// for the Display-L/Display-S hero roles. Nothing in this mapping wires
  /// Fraunces into body or button styles — those stay on Jakarta throughout.
  static TextTheme _ceylonTypeScale(TextTheme base, Color primary, Color secondary) {
    return base.copyWith(
      displayLarge: GoogleFonts.fraunces(fontSize: AppTypeScale.displayL, height: 38 / 32, fontWeight: FontWeight.w600, color: primary),
      displayMedium: GoogleFonts.fraunces(fontSize: AppTypeScale.displayS, height: 28 / 22, fontWeight: FontWeight.w500, color: primary),
      titleLarge: base.titleLarge?.copyWith(fontSize: AppTypeScale.title, fontWeight: FontWeight.w600, color: primary),
      titleMedium: base.titleMedium?.copyWith(fontSize: AppTypeScale.title, fontWeight: FontWeight.w600, color: primary),
      titleSmall: base.titleSmall?.copyWith(fontSize: AppTypeScale.title, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: AppTypeScale.body, height: 21 / 15, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: AppTypeScale.body, height: 21 / 15, fontWeight: FontWeight.w400, color: primary),
      bodySmall: base.bodySmall?.copyWith(fontSize: AppTypeScale.caption, height: 14 / 11, fontWeight: FontWeight.w500, color: secondary),
      labelLarge: base.labelLarge?.copyWith(fontSize: AppTypeScale.label, height: 16 / 13, fontWeight: FontWeight.w500, color: primary),
      labelMedium: base.labelMedium?.copyWith(fontSize: AppTypeScale.label, height: 16 / 13, fontWeight: FontWeight.w500, color: secondary),
      labelSmall: base.labelSmall?.copyWith(fontSize: AppTypeScale.caption, height: 14 / 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }

  static SystemUiOverlayStyle systemOverlayStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
  }
}
