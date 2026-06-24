import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

import '../../app_runtime_models.dart';
import '../../../config/app_config.dart';
import '../../ui_constants.dart';
import '../runtime_ui_utils.dart';

class TyreTile extends StatelessWidget {
  const TyreTile({
    super.key,
    required this.label,
    required this.temp,
    required this.coldMax,
    required this.optimalMax,
    required this.hotMax,
    required this.viewMode,
    this.fontSize,
  });

  final String label;
  final double temp;
  final int coldMax;
  final int optimalMax;
  final int hotMax;
  final DashboardViewMode viewMode;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final tone = tyreTone(
      temp,
      coldMax: coldMax,
      optimalMax: optimalMax,
      hotMax: hotMax,
    );

    // Determine corner position: FL=top-left, FR=top-right, RL=bottom-left, RR=bottom-right
    final bool isTopCorner = label == 'FL' || label == 'FR';
    final bool isLeftCorner = label == 'FL' || label == 'RL';

    final isBright = tone.computeLuminance() > 0.5;
    final contentColor = isBright ? Colors.black : Colors.white;
    final labelColor = isBright ? Colors.black54 : Colors.white70;

    return Container(
      decoration: BoxDecoration(
        color: Gt7Colors.panel,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: tone, width: 8),
      ),
      child: Center(
        child: Text(
          temperatureLabel(temp),
          style: TextStyle(
            color: contentColor,
            fontSize: UiConstants.getBigFontSize(viewMode),
            fontWeight: FontWeight.bold,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ),
    );
  }
}
