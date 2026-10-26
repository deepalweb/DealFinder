import 'package:flutter/material.dart';
import 'stitch_discover_components.dart' show stitchDiscoverTheme;

/// Store pages inherit the accepted marketplace palette for every control.
ThemeData storefrontTheme(ThemeData base) {
  final theme = stitchDiscoverTheme(base);
  final colors = theme.colorScheme;
  return theme.copyWith(
    appBarTheme: theme.appBarTheme.copyWith(
        iconTheme: IconThemeData(color: colors.onSurface),
        actionsIconTheme: IconThemeData(color: colors.onSurface)),
    cardTheme: theme.cardTheme.copyWith(
        color: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant))),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            minimumSize: const Size(48, 48),
            textStyle: theme.textTheme.labelLarge)),
    chipTheme: theme.chipTheme.copyWith(
        labelStyle:
            theme.textTheme.labelLarge?.copyWith(color: colors.onSurface),
        secondaryLabelStyle: theme.textTheme.labelLarge
            ?.copyWith(color: colors.onPrimaryContainer),
        selectedColor: colors.primaryContainer,
        secondarySelectedColor: colors.primaryContainer,
        checkmarkColor: colors.onPrimaryContainer,
        backgroundColor: colors.surfaceContainerLowest,
        side: BorderSide(color: colors.outlineVariant)),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            minimumSize: const Size(48, 48),
            textStyle: theme.textTheme.labelLarge)),
  );
}
