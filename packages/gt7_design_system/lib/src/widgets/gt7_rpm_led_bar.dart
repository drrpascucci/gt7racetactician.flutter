import 'package:flutter/material.dart';

import 'package:gt7_design_system/src/theme/gt7_theme.dart';
import 'package:gt7_design_system/src/tokens/gt7_spacing.dart';
import 'package:gt7_design_system/src/tokens/gt7_typography.dart';

class Gt7RpmLedBar extends StatelessWidget {
  const Gt7RpmLedBar({
    super.key,
    required this.rpm,
    required this.limit,
    this.blinkAboveRpm,
    this.label,
    this.totalLeds = 20,
    this.compact = false,
  });

  final double rpm;
  final double limit;
  /// When set, LEDs blink when [rpm] >= [blinkAboveRpm].
  /// Falls back to 98% of [limit] when null.
  final double? blinkAboveRpm;
  final String? label;
  final int totalLeds;
  final bool compact;

  static bool shouldBlink({
    required double rpm,
    required double limit,
    double? blinkAboveRpm,
    double blinkThreshold = 0.98,
  }) {
    if (limit <= 0) {
      return false;
    }
    final threshold = blinkAboveRpm ?? (limit * blinkThreshold);
    return rpm >= threshold;
  }

  static int activeLedCountFor({
    required double rpm,
    required double limit,
    int pTotalLeds = 20,
    double startThreshold = 0.80,
    double stepPercent = 0.02,
  }) {
    if (limit <= 0 || rpm < limit * startThreshold) {
      return 0;
    }
    stepPercent = (1-startThreshold) / pTotalLeds;

    final step = limit * stepPercent;
    final rpmAboveThreshold = rpm - (limit * startThreshold);

    return (rpmAboveThreshold / step).floor().clamp(0, pTotalLeds - 1) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final gt7 = context.gt7Theme;
    final ledHeight = compact ? 21.6 : 28.8;
    final blink = shouldBlink(rpm: rpm, limit: limit, blinkAboveRpm: blinkAboveRpm);
    final activeLeds = blink
        ? totalLeds
        : activeLedCountFor(rpm: rpm, limit: limit, pTotalLeds: totalLeds);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var index = 0; index < totalLeds; index++)
              Expanded(
                child: Container(
                  key: ValueKey('gt7-led-$index'),
                  height: ledHeight,
                  constraints: BoxConstraints(maxWidth: ledHeight),
                  margin: EdgeInsets.only(
                    right: index == totalLeds - 1 ? 0 : Gt7Spacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: _ledColor(
                      index: index,
                      gt7: gt7,
                      activeLeds: activeLeds,
                      blink: blink,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: gt7.ledOutline),
                  ),
                ),
              ),
          ],
        ),
        if (label != null) ...[
          const SizedBox(height: Gt7Spacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: gt7.headerSurface,
              borderRadius: BorderRadius.circular(Gt7Spacing.radiusMedium),
              border: Border.all(color: gt7.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Gt7Spacing.md,
                vertical: Gt7Spacing.sm,
              ),
              child: Text(
                label!,
                style: Gt7Typography.telemetryValue(
                  blink ? gt7.danger : gt7.highlight,
                  size: compact ? 18 : 22,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _ledColor({
    required int index,
    required Gt7Theme gt7,
    required int activeLeds,
    required bool blink,
  }) {
    if (blink) {
      return gt7.danger;
    }

    if (index >= activeLeds) {
      return gt7.ledOff;
    }

    final progress = totalLeds == 1 ? 1.0 : index / (totalLeds - 1);

    if (progress < 0.6) {
      return Color.lerp(gt7.highlight, gt7.predicted, progress / 0.6)!;
    }

    return Color.lerp(gt7.predicted, gt7.danger, (progress - 0.6) / 0.4)!;
  }
}
