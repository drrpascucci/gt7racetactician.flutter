import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

import '../../ui_constants.dart';

class RemainingStopsBox extends StatelessWidget {
  const RemainingStopsBox({super.key, required this.stops, required this.hasData});

  final int stops;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final double fontSize = hasData ? UiConstants.compactBigFontSize : UiConstants.smallFontSize;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF545454), width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 6,
            child: const Text(
              'STOPS REMAINING',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.4,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  hasData ? '$stops' : 'UPDATING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
