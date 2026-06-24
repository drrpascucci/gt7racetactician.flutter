import 'package:flutter/material.dart';
import 'package:gt7_domain/gt7_domain.dart';

import '../../app_runtime_controller.dart';
import '../../app_runtime_models.dart';
import '../../../config/app_config.dart';
import 'dashboard_status_bar.dart';
import 'dashboard_toolbar.dart';
import 'current_lap_box.dart';
import 'dashboard_status_bar.dart';
import 'dashboard_toolbar.dart';
import 'dashboard_top_bar.dart';
import 'fuel_level_box.dart';
import 'fuel_stop_box.dart';
import 'lap_section.dart';
import 'remaining_race_box.dart';
import 'remaining_stops_box.dart';
import 'smartphone_dashboard.dart';
import 'strategy_section.dart';
import 'tyre_grid_tablet.dart';

class DashboardScreen extends StatefulWidget {
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
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _lastNotifiedPitLap;
  int? _lastNotifiedLapMessage;

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkPitStopAlert();
    _checkLapStartMessage();
  }

  void _checkPitStopAlert() {
    final currentLap = widget.race.currentLapNumber;
    final pitLap = widget.race.predictedStopLap;

    if (currentLap > 0 &&
        currentLap == pitLap &&
        _lastNotifiedPitLap != currentLap) {
      _lastNotifiedPitLap = currentLap;
      _showPitAlert();
    }
  }

  void _checkLapStartMessage() {
    final currentLap = widget.race.currentLapNumber;
    if (currentLap > 1 && _lastNotifiedLapMessage != currentLap) {
      _lastNotifiedLapMessage = currentLap;
      _showLapStartMessage();
    }
  }

  void _showLapStartMessage() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || widget.race.currentLapNumber != _lastNotifiedLapMessage) {
        return;
      }

      final raceType = widget.config.raceType;
      String message;
      if (raceType == RaceType.lapRace) {
        final remaining = widget.race.remainingLaps;
        message = '$remaining LAPS REMAINING';
      } else {
        final remaining = widget.race.remainingTime;
        if (remaining <= Duration.zero) {
          message = 'TIME EXPIRED';
        } else if (remaining.inMinutes >= 1) {
          message = '${remaining.inMinutes}m REMAINING';
        } else {
          message = '${remaining.inSeconds}s REMAINING';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Roboto Mono',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: const Color(0xFF1E88E5), // Bauhaus Blue
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.4,
            left: 50,
            right: 50,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
      );
    });
  }

  void _showPitAlert() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              'BOX THIS LAP',
              style: TextStyle(
                fontFamily: 'Roboto Mono',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: const Color(0xFFE63B2E), // Bauhaus Red
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.4,
            left: 50,
            right: 50,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showStatusBar = constraints.maxWidth >= 500;
        final isSmartphone = widget.config.viewMode == DashboardViewMode.smartphone;
        return Container(
          color: Colors.black,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // ROW 1 — header: logo + RPM display + LED bar
            SizedBox(
              height: 44,
              child: DashboardTopBar(config: widget.config, telemetry: widget.telemetry),
            ),
            // ROW 2 — main content (Expanded) — double-tap toggles view mode
            Expanded(
              child: GestureDetector(
                onDoubleTap: widget.onToggleViewMode,
                behavior: HitTestBehavior.opaque,
                child: widget.config.viewMode == DashboardViewMode.smartphone
                    ? SmartphoneDashboard(
                        race: widget.race,
                        telemetry: widget.telemetry,
                        config: widget.config,
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 20,
                            child: Column(
                              children: [
                                Expanded(
                                  child: CurrentLapBox(
                                    currentLap: widget.race.currentLapNumber,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Expanded(
                                  child: FuelLevelBox(
                                    fuelLevel: widget.telemetry.fuelLevel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            flex: 40,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 40, // 40% of the vertical space on the left
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: FuelStopBox(
                                          stopLap: widget.race.predictedStopLap,
                                          hasData: widget.race.predictedStints.isNotEmpty,
                                          raceType: widget.config.raceType,
                                          targetLaps: widget.config.targetLaps,
                                          predictedStints: widget.race.predictedStints,
                                          targetRaceTimeMs: widget.config.targetRaceTime.inMilliseconds.toDouble(),
                                          currentLap: widget.race.currentLapNumber,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: RemainingStopsBox(
                                          stops: (widget.race.predictedStints.length - 1).clamp(0, 999),
                                          hasData: widget.race.predictedStints.isNotEmpty,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Expanded(
                                  flex: 60, // 60% of the vertical space on the left
                                  child: LapSection(
                                    race: widget.race,
                                    connection: widget.connection,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5), // Spacing between left column and tyres
                          Expanded(
                            flex: 20,
                            child: TyreGridTablet(
                              telemetry: widget.telemetry,
                              config: widget.config,
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
                controller: widget.controller,
                connection: widget.connection,
              ),
            ),
            if (showStatusBar)
              DashboardStatusBar(telemetry: widget.telemetry, connection: widget.connection),
          ],
        ),
      );
      },
    );
  }
}
