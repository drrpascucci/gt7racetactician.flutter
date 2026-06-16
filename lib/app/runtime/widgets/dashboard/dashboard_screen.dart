import 'package:flutter/material.dart';

import '../../app_runtime_controller.dart';
import '../../app_runtime_models.dart';
import '../../../config/app_config.dart';
import 'dashboard_status_bar.dart';
import 'dashboard_toolbar.dart';
import 'dashboard_top_bar.dart';
import 'lap_section.dart';
import 'smartphone_dashboard.dart';
import 'strategy_section.dart';
import 'tyre_section.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.config,
    required this.telemetry,
    required this.connection,
    required this.race,
    required this.onToggleViewMode,
  });

  final AppRuntimeController controller;
  final AppConfig config;
  final TelemetryViewState telemetry;
  final RuntimeConnectionState connection;
  final RaceViewState race;
  final VoidCallback onToggleViewMode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showStatusBar = constraints.maxWidth >= 500;
        final isSmartphone = config.viewMode == DashboardViewMode.smartphone;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ROW 1 — header: logo + RPM display + LED bar
            SizedBox(
              height: 44,
              child: DashboardTopBar(config: config, telemetry: telemetry),
            ),
            if (!isSmartphone) ...[
              // ROW 1b — strategy banner (full width)
              StrategySection(race: race),
              Container(height: 1, color: const Color(0xFF333333)),
            ],
            // ROW 2 — main content (Expanded) — double-tap toggles view mode
            Expanded(
              child: GestureDetector(
                onDoubleTap: onToggleViewMode,
                behavior: HitTestBehavior.opaque,
                child: config.viewMode == DashboardViewMode.smartphone
                    ? SmartphoneDashboard(
                        race: race,
                        telemetry: telemetry,
                        config: config,
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 80, child: LapSection(race: race)),
                          Container(width: 1, color: const Color(0xFF333333)),
                          Expanded(
                            flex: 20,
                            child: TyreSection(
                              telemetry: telemetry,
                              config: config,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            // ROW 3 — button toolbar
            SizedBox(
              height: 44,
              child: DashboardToolbar(
                controller: controller,
                connection: connection,
              ),
            ),
            if (showStatusBar)
              DashboardStatusBar(telemetry: telemetry, connection: connection),
          ],
        );
      },
    );
  }
}
