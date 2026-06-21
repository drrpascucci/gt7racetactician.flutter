import 'package:flutter/material.dart';

import 'package:gt7_design_system/src/tokens/gt7_colors.dart';

@immutable
class Gt7Theme extends ThemeExtension<Gt7Theme> {
  const Gt7Theme({
    required this.background,
    required this.panel,
    required this.panelAlt,
    required this.headerSurface,
    required this.border,
    required this.telemetry,
    required this.description,
    required this.textMuted,
    required this.highlight,
    required this.computed,
    required this.predicted,
    required this.userInput,
    required this.positive,
    required this.negative,
    required this.equal,
    required this.warning,
    required this.danger,
    required this.ledOff,
    required this.ledOutline,
  });

  static const dark = Gt7Theme(
    background: Gt7Colors.background,
    panel: Gt7Colors.panel,
    panelAlt: Gt7Colors.panelAlt,
    headerSurface: Gt7Colors.headerSurface,
    border: Gt7Colors.border,
    telemetry: Gt7Colors.telemetry,
    description: Gt7Colors.description,
    textMuted: Gt7Colors.textMuted,
    highlight: Gt7Colors.highlight,
    computed: Gt7Colors.computed,
    predicted: Gt7Colors.predicted,
    userInput: Gt7Colors.userInput,
    positive: Gt7Colors.positive,
    negative: Gt7Colors.negative,
    equal: Gt7Colors.equal,
    warning: Gt7Colors.warning,
    danger: Gt7Colors.danger,
    ledOff: Gt7Colors.ledOff,
    ledOutline: Gt7Colors.ledOutline,
  );

  static const light = Gt7Theme(
    background: Color(0xFFF4F4F4),
    panel: Colors.white,
    panelAlt: Color(0xFFE9E9E9),
    headerSurface: Color(0xFF111111),
    border: Color(0xFFBBBBBB),
    telemetry: Color(0xFF111111),
    description: Color(0xFFBBBBBB),
    textMuted: Color(0xFF757575),
    highlight: Gt7Colors.highlight,
    computed: Gt7Colors.computed,
    predicted: Gt7Colors.predicted,
    userInput: Gt7Colors.userInput,
    positive: Gt7Colors.positive,
    negative: Gt7Colors.negative,
    equal: Gt7Colors.equalBlue,
    warning: Gt7Colors.warning,
    danger: Gt7Colors.danger,
    ledOff: Color(0xFFD8D8D8),
    ledOutline: Color(0xFF9A9A9A),
  );

  final Color background;
  final Color panel;
  final Color panelAlt;
  final Color headerSurface;
  final Color border;
  final Color telemetry;
  final Color description;
  final Color textMuted;
  final Color highlight;
  final Color computed;
  final Color predicted;
  final Color userInput;
  final Color positive;
  final Color negative;
  final Color equal;
  final Color warning;
  final Color danger;
  final Color ledOff;
  final Color ledOutline;

  static Gt7Theme of(BuildContext context) {
    return Theme.of(context).extension<Gt7Theme>() ?? dark;
  }

  @override
  Gt7Theme copyWith({
    Color? background,
    Color? panel,
    Color? panelAlt,
    Color? headerSurface,
    Color? border,
    Color? telemetry,
    Color? description,
    Color? textMuted,
    Color? highlight,
    Color? computed,
    Color? predicted,
    Color? userInput,
    Color? positive,
    Color? negative,
    Color? equal,
    Color? warning,
    Color? danger,
    Color? ledOff,
    Color? ledOutline,
  }) {
    return Gt7Theme(
      background: background ?? this.background,
      panel: panel ?? this.panel,
      panelAlt: panelAlt ?? this.panelAlt,
      headerSurface: headerSurface ?? this.headerSurface,
      border: border ?? this.border,
      telemetry: telemetry ?? this.telemetry,
      description: description ?? this.description,
      textMuted: textMuted ?? this.textMuted,
      highlight: highlight ?? this.highlight,
      computed: computed ?? this.computed,
      predicted: predicted ?? this.predicted,
      userInput: userInput ?? this.userInput,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      equal: equal ?? this.equal,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      ledOff: ledOff ?? this.ledOff,
      ledOutline: ledOutline ?? this.ledOutline,
    );
  }

  @override
  Gt7Theme lerp(ThemeExtension<Gt7Theme>? other, double t) {
    if (other is! Gt7Theme) {
      return this;
    }

    return Gt7Theme(
      background: Color.lerp(background, other.background, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelAlt: Color.lerp(panelAlt, other.panelAlt, t)!,
      headerSurface: Color.lerp(headerSurface, other.headerSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      telemetry: Color.lerp(telemetry, other.telemetry, t)!,
      description: Color.lerp(description, other.description, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      computed: Color.lerp(computed, other.computed, t)!,
      predicted: Color.lerp(predicted, other.predicted, t)!,
      userInput: Color.lerp(userInput, other.userInput, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      equal: Color.lerp(equal, other.equal, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      ledOff: Color.lerp(ledOff, other.ledOff, t)!,
      ledOutline: Color.lerp(ledOutline, other.ledOutline, t)!,
    );
  }
}

extension Gt7BuildContextTheme on BuildContext {
  Gt7Theme get gt7Theme => Gt7Theme.of(this);
}
