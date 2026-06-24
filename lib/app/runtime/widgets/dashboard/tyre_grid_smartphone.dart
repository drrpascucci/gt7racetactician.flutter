import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';
import 'package:gt7_telemetry/gt7_telemetry.dart';

import '../../../config/app_config.dart';
import '../../ui_constants.dart';
import 'tyre_tile.dart';

class TyreGridSmartphone extends StatelessWidget {
  TyreGridSmartphone({
    super.key,
    required this.tyreTemps,
    required this.config,
    this.cellSpacing = 4,
  });

  final Gt7WheelValues tyreTemps;
  final AppConfig config;
  double cellSpacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Gt7Colors.panel,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color:  const Color(0xFF545454), width: 2),
      ),
      padding: const EdgeInsets.all(5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              SizedBox(
                height: 30,
                child: Text(
                  "TYRE TEMPS °",
                  style: TextStyle(
                    color: Gt7Colors.description,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TyreTile(
                        label: 'FL',
                        temp: tyreTemps.isEmpty ? 80 : tyreTemps.frontLeft,
                        coldMax: config.tyreColdMax,
                        optimalMax: config.tyreOptimalMax,
                        hotMax: config.tyreHotMax,
                        viewMode: config.viewMode,
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(width: cellSpacing),
                    Expanded(
                      child: TyreTile(
                        label: 'FR',
                        temp: tyreTemps.isEmpty ? 80 : tyreTemps.frontRight,
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
              SizedBox(height: cellSpacing),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TyreTile(
                        label: 'RL',
                        temp: tyreTemps.isEmpty ? 80 : tyreTemps.rearLeft,
                        coldMax: config.tyreColdMax,
                        optimalMax: config.tyreOptimalMax,
                        hotMax: config.tyreHotMax,
                        viewMode: config.viewMode,
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(width: cellSpacing),
                    Expanded(
                      child: TyreTile(
                        label: 'RR',
                        temp: tyreTemps.isEmpty ? 80 : tyreTemps.rearRight,
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
          ),
        ],
      ),
    );
  }
}
