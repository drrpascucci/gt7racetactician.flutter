import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart' show Gt7Colors;

import '../../ui_constants.dart';
import '../runtime_ui_utils.dart';

class DeltaBox extends StatelessWidget {
  const DeltaBox({
    super.key,
    required this.label,
    required this.deltaMs,
    required this.hasData,
    this.targetMs = 0,
  });

  final String label;
  final double deltaMs;
  final bool hasData;
  final double targetMs;

  @override
  Widget build(BuildContext context) {
    final Color qualitativeColor;
    final bg = const Color(0xFF1A1A1A); // Always dark gray background
    final Color labelColor = Gt7Colors.boxLabel;
    final IconData icon;

    if (!hasData || targetMs <= 0) {
      qualitativeColor = const Color(0xFF545454);
      icon = Icons.pending;
    } else {
      final threshold = targetMs * 0.005; // 0.5%
      if (deltaMs < -threshold) {
        qualitativeColor = const Color(0xFF43A047); // Green - Faster
        icon = Icons.arrow_downward;
      } else if (deltaMs > threshold) {
        qualitativeColor = const Color(0xFFE53935); // Red - Slower
        icon = Icons.arrow_upward;
      } else {
        qualitativeColor = const Color(0xFF1E88E5); // Blue - Similar
        icon = Icons.check;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: qualitativeColor, width: 3), // Thicker border
      ),

      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 6,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: labelColor,
                fontSize: 14.4,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontFamily: 'Rubik',
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasData
                      ? formatAdaptiveSignedDurationMs(deltaMs, compact: true)
                      : '0.000',
                  style: TextStyle(
                    color: qualitativeColor, // Text color matches border
                    fontSize: UiConstants.compactBigFontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, color: qualitativeColor, size: 27),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
