import 'package:flutter/material.dart';

import '../../ui_constants.dart';
import '../runtime_ui_utils.dart';

class DeltaBox extends StatelessWidget {
  const DeltaBox({
    super.key,
    required this.label,
    required this.deltaMs,
    required this.hasData,
  });

  final String label;
  final double deltaMs;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;

    if (!hasData) {
      bg = const Color(0xFF1A1A1A);
      fg = const Color(0xFF666666);
      icon = Icons.pending;
    } else if (deltaMs < -1000) {
      bg = const Color(0xFF0A2540); // blue — faster
      fg = const Color(0xFF42A5F5);
      icon = Icons.arrow_downward;
    } else if (deltaMs > 1000) {
      bg = const Color(0xFF3B0000); // red — slower
      fg = const Color(0xFFEF5350);
      icon = Icons.arrow_upward;
    } else {
      bg = const Color(0xFF0D2010); // green — on target
      fg = const Color(0xFF66BB6A);
      if (deltaMs > 0) {
        icon = Icons.arrow_downward;
      } else if (deltaMs < 0) {
        icon = Icons.arrow_upward;
      } else {
        icon = Icons.check;
      }
    }

    return Container(
      color: bg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: fg.withValues(alpha: 0.7),
              fontSize: UiConstants.smallFontSize, // 9 * 3
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasData
                ? formatAdaptiveSignedDurationMs(deltaMs, compact: true)
                : '0.000',
            style: TextStyle(
              color: fg,
              fontSize: UiConstants.compactBigFontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(height: 2),
          Icon(icon, color: fg, size: 27),
        ],
      ),
    );
  }
}
