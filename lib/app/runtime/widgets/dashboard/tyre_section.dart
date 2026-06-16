import 'package:flutter/material.dart';

import '../../app_runtime_models.dart';
import '../../../config/app_config.dart';
import 'tyre_tile.dart';

class TyreSection extends StatelessWidget {
  const TyreSection({super.key, required this.telemetry, required this.config});

  final TelemetryViewState telemetry;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final tyreTemps = telemetry.tireTemperatures;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TyreTile(
                  label: 'FL',
                  temp: tyreTemps.isEmpty  ? 80 : tyreTemps.frontLeft,
                  coldMax: config.tyreColdMax,
                  optimalMax: config.tyreOptimalMax,
                  hotMax: config.tyreHotMax,
                  viewMode: config.viewMode,
                ),
              ),
              Container(width: 1, color: const Color(0xFF333333)),
              Expanded(
                child: TyreTile(
                  label: 'FR',
                  temp:  tyreTemps.isEmpty  ? 80 : tyreTemps.frontRight,
                  coldMax: config.tyreColdMax,
                  optimalMax: config.tyreOptimalMax,
                  hotMax: config.tyreHotMax,
                  viewMode: config.viewMode,
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFF333333)),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TyreTile(
                  label: 'RL',
                  temp:  tyreTemps.isEmpty  ? 80 : tyreTemps.rearLeft,
                  coldMax: config.tyreColdMax,
                  optimalMax: config.tyreOptimalMax,
                  hotMax: config.tyreHotMax,
                  viewMode: config.viewMode,
                ),
              ),
              Container(width: 1, color: const Color(0xFF333333)),
              Expanded(
                child: TyreTile(
                  label: 'RR',
                  temp:  tyreTemps.isEmpty  ? 80 : tyreTemps.rearRight,
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
