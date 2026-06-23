import 'package:flutter/material.dart';
import 'package:gt7_domain/gt7_domain.dart';

import '../../ui_constants.dart';

class RemainingRaceBox extends StatelessWidget {
  const RemainingRaceBox({
    super.key,
    required this.raceType,
    required this.remainingLaps,
    required this.remainingTime,
  });

  final RaceType raceType;
  final int remainingLaps;
  final Duration remainingTime;

  @override
  Widget build(BuildContext context) {
    String label;
    String value;
    bool showFlag = false;

    if (raceType == RaceType.lapRace) {
      label = 'LAPS TO GO';
      value = remainingLaps > 0 ? '$remainingLaps' : '0';
    } else {
      label = 'TIME REMAINING';
      if (remainingTime <= Duration.zero) {
        value = '';
        showFlag = true;
      } else if (remainingTime.inMinutes >= 1) {
        value = '${remainingTime.inMinutes}m';
      } else {
        value = '${remainingTime.inSeconds}s';
      }
    }

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
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: showFlag
                ? const Icon(Icons.flag, color: Colors.white, size: 40)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
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
