import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Gt7Colors.panel,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF545454), width: 2),
      ),
      padding: const EdgeInsets.all(5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 30,
                child: Text(
                  "TYRE TEMPS °",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Gt7Colors.boxLabel,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
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
        ],
      ),
    );
  }
}
