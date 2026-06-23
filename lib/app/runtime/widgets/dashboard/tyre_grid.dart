import 'package:flutter/material.dart';
import 'package:gt7_telemetry/gt7_telemetry.dart';

import '../../../config/app_config.dart';
import 'tyre_tile.dart';

class TyreGrid extends StatelessWidget {
  const TyreGrid({
    super.key,
    required this.tireTemperatures,
    required this.config,
  });

  final Gt7WheelValues tireTemperatures;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: TyreTile(
                  label: 'FL',
                  temp: tireTemperatures.frontLeft,
                  coldMax: config.tyreColdMax,
                  optimalMax: config.tyreOptimalMax,
                  hotMax: config.tyreHotMax,
                  viewMode: config.viewMode,
                  fontSize: 24,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: TyreTile(
                  label: 'FR',
                  temp: tireTemperatures.frontRight,
                  coldMax: config.tyreColdMax,
                  optimalMax: config.tyreOptimalMax,
                  hotMax: config.tyreHotMax,
                  viewMode: config.viewMode,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: TyreTile(
                  label: 'RL',
                  temp: tireTemperatures.rearLeft,
                  coldMax: config.tyreColdMax,
                  optimalMax: config.tyreOptimalMax,
                  hotMax: config.tyreHotMax,
                  viewMode: config.viewMode,
                  fontSize: 24,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: TyreTile(
                  label: 'RR',
                  temp: tireTemperatures.rearRight,
                  coldMax: config.tyreColdMax,
                  optimalMax: config.tyreOptimalMax,
                  hotMax: config.tyreHotMax,
                  viewMode: config.viewMode,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
