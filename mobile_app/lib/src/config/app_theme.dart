import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const iosPrimary = Color(0xFF007AFF);
  static const iosSecondary = Color(0xFF5AC8FA);
  static const iosTertiary = Color(0xFF34C759);
  static const iosError = Color(0xFFFF3B30);
  
  static const priceRed = Color(0xFFE53935);
  static const ratingAmber = Color(0xFFF59E0B);
  static const savingsOrange = Color(0xFFC2410C);
  static const distanceBlue = Color(0xFF1565C0);
  static const expiredRed = Color(0xFFB91C1C);
  
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9E9E9E);
  
  static const surfaceLight = Color(0xFFF2F2F7);
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFD8D8DE);
  static const borderSubtle = Color(0xFFE5E7EB);
  static const borderCard = Color(0xFFE8EEF7);
  
  static const surfaceDark = Color(0xFF1C1C1E);
  static const cardDark = Color(0xFF2C2C2E);
  static const borderDark = Color(0xFF3A3A3C);
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFAAAAAA);
}

class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const xxl = 24.0;
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

class DealFinderThemeExtension extends ThemeExtension<DealFinderThemeExtension> {
  final Color priceColor;
  final Color savingsColor;
  final Color ratingColor;
  final Color distanceColor;
  final Color expiredColor;
  final Color cardShadow;
  final Color glassBackground;
  final Color chipBackground;

  const DealFinderThemeExtension({
    required this.priceColor,
    required this.savingsColor,
    required this.ratingColor,
    required this.distanceColor,
    required this.expiredColor,
    required this.cardShadow,
    required this.glassBackground,
    required this.chipBackground,
  });

  @override
  DealFinderThemeExtension copyWith({
    Color? priceColor,
    Color? savingsColor,
    Color? ratingColor,
    Color? distanceColor,
    Color? expiredColor,
    Color? cardShadow,
    Color? glassBackground,
    Color? chipBackground,
  }) {
    return DealFinderThemeExtension(
      priceColor: priceColor ?? this.priceColor,
      savingsColor: savingsColor ?? this.savingsColor,
      ratingColor: ratingColor ?? this.ratingColor,
      distanceColor: distanceColor ?? this.distanceColor,
      expiredColor: expiredColor ?? this.expiredColor,
      cardShadow: cardShadow ?? this.cardShadow,
      glassBackground: glassBackground ?? this.glassBackground,
      chipBackground: chipBackground ?? this.chipBackground,
    );
  }

  @override
  DealFinderThemeExtension lerp(ThemeExtension<DealFinderThemeExtension>? other, double t) {
    if (other is! DealFinderThemeExtension) return this;
    return DealFinderThemeExtension(
      priceColor: Color.lerp(priceColor, other.priceColor, t)!,
      savingsColor: Color.lerp(savingsColor, other.savingsColor, t)!,
      ratingColor: Color.lerp(ratingColor, other.ratingColor, t)!,
      distanceColor: Color.lerp(distanceColor, other.distanceColor, t)!,
      expiredColor: Color.lerp(expiredColor, other.expiredColor, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
    );
  }

  static const light = DealFinderThemeExtension(
    priceColor: AppColors.priceRed,
    savingsColor: AppColors.savingsOrange,
    ratingColor: AppColors.ratingAmber,
    distanceColor: AppColors.distanceBlue,
    expiredColor: AppColors.expiredRed,
    cardShadow: AppColors.textPrimary,
    glassBackground: AppColors.cardLight,
    chipBackground: Color(0xFFFEF3C7),
  );

  static const dark = DealFinderThemeExtension(
    priceColor: Color(0xFFEF5350),
    savingsColor: Color(0xFFFF9800),
    ratingColor: Color(0xFFFFC107),
    distanceColor: Color(0xFF42A5F5),
    expiredColor: Color(0xFFEF5350),
    cardShadow: Color(0xFF000000),
    glassBackground: AppColors.cardDark,
    chipBackground: Color(0xFF4A3800),
  );
}

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.iosPrimary,
        primary: AppColors.iosPrimary,
        secondary: AppColors.iosSecondary,
        tertiary: AppColors.iosTertiary,
        surface: AppColors.surfaceLight,
        surfaceContainerHighest: AppColors.cardLight,
        error: AppColors.iosError,
        brightness: Brightness.light,
      ),
      extensions: const [DealFinderThemeExtension.light],
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
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AppColors.iosPrimary,
        scaffoldBackgroundColor: AppColors.surfaceLight,
        barBackgroundColor: Color(0xF7FFFFFF),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.iosPrimary,
          textStyle: TextStyle(color: AppColors.textPrimary, fontSize: 17),
          navTitleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          navLargeTitleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xF7FFFFFF),
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.iosPrimary),
        actionsIconTheme: IconThemeData(color: AppColors.iosPrimary),
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
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.cardLight,
        selectedColor: Color(0xFFEAF3FF),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.iosPrimary,
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: StadiumBorder(side: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          borderSide: BorderSide(color: AppColors.iosPrimary, width: 1.5),
        ),
        hintStyle: TextStyle(color: AppColors.textSecondary),
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.iosPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.iosPrimary,
          side: const BorderSide(color: AppColors.borderLight, width: 1),
          backgroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.iosPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.iosPrimary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.iosPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1F2937),
        contentTextStyle: TextStyle(color: Colors.white),
        actionTextColor: AppColors.iosSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.iosPrimary,
        primary: AppColors.iosPrimary,
        secondary: AppColors.iosSecondary,
        tertiary: AppColors.iosTertiary,
        surface: AppColors.surfaceDark,
        surfaceContainerHighest: AppColors.cardDark,
        error: AppColors.iosError,
        brightness: Brightness.dark,
      ),
      extensions: const [DealFinderThemeExtension.dark],
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
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AppColors.iosPrimary,
        scaffoldBackgroundColor: AppColors.surfaceDark,
        barBackgroundColor: AppColors.cardDark,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.iosPrimary,
          textStyle: TextStyle(color: AppColors.textPrimaryDark, fontSize: 17),
          navTitleTextStyle: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          navLargeTitleTextStyle: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryDark,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: AppColors.iosPrimary),
        actionsIconTheme: IconThemeData(color: AppColors.iosPrimary),
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
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.cardDark,
        selectedColor: Color(0xFF1E3A5F),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.iosPrimary,
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: StadiumBorder(side: BorderSide(color: AppColors.borderDark, width: 1)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          borderSide: BorderSide(color: AppColors.iosPrimary, width: 1.5),
        ),
        hintStyle: TextStyle(color: AppColors.textSecondaryDark),
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.iosPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.iosPrimary,
          side: const BorderSide(color: AppColors.borderDark, width: 1),
          backgroundColor: AppColors.cardDark,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.iosPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.iosPrimary,
        unselectedItemColor: AppColors.textSecondaryDark,
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.iosPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.cardDark,
        contentTextStyle: TextStyle(color: AppColors.textPrimaryDark),
        actionTextColor: AppColors.iosSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
        displayMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.textPrimaryDark),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
        bodyLarge: TextStyle(color: AppColors.textPrimaryDark),
        bodyMedium: TextStyle(color: AppColors.textSecondaryDark),
        bodySmall: TextStyle(color: AppColors.textSecondaryDark),
      ),
    );
  }

  static SystemUiOverlayStyle systemOverlayStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? AppColors.surfaceDark : Colors.white,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
  }
}
