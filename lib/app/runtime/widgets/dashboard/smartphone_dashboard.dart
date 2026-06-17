import 'package:flutter/material.dart';

import '../../app_runtime_models.dart';
import '../../../config/app_config.dart';
import 'delta_box.dart';
import 'fuel_stop_box.dart';
import 'remaining_stops_box.dart';
import 'tyre_tile.dart';

class SmartphoneDashboard extends StatelessWidget {
  const SmartphoneDashboard({
    super.key,
    required this.race,
    required this.telemetry,
    required this.config,
  });

  final RaceViewState race;
  final TelemetryViewState telemetry;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final temps = telemetry.tireTemperatures;
    final targetLapMs = race.targetAvgLapTimeMs;
    final lastLapDelta = race.lastCompletedLap?.deltaFromTargetMs ?? 0.0;
    final hasLastLap = race.lastCompletedLap != null;
    final avgDelta = (race.averageLapTimeMs > 0 && targetLapMs > 0)
        ? race.averageLapTimeMs - targetLapMs
        : 0.0;
    final hasAvgData = race.averageLapTimeMs > 0 && targetLapMs > 0;

    final predictedStints = race.predictedStints;
    final stopLap = race.predictedStopLap;
    final remainingStops = (predictedStints.length - 1).clamp(0, 999);
    final hasData = predictedStints.isNotEmpty;

    const sep = Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1: LAST LAP | AVG LAP | FL | FR
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DeltaBox(
                  label: 'LAST LAP',
                  deltaMs: lastLapDelta,
                  hasData: hasLastLap,
                  targetMs: targetLapMs,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: DeltaBox(
                  label: 'AVG LAP',
                  deltaMs: avgDelta,
                  hasData: hasAvgData,
                  targetMs: targetLapMs,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: TyreTile(
                  label: 'FL',
                  temp: temps.isEmpty ? 80 : temps.frontLeft,
                  coldMax: config.tyreColdMax,
                  optimalMax: config.tyreOptimalMax,
                  hotMax: config.tyreHotMax,
                  viewMode: config.viewMode,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: TyreTile(
                  label: 'FR',
                  temp: temps.isEmpty ? 80 : temps.frontRight,
                  coldMax: config.tyreColdMax,
                  optimalMax: config.tyreOptimalMax,
                  hotMax: config.tyreHotMax,
                  viewMode: config.viewMode,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        // Row 2: NEXT STOP | TOT STOPS | RL | RR
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: FuelStopBox(
                  stopLap: stopLap,
                  hasData: hasData,
                  raceType: config.raceType,
                  targetLaps: config.targetLaps,
                  predictedStints: predictedStints,
                  targetRaceTimeMs: config.targetRaceTime.inMilliseconds.toDouble(),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: RemainingStopsBox(
                  stops: remainingStops,
                  hasData: hasData,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: TyreTile(
                  label: 'RL',
                  temp: temps.isEmpty ? 80 : temps.rearLeft,
                  coldMax: config.tyreColdMax,
                  optimalMax: config.tyreOptimalMax,
                  hotMax: config.tyreHotMax,
                  viewMode: config.viewMode,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: TyreTile(
                  label: 'RR',
                  temp: temps.isEmpty ? 80 : temps.rearRight,
                  coldMax: config.tyreColdMax,
                  optimalMax: config.tyreOptimalMax,
                  hotMax: config.tyreHotMax,
                  viewMode: config.viewMode,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
