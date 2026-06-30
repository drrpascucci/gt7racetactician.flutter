import 'dart:io';

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

Future<void> confirmExit(BuildContext context) async {
  final shouldExit = await showDialog<bool>(
    context: context,
    builder: (context) => Gt7DialogFrame(
      title: 'Confirm',
      child: const Text(
        'Are you sure you want to close GT7 Race Tactictian?',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton(
                label: 'CANCEL',
                onPressed: () => Navigator.of(context).pop(false),
                backgroundColor: Gt7Colors.cancel,
                foregroundColor: Colors.white,
                compact: true,
              ),
              const SizedBox(width: 10),
              AppButton(
                label: 'EXIT',
                onPressed: () => Navigator.of(context).pop(true),
                backgroundColor: Gt7Colors.negative,
                foregroundColor: Colors.white,
                borderColor: Gt7Colors.danger,
                compact: true,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  if (shouldExit == true) {
    exit(0);
  }
}

class DashboardToolbar extends StatelessWidget {
  const DashboardToolbar({super.key, required this.controller, required this.connection});

  final AppRuntimeController controller;
  final RuntimeConnectionState connection;

  @override
  Widget build(BuildContext context) {
    final phase = connection.phase;
    final isBusy = connection.isBusy;

    final (simBtnBg, simBtnLabel, simBtnBorder) = switch (phase) {
      RuntimeConnectionPhase.live => (
          const Color(0xFF333333),
          'STOP',
          const Color(0xFFFF4444),
        ),
      RuntimeConnectionPhase.connecting => (
          const Color(0xFFCC8800),
          'CONNECTING',
          const Color(0xFFFFBB33),
        ),
      RuntimeConnectionPhase.error => (
          const Color(0xFFCC4400),
          'RETRY',
          const Color(0xFFFF4444),
        ),
      _ => (
          Gt7Colors.ok,
          'START',
          const Color(0xFF555555),
        ),
    };

    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          // EXIT button aligned to the far left
          AppButton(
            label: "EXIT",
            backgroundColor: const Color(0xFFCC0000),
            foregroundColor: Colors.white,
            borderColor: const Color(0xFFFF4444),
            onPressed: () => confirmExit(context),
          ),
          // Fill all space between EXIT and other buttons
          const Spacer(),
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
          // START/STOP main action button
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
