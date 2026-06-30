import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

import 'app_runtime_controller.dart';
import '../config/app_config.dart';
import 'widgets/dashboard/dashboard_screen.dart';
import 'widgets/discovery/discovery_stage.dart';

class RuntimeShell extends StatelessWidget {
  const RuntimeShell({super.key, required this.controller});

  final AppRuntimeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, controller.configService]),
      builder: (context, _) {
        if (!controller.hasSelectedPlaystation) {
          return Scaffold(
            backgroundColor: const Color(0xFF111111),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: Gt7Spacing.screenInsets,
                  child: DiscoveryStage(
                    controller: controller,
                    config: controller.configService.config,
                    connection: controller.connectionState,
                    telemetry: controller.telemetryState.value,
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                controller,
                controller.configService,
                controller.telemetryState,
                controller.raceState,
              ]),
            builder: (context, _) {
              final config = controller.configService.config;
              return DashboardScreen(
                controller: controller,
                config: config,
                telemetry: controller.telemetryState.value,
                connection: controller.connectionState,
                race: controller.raceState.value,
                onToggleViewMode: () {
                  final current = controller.configService.config;
                  final next = current.viewMode == DashboardViewMode.tablet
                      ? DashboardViewMode.smartphone
                      : DashboardViewMode.tablet;
                  controller.updateConfig(current.copyWith(viewMode: next));
                },
              );
            },
            ),
          ),
        );
      },
    );
  }
}
