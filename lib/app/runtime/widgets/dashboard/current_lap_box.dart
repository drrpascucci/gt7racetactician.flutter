import 'package:flutter/material.dart';

import '../../ui_constants.dart';

class CurrentLapBox extends StatelessWidget {
  const CurrentLapBox({super.key, required this.currentLap});

  final int currentLap;

  @override
  Widget build(BuildContext context) {
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
              'CURRENT LAP',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  currentLap > 0 ? '$currentLap' : '1',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: UiConstants.compactBigFontSize,
                    fontWeight: FontWeight.bold,
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
