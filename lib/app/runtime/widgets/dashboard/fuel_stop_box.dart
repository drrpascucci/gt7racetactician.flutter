import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';
import 'package:gt7_domain/gt7_domain.dart';

import '../../app_runtime_models.dart';
import '../../ui_constants.dart';

class FuelStopBox extends StatelessWidget {
  const FuelStopBox({
    super.key,
    required this.stopLap,
    required this.hasData,
    required this.raceType,
    required this.targetLaps,
    required this.predictedStints,
    required this.targetRaceTimeMs,
  });

  final int stopLap;
  final bool hasData;
  final RaceType raceType;
  final int targetLaps;
  final List<RaceStint> predictedStints;
  final double targetRaceTimeMs;

  bool _isStopBeyondRaceEnd() {
    if (!hasData || stopLap <= 0) {
      return false;
    }

    if (raceType == RaceType.lapRace) {
      // For lap races: show * if stop lap >= total laps
      return stopLap >= targetLaps;
    } else {
      // For time races: check if first stint ends after race duration
      if (predictedStints.isEmpty) {
        return false;
      }
      return predictedStints.first.endTimeMs >= targetRaceTimeMs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBeyondEnd = _isStopBeyondRaceEnd();
    final lapText = !hasData || stopLap <= 0
        ? '???'
        : isBeyondEnd
        ? 'NO STOP'
        : 'L $stopLap';
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            lapText,
            style: const TextStyle(
              color: Gt7Colors.lapsForeColor,
              fontSize: UiConstants.compactBigFontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'RobotoMono',
            ),
          ),
          const Text(
            'NEXT STOP',
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
