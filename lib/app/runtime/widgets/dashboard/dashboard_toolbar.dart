import 'package:flutter/material.dart';

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
        ? const Color(0xFFCC0000)
        : phase == RuntimeConnectionPhase.connecting
        ? const Color(0xFFCC8800)
        : phase == RuntimeConnectionPhase.error
        ? const Color(0xFFCC4400)
        : const Color(0xFF333333);
    final simBtnLabel = isLive
        ? '■ STOP SIM'
        : phase == RuntimeConnectionPhase.connecting
        ? '⏳ CONNECTING'
        : phase == RuntimeConnectionPhase.error
        ? '⚠ RETRY'
        : '▶ START SIM';
    final simBtnBorder = isLive
        ? const Color(0xFFFF4444)
        : phase == RuntimeConnectionPhase.connecting
        ? const Color(0xFFFFBB33)
        : phase == RuntimeConnectionPhase.error
        ? const Color(0xFFFF4444)
        : const Color(0xFF555555);

    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // START SIM - main action button
          Flexible(
            fit: FlexFit.loose,
            child: Tooltip(
              message: telemetryControlTooltip(phase),
              child: AppButton(
                label: simBtnLabel,
                onPressed: isBusy ? null : controller.toggleTelemetry,
                backgroundColor: simBtnBg,
                foregroundColor: Colors.white,
                borderColor: simBtnBorder,
                compact: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // REPLAY
          Flexible(
            fit: FlexFit.loose,
            child: Tooltip(
              message: 'Reset session',
              child: AppButton(
                label: '▶ REPLAY',
                onPressed: controller.resetSession,
                compact: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // FIND PS
          Flexible(
            fit: FlexFit.loose,
            child: Tooltip(
              message: 'Change PlayStation',
              child: AppButton(
                label: '🎮 FIND PS',
                onPressed: controller.changePlaystation,
                compact: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // RELOAD
          Flexible(
            fit: FlexFit.loose,
            child: Tooltip(
              message: 'Reconnect',
              child: AppButton(
                label: '🔄 RELOAD',
                onPressed: isBusy ? null : controller.reconnect,
                compact: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // SETTINGS
          Flexible(
            fit: FlexFit.loose,
            child: Tooltip(
              message: 'Open settings',
              child: AppButton(
                label: '⚙ SETTINGS',
                onPressed: () => openSettingsScreen(context, controller),
                compact: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
