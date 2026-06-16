import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

import '../../ui_constants.dart';

class RemainingStopsBox extends StatelessWidget {
  const RemainingStopsBox({super.key, required this.stops, required this.hasData});

  final int stops;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hasData ? '$stops' : '00',
            style: const TextStyle(
              color: Gt7Colors.lapsForeColor,
              fontSize: UiConstants.compactBigFontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'RobotoMono',
            ),
          ),
          const Text(
            'TOT STOPS',
            style: TextStyle(
              color: Gt7Colors.lapsForeColor,
              fontSize: UiConstants.smallFontSize, // 9 * 3
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
