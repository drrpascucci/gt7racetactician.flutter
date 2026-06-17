import 'package:flutter/material.dart';

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
    Color bg;
    final Color fg = Colors.white;
    final Color labelColor = Colors.white70;
    final IconData icon;

    if (!hasData || targetMs <= 0) {
      bg = const Color(0xFF1A1A1A);
      icon = Icons.pending;
    } else {
      final threshold = targetMs * 0.005; // 0.5%
      if (deltaMs < -threshold) {
        bg = const Color(0xFF43A047); // Green - Faster
        icon = Icons.arrow_downward;
      } else if (deltaMs > threshold) {
        bg = const Color(0xFFE53935); // Red - Slower
        icon = Icons.arrow_upward;
      } else {
        bg = const Color(0xFF1E88E5); // Blue - Similar
        icon = Icons.check;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF545454), width: 1),
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
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasData
                      ? formatAdaptiveSignedDurationMs(deltaMs, compact: true)
                      : '0.000',
                  style: TextStyle(
                    color: fg,
                    fontSize: UiConstants.compactBigFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(icon, color: fg, size: 27),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
