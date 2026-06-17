import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

import '../../app_runtime_controller.dart';
import '../common/app_button.dart';
import 'connection_panel.dart';
import 'debug_telemetry_panel.dart';
import 'race_settings_panel.dart';

class RuntimeSettingsScreen extends StatefulWidget {
  const RuntimeSettingsScreen({super.key, required this.controller});

  final AppRuntimeController controller;

  @override
  State<RuntimeSettingsScreen> createState() => _RuntimeSettingsScreenState();
}

class _RuntimeSettingsScreenState extends State<RuntimeSettingsScreen> {
  final _raceSettingsKey = GlobalKey<RaceSettingsPanelState>();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller,
        widget.controller.configService,
        widget.controller.telemetryState,
      ]),
      builder: (context, _) {
        final config = widget.controller.configService.config;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'GT7 Race Tactician Settings',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SafeArea(
            child: Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.apply(
                      bodyColor: Colors.white,
                      displayColor: Colors.white,
                    ),
              ),
              child: ListView(
              padding: Gt7Spacing.screenInsets,
              children: [
                Text(
                  'GT7 RACE TACTICIAN SETTINGS',
                  style: TextStyle(
                    color: context.gt7Theme.highlight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: Gt7Spacing.lg),
                RaceSettingsPanel(
                  key: _raceSettingsKey,
                  initialConfig: config,
                  onSave: widget.controller.updateConfig,
                ),
                const SizedBox(height: Gt7Spacing.lg),
                ConnectionPanel(
                  controller: widget.controller,
                  config: config,
                  telemetry: widget.controller.telemetryState.value,
                  connection: widget.controller.connectionState,
                ),
                const SizedBox(height: Gt7Spacing.lg),
                DebugTelemetryPanel(controller: widget.controller, config: config),
                const SizedBox(height: Gt7Spacing.xl),
                Align(
                  alignment: Alignment.center,
                  child: AppButton(
                    label: 'Apply & Close',
                    onPressed: () async {
                      await _raceSettingsKey.currentState?.save();
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    backgroundColor: const Color(0xFF388E3C),
                    foregroundColor: Colors.white,
                    borderColor: Gt7Colors.border,
                  ),
                ),
                const SizedBox(height: Gt7Spacing.xl * 2),
              ],
            ),
          ),
        );
      },
    );
  }
}
