import 'package:flutter/material.dart';

import 'package:gt7_design_system/src/theme/gt7_theme.dart';
import 'package:gt7_design_system/src/tokens/gt7_colors.dart';
import 'package:gt7_design_system/src/tokens/gt7_spacing.dart';
import 'package:gt7_design_system/src/tokens/gt7_typography.dart';

final class Gt7AppTheme {
  const Gt7AppTheme._();

  static ThemeData light() {
    const gt7Theme = Gt7Theme.light;
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Gt7Colors.highlight,
      onPrimary: Colors.black,
      secondary: Gt7Colors.predicted,
      onSecondary: Colors.black,
      tertiary: Gt7Colors.computed,
      onTertiary: Colors.black,
      error: Gt7Colors.danger,
      onError: Colors.white,
      surface: Color(0xFFF4F4F4),
      onSurface: Color(0xFF111111),
      onSurfaceVariant: Color(0xFF535353),
      outline: Color(0xFFB8B8B8),
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: Gt7Colors.panel,
      onInverseSurface: Gt7Colors.telemetry,
      inversePrimary: Gt7Colors.highlight,
    );

    return _buildTheme(colorScheme: colorScheme, gt7Theme: gt7Theme);
  }

  static ThemeData dark() {
    const gt7Theme = Gt7Theme.dark;
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Gt7Colors.highlight,
      onPrimary: Colors.black,
      secondary: Gt7Colors.predicted,
      onSecondary: Colors.black,
      tertiary: Gt7Colors.computed,
      onTertiary: Colors.black,
      error: Gt7Colors.danger,
      onError: Colors.white,
      surface: Gt7Colors.background,
      onSurface: Gt7Colors.telemetry,
      onSurfaceVariant: Gt7Colors.description,
      outline: Gt7Colors.border,
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,
      inversePrimary: Gt7Colors.highlight,
    );

    return _buildTheme(colorScheme: colorScheme, gt7Theme: gt7Theme);
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Gt7Theme gt7Theme,
  }) {
    final textTheme = Gt7Typography.textTheme(colorScheme);

    final stadiumShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Gt7Spacing.radiusPill),
      side: BorderSide(color: gt7Theme.border, width: 2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      fontFamily: 'Roboto Mono',
      textTheme: textTheme,
      scaffoldBackgroundColor: gt7Theme.background,
      canvasColor: gt7Theme.background,
      dividerColor: gt7Theme.border,
      splashColor: gt7Theme.highlight.withValues(alpha: 0.16),
      highlightColor: gt7Theme.highlight.withValues(alpha: 0.12),
      disabledColor: gt7Theme.textMuted,
      extensions: [gt7Theme],
      appBarTheme: AppBarTheme(
        backgroundColor: gt7Theme.headerSurface,
        foregroundColor: gt7Theme.telemetry,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: gt7Theme.panel,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Gt7Spacing.radiusPanel),
          side: BorderSide(color: gt7Theme.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Gt7Spacing.radiusPanel),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: gt7Theme.panel,
        iconColor: gt7Theme.highlight,
        textColor: gt7Theme.telemetry,
        contentPadding: Gt7Spacing.panelInsets,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Gt7Spacing.radiusPanel),
          side: BorderSide(color: gt7Theme.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: gt7Theme.panelAlt,
        selectedColor: gt7Theme.highlight,
        secondarySelectedColor: gt7Theme.highlight,
        disabledColor: gt7Theme.panel,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: textTheme.labelLarge!,
        secondaryLabelStyle: textTheme.labelLarge!,
        brightness: colorScheme.brightness,
        shape: StadiumBorder(side: BorderSide(color: gt7Theme.border)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black,
        hintStyle: textTheme.bodyMedium?.copyWith(color: gt7Theme.textMuted),
        labelStyle: textTheme.labelLarge?.copyWith(color: gt7Theme.description),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: Color(0xFF333333)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: gt7Theme.highlight, width: 2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gt7Theme.telemetry,
          textStyle: Gt7Typography.buttonLabel(gt7Theme.telemetry),
          side: BorderSide(color: gt7Theme.border, width: 2),
          backgroundColor: gt7Theme.panelAlt,
          shape: stadiumShape,
          minimumSize: const Size(0, Gt7Spacing.buttonHeightMedium),
          padding: const EdgeInsets.symmetric(horizontal: Gt7Spacing.lg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: gt7Theme.highlight,
          foregroundColor: Colors.black,
          textStyle: Gt7Typography.buttonLabel(Colors.black),
          shape: stadiumShape,
          minimumSize: const Size(0, Gt7Spacing.buttonHeightMedium),
          padding: const EdgeInsets.symmetric(horizontal: Gt7Spacing.lg),
        ),
      ),
    );
  }
}
