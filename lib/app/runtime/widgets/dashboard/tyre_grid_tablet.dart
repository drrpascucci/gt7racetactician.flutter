import 'package:flutter/material.dart';

import '../../app_runtime_models.dart';
import '../../../config/app_config.dart';
import 'tyre_tile.dart';

class TyreGridTablet extends StatelessWidget {
  const TyreGridTablet({
    super.key,
    required this.telemetry,
    required this.config,
  });

  final TelemetryViewState telemetry;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final tyreTemps = telemetry.tireTemperatures;
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TyreTile(
                      label: 'FL',
                      temp: tyreTemps.isEmpty ? 80 : tyreTemps.frontLeft,
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
                      temp: tyreTemps.isEmpty ? 80 : tyreTemps.frontRight,
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
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TyreTile(
                      label: 'RL',
                      temp: tyreTemps.isEmpty ? 80 : tyreTemps.rearLeft,
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
                      temp: tyreTemps.isEmpty ? 80 : tyreTemps.rearRight,
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
        ),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            'assets/images/gt_car.png',
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
