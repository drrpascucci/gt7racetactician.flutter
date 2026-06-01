import 'package:flutter/material.dart';

final class Gt7Typography {
  const Gt7Typography._();

  static const _sansFallback = <String>['Roboto', 'Arial'];
  static const _monoFallback = <String>[
    'Roboto Mono',
    'Consolas',
    'Courier New',
  ];

  static TextTheme textTheme(ColorScheme colorScheme) {
    final baseColor = colorScheme.onSurface;
    final mutedColor = colorScheme.onSurfaceVariant;

    return TextTheme(
      displaySmall: _headline(28, baseColor),
      headlineMedium: _headline(24, baseColor),
      headlineSmall: _headline(20, baseColor),
      titleLarge: _headline(18, baseColor),
      titleMedium: _headline(16, baseColor, spacing: 0.2),
      titleSmall: _headline(14, baseColor, spacing: 0.4),
      bodyLarge: _body(16, baseColor),
      bodyMedium: _body(14, baseColor),
      bodySmall: _body(12, mutedColor),
      labelLarge: buttonLabel(baseColor),
      labelMedium: _body(12, mutedColor, weight: FontWeight.w600),
      labelSmall: _body(11, mutedColor, weight: FontWeight.w600),
    );
  }

  static TextStyle buttonLabel(Color color, {double size = 14}) {
    return _headline(size, color, spacing: 0.7);
  }

  static TextStyle telemetryValue(
    Color color, {
    double size = 24,
    FontWeight weight = FontWeight.w700,
  }) {
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      fontFamilyFallback: _monoFallback,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: 0.2,
      height: 1.1,
    );
  }

  static TextStyle tableHeader(Color color) {
    return telemetryValue(
      color,
      size: 14,
      weight: FontWeight.w700,
    ).copyWith(letterSpacing: 0.8);
  }

  static TextStyle tableCell(Color color) {
    return telemetryValue(color, size: 13, weight: FontWeight.w500);
  }

  static TextStyle _headline(double size, Color color, {double spacing = 0.6}) {
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: spacing,
      height: 1.15,
      fontFamilyFallback: _sansFallback,
    );
  }

  static TextStyle _body(
    double size,
    Color color, {
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: 0.1,
      height: 1.3,
      fontFamilyFallback: _sansFallback,
    );
  }
}
