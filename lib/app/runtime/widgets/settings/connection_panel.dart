import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

import '../../app_runtime_controller.dart';
import '../../app_runtime_models.dart';
import '../../../config/app_config.dart';
import '../common/app_button.dart';
import '../common/metric_tile.dart';
import '../common/status_badge.dart';
import '../runtime_ui_utils.dart';

class ConnectionPanel extends StatefulWidget {
  const ConnectionPanel({
    super.key,
    required this.controller,
    required this.config,
    required this.telemetry,
    required this.connection,
  });

  final AppRuntimeController controller;
  final AppConfig config;
  final TelemetryViewState telemetry;
  final RuntimeConnectionState connection;

  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  late final TextEditingController _manualIpController;

  @override
  void initState() {
    super.initState();
    _manualIpController = TextEditingController(
      text: widget.config.normalizedManualPlaystationIp ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ConnectionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.config.normalizedManualPlaystationIp ?? '';
    final prevValue = oldWidget.config.normalizedManualPlaystationIp ?? '';
    if (nextValue != prevValue) {
      _manualIpController.text = nextValue;
    }
  }

  @override
  void dispose() {
    _manualIpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gt7 = context.gt7Theme;
    final address = widget.connection.playstationAddress?.address;

    return Gt7Panel(
      title: 'Connection settings',
      subtitle: widget.connection.headline,
      trailing: StatusBadge(
        label: widget.controller.isReplayMode
            ? 'REPLAY'
            : widget.connection.usingManualAddress
            ? 'MANUAL'
            : 'AUTO',
        color: widget.controller.isReplayMode
            ? gt7.warning
            : widget.connection.usingManualAddress
            ? gt7.userInput
            : gt7.highlight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.connection.detail != null)
            Text(
              widget.connection.detail!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: gt7.description),
            ),
          const SizedBox(height: Gt7Spacing.md),
          Wrap(
            spacing: Gt7Spacing.md,
            runSpacing: Gt7Spacing.md,
            children: [
              MetricTile(
                label: 'Endpoint',
                value:
                    address ??
                    (widget.connection.usingManualAddress
                        ? 'Manual target'
                        : 'Broadcast discovery'),
              ),
              MetricTile(
                label: 'Source',
                value: widget.connection.usingManualAddress
                    ? 'Manual IP'
                    : 'Discovery',
                tone: widget.connection.usingManualAddress
                    ? gt7.userInput
                    : gt7.highlight,
              ),
              MetricTile(
                label: 'Last packet',
                value: relativeTimestamp(widget.telemetry.lastPacketAt),
              ),
            ],
          ),
          const SizedBox(height: Gt7Spacing.lg),
          TextField(
            controller: _manualIpController,
            keyboardType: TextInputType.url,
            autofillHints: const <String>[AutofillHints.url],
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Manual PlayStation IP',
              hintText: '192.168.0.10',
            ),
          ),
          const SizedBox(height: Gt7Spacing.sm),
          Text(
            'Leave blank to keep auto discovery. Manual IP overrides discovery until cleared.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: gt7.description),
          ),
          const SizedBox(height: Gt7Spacing.md),
          Wrap(
            spacing: Gt7Spacing.sm,
            runSpacing: Gt7Spacing.sm,
            children: [
              AppButton(
                label: 'Apply manual IP',
                onPressed: _applyManualIp,
              ),
              AppButton(label: 'Auto discovery', onPressed: _clearManualIp),
              AppButton(
                label: 'Reconnect',
                onPressed: widget.controller.reconnect,
              ),
              AppButton(
                label: 'Change PlayStation',
                onPressed: _changePlaystation,
              ),
            ],
          ),
          if (widget.telemetry.errorMessage != null) ...[
            const SizedBox(height: Gt7Spacing.md),
            Text(
              widget.telemetry.errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _applyManualIp() async {
    final value = _manualIpController.text.trim();
    if (value.isEmpty) {
      await _clearManualIp();
      return;
    }

    if (InternetAddress.tryParse(value) == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid IPv4 or IPv6 address.')),
      );
      return;
    }

    await widget.controller.updateConfig(
      widget.config.copyWith(manualPlaystationIp: value),
    );
  }

  Future<void> _clearManualIp() async {
    _manualIpController.clear();
    await widget.controller.updateConfig(
      widget.config.copyWith(clearManualPlaystationIp: true),
    );
  }

  Future<void> _changePlaystation() async {
    await widget.controller.changePlaystation();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}
