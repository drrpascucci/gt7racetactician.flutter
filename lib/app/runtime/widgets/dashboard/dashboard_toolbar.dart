import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

import '../../app_runtime_controller.dart';
import '../../app_runtime_models.dart';
import '../common/app_button.dart';
import '../runtime_ui_utils.dart';
import '../settings/runtime_settings_screen.dart';

Future<void> openSettingsScreen(
  BuildContext context,
  AppRuntimeController controller,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: false,
      builder: (context) => RuntimeSettingsScreen(controller: controller),
    ),
  );
}

class DashboardToolbar extends StatelessWidget {
  const DashboardToolbar({super.key, required this.controller, required this.connection});

  final AppRuntimeController controller;
  final RuntimeConnectionState connection;

  @override
  Widget build(BuildContext context) {
    final phase = connection.phase;
    final isLive = phase == RuntimeConnectionPhase.live;
    final isBusy = connection.isBusy;

    final simBtnBg = isLive
        ? const Color(0xFF333333)
        : phase == RuntimeConnectionPhase.connecting
        ? const Color(0xFFCC8800)
        : phase == RuntimeConnectionPhase.error
        ? const Color(0xFFCC4400)
        : Gt7Colors.ok;
    final simBtnLabel = isLive
        ? 'STOP'
        : phase == RuntimeConnectionPhase.connecting
        ? 'CONNECTING'
        : phase == RuntimeConnectionPhase.error
        ? 'RETRY'
        : 'START';
    final simBtnBorder = isLive
        ? const Color(0xFFFF4444)
        : phase == RuntimeConnectionPhase.connecting
        ? const Color(0xFFFFBB33)
        : phase == RuntimeConnectionPhase.error
        ? const Color(0xFFFF4444)
        : const Color(0xFF555555);

    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // SETTINGS
          Tooltip(
            message: 'Open settings',
            child: AppButton(
              label: 'SETTINGS',
              foregroundColor: Colors.white,
              onPressed: () => openSettingsScreen(context, controller),
            ),
          ),
          const SizedBox(width: 10),
          // START - main action button
          Tooltip(
            message: telemetryControlTooltip(phase),
            child: AppButton(
              label: simBtnLabel,
              onPressed: isBusy ? null : controller.toggleTelemetry,
              backgroundColor: simBtnBg,
              foregroundColor: Colors.white,
              borderColor: simBtnBorder,
            ),
          ),
        ],
      ),
    );
  }
}
