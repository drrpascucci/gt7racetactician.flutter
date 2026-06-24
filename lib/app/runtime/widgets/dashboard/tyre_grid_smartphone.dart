import 'package:flutter/material.dart';
import 'package:gt7_telemetry/gt7_telemetry.dart';

import '../../../config/app_config.dart';
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
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: TyreTile(
                      label: 'FL',
                      temp:  tyreTemps.isEmpty  ? 80 : tyreTemps.frontLeft,
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
                      temp: tyreTemps.isEmpty  ? 80 : tyreTemps.frontRight,
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
                      temp: tyreTemps.isEmpty  ? 80 : tyreTemps.rearLeft,
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
                      temp: tyreTemps.isEmpty  ? 80 : tyreTemps.rearRight,
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
        // Stylized GT Car in the middle
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
