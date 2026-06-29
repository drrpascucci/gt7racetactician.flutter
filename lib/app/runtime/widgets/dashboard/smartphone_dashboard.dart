import 'package:flutter/material.dart';

import '../../app_runtime_models.dart';
import '../../../config/app_config.dart';
import 'current_lap_box.dart';
import 'delta_box.dart';
import 'fuel_level_box.dart';
import 'fuel_stop_box.dart';
import 'remaining_stops_box.dart';
import 'tyre_grid_smartphone.dart';

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: CurrentLapBox(
                  currentLap: race.currentLapNumber,
                  odometer: race.totalDistanceMeters,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: FuelStopBox(
                  stopLap: stopLap,
                  hasData: hasData,
                  raceType: config.raceType,
                  targetLaps: config.targetLaps,
                  predictedStints: predictedStints,
                  targetRaceTimeMs: config.targetRaceTime.inMilliseconds.toDouble(),
                  currentLap: race.currentLapNumber,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: DeltaBox(
                  label: 'LAST LAP',
                  deltaMs: lastLapDelta,
                  hasData: hasLastLap,
                  targetMs: targetLapMs,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: FuelLevelBox(fuelLevel: telemetry.fuelLevel),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: RemainingStopsBox(
                  stops: remainingStops,
                  hasData: hasData,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: DeltaBox(
                  label: 'AVERAGE LAP',
                  deltaMs: avgDelta,
                  hasData: hasAvgData,
                  targetMs: targetLapMs,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          flex: 1,
          child: TyreGridSmartphone(
            tyreTemps: temps,
            config: config,
          ),
        ),
      ],
    );
  }
}
