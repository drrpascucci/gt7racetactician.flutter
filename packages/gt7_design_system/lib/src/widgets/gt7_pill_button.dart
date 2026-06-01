import 'package:flutter/material.dart';

import 'package:gt7_design_system/src/theme/gt7_theme.dart';
import 'package:gt7_design_system/src/tokens/gt7_spacing.dart';
import 'package:gt7_design_system/src/tokens/gt7_typography.dart';

enum Gt7ButtonVariant { primary, secondary, warning, danger }

enum Gt7ButtonSize { small, medium, large }

class Gt7PillButton extends StatelessWidget {
  const Gt7PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = Gt7ButtonVariant.primary,
    this.size = Gt7ButtonSize.medium,
    this.icon,
    this.expand = false,
    this.showLabel = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Gt7ButtonVariant variant;
  final Gt7ButtonSize size;
  final Widget? icon;
  final bool expand;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final gt7 = context.gt7Theme;
    final scheme = _resolveScheme(gt7);
    final minimumHeight = switch (size) {
      Gt7ButtonSize.small => Gt7Spacing.buttonHeightSmall,
      Gt7ButtonSize.medium => Gt7Spacing.buttonHeightMedium,
      Gt7ButtonSize.large => Gt7Spacing.buttonHeightLarge,
    };
    final horizontalPadding = switch (size) {
      Gt7ButtonSize.small => Gt7Spacing.md,
      Gt7ButtonSize.medium => Gt7Spacing.lg,
      Gt7ButtonSize.large => Gt7Spacing.xl,
    };
    final fontSize = switch (size) {
      Gt7ButtonSize.small => 13.0,
      Gt7ButtonSize.medium => 14.0,
      Gt7ButtonSize.large => 16.0,
    };
    final iconOnly = icon != null && !showLabel;

    final button = SizedBox(
      width: expand ? double.infinity : null,
      height: minimumHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.foreground,
          backgroundColor: scheme.background,
          disabledForegroundColor: gt7.textMuted,
          disabledBackgroundColor: gt7.panel,
          side: BorderSide(color: scheme.border, width: 2),
          padding: EdgeInsets.symmetric(
            horizontal: iconOnly ? Gt7Spacing.sm : horizontalPadding,
          ),
          minimumSize: iconOnly ? Size.square(minimumHeight) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Gt7Spacing.radiusPill),
          ),
          textStyle: Gt7Typography.buttonLabel(
            scheme.foreground,
            size: fontSize,
          ),
        ),
        child: iconOnly
            ? Semantics(
                label: label,
                child: ExcludeSemantics(child: icon!),
              )
            : icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: Gt7Spacing.xs),
                  Text(label),
                ],
              ),
      ),
    );

    if (expand) {
      return button;
    }

    return IntrinsicWidth(child: button);
  }

  _Gt7ButtonScheme _resolveScheme(Gt7Theme gt7) {
    return switch (variant) {
      Gt7ButtonVariant.primary => _Gt7ButtonScheme(
        background: gt7.panelAlt,
        foreground: gt7.telemetry,
        border: gt7.border,
      ),
      Gt7ButtonVariant.secondary => _Gt7ButtonScheme(
        background: gt7.panelAlt,
        foreground: gt7.userInput,
        border: gt7.border,
      ),
      Gt7ButtonVariant.warning => _Gt7ButtonScheme(
        background: gt7.panelAlt,
        foreground: gt7.predicted,
        border: gt7.border,
      ),
      Gt7ButtonVariant.danger => _Gt7ButtonScheme(
        background: gt7.danger,
        foreground: gt7.telemetry,
        border: gt7.border,
      ),
    };
  }
}

final class _Gt7ButtonScheme {
  const _Gt7ButtonScheme({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
