import 'package:flutter/material.dart';
import 'package:gt7_domain/gt7_domain.dart';

import '../../app_runtime_models.dart';
import '../runtime_ui_utils.dart';

class StrategySection extends StatelessWidget {
  const StrategySection({super.key, required this.race});

  final RaceViewState race;

  @override
  Widget build(BuildContext context) {
    final config = race.config;
    final raceLength = config.raceType == RaceType.timeRace
        ? '${config.targetRaceTime.inMinutes} min'
        : '${config.targetLaps} laps';
    final avgTargetMs = config.targetLaps <= 0
        ? 0.0
        : config.targetRaceTime.inMilliseconds / config.targetLaps;
    final bannerText = race.predictedStopLap <= 0
        ? 'GO TO THE END'
        : 'PIT LAP ${race.predictedStopLap}';
    final targetLabel = formatDurationMs(
      config.targetRaceTime.inMilliseconds.toDouble(),
    );
    final avgLabel = formatDurationMs(avgTargetMs);

    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF282828),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: const Text(
              'DRIVER ASSIST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 13,
                  color: const Color(0xFF222222),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'Strategy',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 7,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        color: const Color(0xFF1A1A1A),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        child: Text(
                          bannerText,
                          style: const TextStyle(
                            color: Color(0xFFFFB300),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Length: $raceLength',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Target: $targetLabel',
                                style: const TextStyle(
                                  color: Color(0xFF64B5F6),
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Avg: $avgLabel',
                                style: const TextStyle(
                                  color: Color(0xFFFFB300),
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
