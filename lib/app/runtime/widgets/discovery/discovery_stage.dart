import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

import '../../app_runtime_controller.dart';
import '../../app_runtime_models.dart';
import '../../../config/app_config.dart';
import '../common/app_button.dart';

class DiscoveryStage extends StatefulWidget {
  const DiscoveryStage({
    super.key,
    required this.controller,
    required this.config,
    required this.connection,
    required this.telemetry,
  });

  final AppRuntimeController controller;
  final AppConfig config;
  final RuntimeConnectionState connection;
  final TelemetryViewState telemetry;

  @override
  State<DiscoveryStage> createState() => _DiscoveryStageState();
}

class _DiscoveryStageState extends State<DiscoveryStage> {
  late final TextEditingController _manualIpController;

  @override
  void initState() {
    super.initState();
    _manualIpController = TextEditingController(
      text: widget.config.normalizedManualPlaystationIp ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant DiscoveryStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.config.normalizedManualPlaystationIp ?? '';
    if (_manualIpController.text != nextValue) {
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

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Enter IP or search for PlayStation',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: gt7.highlight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(height: Gt7Spacing.xl),
          Text(
            'Enter PlayStation IP Address:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: gt7.telemetry,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: Gt7Spacing.md),
          SizedBox(
            width: 240,
            child: TextField(
              controller: _manualIpController,
              keyboardType: TextInputType.url,
              autofillHints: const <String>[AutofillHints.url],
              autocorrect: false,
              enableSuggestions: false,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'RobotoMono',
              ),
              cursorColor: Colors.black,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Gt7Spacing.md,
                  vertical: Gt7Spacing.sm,
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide.none,
                ),
                hintText: '192.168.1.9',
                hintStyle: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(height: Gt7Spacing.lg),
          AppButton(
            label: widget.connection.phase == RuntimeConnectionPhase.discovering
                ? 'SEARCHING...'
                : 'SEARCH PS',
            onPressed: widget.connection.isBusy
                ? null
                : widget.controller.discoverPlaystation,
          ),
          const SizedBox(height: Gt7Spacing.xl),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Gt7Spacing.md,
            runSpacing: Gt7Spacing.sm,
            children: [
              AppButton(
                label: 'EXIT',
                onPressed: () => exit(0),
                backgroundColor: const Color(0xFFCC0000),
                foregroundColor: Colors.white,
                borderColor: const Color(0xFFFF4444),
              ),
              AppButton(
                  label: "LET'S RACE!",
                onPressed: widget.connection.isBusy ? null : _applyManualIp,
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
                borderColor: const Color(0xFF4CAF50),
              ),
            ],
          ),
          if (widget.telemetry.errorMessage != null ||
              widget.connection.phase == RuntimeConnectionPhase.error) ...[
            const SizedBox(height: Gt7Spacing.lg),
            Text(
              widget.telemetry.errorMessage ?? widget.connection.detail ?? '',
              textAlign: TextAlign.center,
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid IP or use discovery.')),
      );
      return;
    }
    await widget.controller.selectManualPlaystation(value);
  }
}
