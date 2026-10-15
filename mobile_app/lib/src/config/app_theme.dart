import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// DealFinder: sapphire actions, quiet surfaces, and photography-led content.
/// Legacy names remain aliases so all existing screens share the new tokens.
class AppColors {
  static const ceylonInk = Color(0xFF2457E8);
  static const turmeric = Color(0xFFFFD67A);
  static const chili = Color(0xFFBC3548);
  static const betelGreen = Color(0xFF237450);
  static const sand = Color(0xFFF5F6FA);
  static const charcoal = Color(0xFF191919);
  static const ash = Color(0xFF666666);
  static const textPrimary = charcoal;
  static const textSecondary = ash;
  static const textTertiary = Color(0xFF737D90);
  static const surfaceLight = sand;
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFDDE2EC);
  static const borderSubtle = Color(0xFFE8ECF3);
  static const surfaceDark = Color(0xFF10131B);
  static const cardDark = Color(0xFF1B202C);
  static const borderDark = Color(0xFF343C4C);
  static const textPrimaryDark = Color(0xFFF1F4FA);
  static const textSecondaryDark = Color(0xFFADB8CC);
  static const barBackgroundLight = Color(0xEEFFFFFF);
  static const barBackgroundDark = Color(0xEE1B202C);
  static const error = chili;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color text(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimary;
  static Color muted(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondary;
  static Color card(BuildContext context) =>
      isDark(context) ? cardDark : cardLight;
  static Color canvas(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLight;
  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;
  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
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

class AppTypeScale {
  static const displayL = 34.0;
  static const displayS = 26.0;
  static const title = 17.0;
  static const body = 16.0;
  static const label = 13.0;
  static const caption = 12.0;
}

class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
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

class AppMotion {
  static Duration duration(BuildContext context, [int milliseconds = 220]) =>
      MediaQuery.disableAnimationsOf(context) ||
              MediaQuery.accessibleNavigationOf(context)
          ? Duration.zero
          : Duration(milliseconds: milliseconds);
}

class AppButtonStyles {
  static ButtonStyle primary({Color? background, Color? foreground}) =>
      ElevatedButton.styleFrom(
        backgroundColor: background ?? AppColors.ceylonInk,
        foregroundColor: foreground ?? Colors.white,
        elevation: 0,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      );
}

class _AdaptiveTransitions extends PageTransitionsBuilder {
  const _AdaptiveTransitions();
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    if (AppMotion.duration(context) == Duration.zero) return child;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return const CupertinoPageTransitionsBuilder().buildTransitions(
          route, context, animation, secondaryAnimation, child);
    }
    return const FadeUpwardsPageTransitionsBuilder()
        .buildTransitions(route, context, animation, secondaryAnimation, child);
  }
}

class AppTheme {
  static ThemeData lightTheme() => _theme(Brightness.light);
  static ThemeData darkTheme() => _theme(Brightness.dark);

  static ThemeData highContrastLightTheme() =>
      _theme(Brightness.light, highContrast: true);
  static ThemeData highContrastDarkTheme() =>
      _theme(Brightness.dark, highContrast: true);

  static ThemeData _theme(Brightness brightness, {bool highContrast = false}) {
    final dark = brightness == Brightness.dark;
    final canvas = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final card = dark ? AppColors.cardDark : AppColors.cardLight;
    final text = dark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final muted = dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final border = highContrast
        ? (dark ? AppColors.textSecondaryDark : AppColors.textSecondary)
        : (dark ? AppColors.borderDark : AppColors.borderLight);
    final accent = dark ? const Color(0xFF9EB9FF) : AppColors.ceylonInk;
    final onAccent = dark ? AppColors.surfaceDark : Colors.white;
    final scheme = ColorScheme.fromSeed(
            seedColor: AppColors.ceylonInk, brightness: brightness)
        .copyWith(
      primary: accent,
      onPrimary: onAccent,
      primaryContainer:
          dark ? const Color(0xFF273657) : const Color(0xFFE9EFFF),
      onPrimaryContainer:
          dark ? AppColors.textPrimaryDark : AppColors.ceylonInk,
      secondary: accent,
      onSecondary: onAccent,
      surface: card,
      onSurface: text,
      onSurfaceVariant: muted,
      surfaceContainerLow:
          dark ? const Color(0xFF27292D) : const Color(0xFFF1F1F1),
      surfaceContainerHighest:
          dark ? const Color(0xFF272E3D) : const Color(0xFFEDF0F6),
      outline: muted,
      outlineVariant: border,
      error: dark ? const Color(0xFFFFA7B2) : AppColors.chili,
    );
    final base = ThemeData(
        useMaterial3: true, brightness: brightness, colorScheme: scheme);
    final typography =
        base.textTheme.apply(bodyColor: text, displayColor: text).copyWith(
              displayLarge: TextStyle(
                  fontSize: 34,
                  height: 1.12,
                  letterSpacing: -1.2,
                  fontWeight: FontWeight.w700,
                  color: text),
              displayMedium: TextStyle(
                  fontSize: 28,
                  height: 1.16,
                  letterSpacing: -0.8,
                  fontWeight: FontWeight.w700,
                  color: text),
              headlineLarge: TextStyle(
                  fontSize: 32,
                  height: 1.15,
                  letterSpacing: -0.8,
                  fontWeight: FontWeight.w700,
                  color: text),
              titleLarge: TextStyle(
                  fontSize: 22,
                  height: 1.2,
                  letterSpacing: -0.4,
                  fontWeight: FontWeight.w700,
                  color: text),
              titleMedium: TextStyle(
                  fontSize: 17,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: text),
              bodyLarge: TextStyle(fontSize: 17, height: 1.45, color: text),
              bodyMedium: TextStyle(fontSize: 16, height: 1.4, color: text),
              bodySmall: TextStyle(fontSize: 13, height: 1.4, color: muted),
              labelLarge:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              labelMedium: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: muted),
              labelSmall: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: muted),
            );
    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      textTheme: typography,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: _AdaptiveTransitions(),
        TargetPlatform.iOS: _AdaptiveTransitions(),
        TargetPlatform.macOS: _AdaptiveTransitions(),
        TargetPlatform.windows: _AdaptiveTransitions(),
        TargetPlatform.linux: _AdaptiveTransitions(),
      }),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: accent,
        scaffoldBackgroundColor: canvas,
        barBackgroundColor: card,
        textTheme: CupertinoTextThemeData(
            primaryColor: accent,
            textStyle: TextStyle(fontSize: 17, color: text),
            navTitleTextStyle: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600, color: text),
            navLargeTitleTextStyle: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                color: text)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: typography.titleLarge,
        iconTheme: IconThemeData(color: accent, size: 24),
        actionsIconTheme: IconThemeData(color: accent, size: 24),
        systemOverlayStyle: systemOverlayStyle(brightness),
      ),
      cardTheme: CardThemeData(
          color: card,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: border.withValues(alpha: 0.65)))),
      listTileTheme: ListTileThemeData(
          textColor: text,
          iconColor: accent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        hintStyle: TextStyle(color: muted, fontSize: 16),
        labelStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accent, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.error)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppButtonStyles.primary(
              background: accent, foreground: onAccent)),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize: const Size(48, 52),
              backgroundColor: accent,
              foregroundColor: onAccent,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: accent,
              side: BorderSide(color: border),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)))),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: accent,
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
              minimumSize: const Size(48, 48), foregroundColor: accent)),
      chipTheme: ChipThemeData(
          backgroundColor: card,
          selectedColor: scheme.primaryContainer,
          labelStyle:
              TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text),
          secondaryLabelStyle: TextStyle(color: accent),
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: const StadiumBorder()),
      bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: card,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
          dragHandleColor: muted,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
      dialogTheme: DialogThemeData(
          backgroundColor: card,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titleTextStyle: typography.titleLarge),
      tabBarTheme: TabBarThemeData(
          labelColor: accent,
          unselectedLabelColor: muted,
          indicatorColor: accent,
          dividerColor: border,
          labelStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: onAccent,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      snackBarTheme: SnackBarThemeData(
          backgroundColor: dark ? const Color(0xFFDEE6F6) : AppColors.charcoal,
          contentTextStyle: TextStyle(
              color: dark ? AppColors.charcoal : Colors.white, fontSize: 15),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      dividerTheme: DividerThemeData(color: border, thickness: 0.6),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: accent, strokeWidth: 2.5),
      switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? onAccent : muted),
          trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? accent
                  : scheme.surfaceContainerHighest)),
    );
  }

  static SystemUiOverlayStyle systemOverlayStyle(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            dark ? AppColors.surfaceDark : AppColors.surfaceLight,
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark);
  }
}
