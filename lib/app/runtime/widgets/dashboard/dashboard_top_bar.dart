import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

import '../../app_runtime_models.dart';
import '../../../config/app_config.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({super.key, required this.config, required this.telemetry});

  final AppConfig config;
  final TelemetryViewState telemetry;

  @override
  Widget build(BuildContext context) {
    final rpm = telemetry.engineRpm;
    final packet = telemetry.packet;
    // Use maxAlertRpm from live telemetry when available; fall back to 7800
    final maxAlertRpm = (packet != null && packet.maxAlertRpm > 0)
        ? packet.maxAlertRpm.toDouble()
        : 7800.0;
    // Apply short shift percentage to get the effective LED max
    final rpmLimit = maxAlertRpm * (config.shiftPercentage / 100.0);
    final blinkAboveRpm = (packet != null && packet.minAlertRpm > 0)
        ? packet.minAlertRpm.toDouble()
        : null;
    final rpmFraction = rpmLimit > 0 ? (rpm / rpmLimit).clamp(0.0, 1.0) : 0.0;

    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo area
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22) ,
                color: Colors.white),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Image.asset('assets/images/gt7_tactician_icon.png'),
            ),
          ),
          const SizedBox(width: 6),
          // RPM display: value text + thin progress bar
          SizedBox(
            width: 120,
            child: Text(
              rpm.toStringAsFixed(0),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 28,
                fontWeight: FontWeight.bold,

              ),
            ),
          ),
          const SizedBox(width: 20),
          // Gear LED bar — fills remaining space
          Expanded(
            child: Gt7RpmLedBar(
              rpm: rpm,
              limit: rpmLimit,
              blinkAboveRpm: blinkAboveRpm,
              compact: true,
              totalLeds: config.viewMode == DashboardViewMode.smartphone ? 20 : 30,
            ),
          ),
        ],
      ),
    );
  }
}
