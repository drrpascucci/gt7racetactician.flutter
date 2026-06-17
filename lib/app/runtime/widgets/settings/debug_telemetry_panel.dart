import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

import '../../app_runtime_controller.dart';
import '../../../config/app_config.dart';
import '../common/app_button.dart';
import '../common/metric_tile.dart';
import '../common/status_badge.dart';

class DebugTelemetryPanel extends StatelessWidget {
  const DebugTelemetryPanel({super.key, required this.controller, required this.config});

  final AppRuntimeController controller;
  final AppConfig config;

  String _formatSpeedLabel(double value) {
    return value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final speedOptions = <double>[1, 2, 5, 10, 20];
    final selectedSpeed = speedOptions.contains(config.replaySpeedMultiplier)
        ? config.replaySpeedMultiplier
        : 1.0;

    return Gt7Panel(
      title: 'Debug telemetry',
      subtitle: controller.isReplayMode
          ? 'Replay is active at x${_formatSpeedLabel(controller.activeReplaySpeedMultiplier)}.'
          : 'Capture raw UDP packets and replay the latest log.',
      trailing: StatusBadge(
        label: controller.isReplayMode
            ? 'REPLAY'
            : controller.activeLogFilePath != null
            ? 'LOGGING'
            : 'DEBUG',
        color: controller.isReplayMode
            ? context.gt7Theme.warning
            : controller.activeLogFilePath != null
            ? context.gt7Theme.userInput
            : context.gt7Theme.highlight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raw telemetry logging',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: Gt7Spacing.xs),
                    Text(
                      'Write every UDP packet to a .gt7log file for later replay.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.gt7Theme.description,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gt7Spacing.md),
              Switch.adaptive(
                value: config.rawLoggingEnabled,
                onChanged: (value) async {
                  await controller.updateConfig(
                    config.copyWith(rawLoggingEnabled: value),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: Gt7Spacing.md),
          Wrap(
            spacing: Gt7Spacing.md,
            runSpacing: Gt7Spacing.md,
            children: [
              FutureBuilder<String?>(
                future: controller.getTelemetryLogsDirectoryPath(),
                builder: (context, snapshot) => MetricTile(
                  label: 'Logs directory',
                  value: snapshot.data ?? 'Unavailable',
                ),
              ),
              MetricTile(
                label: 'Active log file',
                value: controller.activeLogFilePath ?? 'Idle',
              ),
              FutureBuilder<String?>(
                future: controller.findLatestReplayLogFilePath(),
                builder: (context, snapshot) => MetricTile(
                  label: 'Latest replay log',
                  value:
                      controller.lastReplayLogFilePath ??
                      snapshot.data ??
                      'No session recorded',
                ),
              ),
            ],
          ),
          const SizedBox(height: Gt7Spacing.md),
          DropdownButtonFormField<double>(
            key: ValueKey<double>(selectedSpeed),
            value: selectedSpeed,
            dropdownColor: Colors.black,
            decoration: const InputDecoration(
              labelText: 'Replay speed',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            items: speedOptions
                .map(
                  (value) => DropdownMenuItem<double>(
                    value: value,
                    child: Text('x${_formatSpeedLabel(value)}'),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) async {
              if (value == null) {
                return;
              }
              await controller.updateConfig(
                config.copyWith(replaySpeedMultiplier: value),
              );
            },
          ),
          const SizedBox(height: Gt7Spacing.md),
          Wrap(
            spacing: Gt7Spacing.md,
            runSpacing: Gt7Spacing.md,
            children: [
              AppButton(
                onPressed: () async {
                  await controller.startReplay(
                    speedMultiplier: config.replaySpeedMultiplier,
                  );
                },
                label: 'Replay last session',
              ),
              if (controller.isReplayMode)
                TextButton(
                  onPressed: controller.stopReplay,
                  child: const Text('Stop replay'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
