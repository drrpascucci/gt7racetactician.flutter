import 'package:flutter/material.dart';

import '../../app_runtime_models.dart';
import '../runtime_ui_utils.dart';

class DashboardStatusBar extends StatelessWidget {
  const DashboardStatusBar({
    super.key,
    required this.telemetry,
    required this.connection,
  });

  final TelemetryViewState telemetry;
  final RuntimeConnectionState connection;

  @override
  Widget build(BuildContext context) {
    final phase = connection.phase;
    final statusText = switch (phase) {
      RuntimeConnectionPhase.live => 'Live',
      RuntimeConnectionPhase.connecting => 'Connecting',
      RuntimeConnectionPhase.error => 'Error',
      RuntimeConnectionPhase.stopped => 'Stopped',
      RuntimeConnectionPhase.paused => 'Paused',
      _ => 'Not Active',
    };

    return Container(
      height: 30,
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text(
            'Pkt: ${telemetry.packet?.packetId ?? 0}  |',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            'IP: ${connection.playstationAddress?.address ?? "--"}',
            style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 12),
          ),
          const SizedBox(width: 4),
          const Text(
            '|  Status:',
            style: TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
          const SizedBox(width: 2),
          Text(
            statusText,
            style: TextStyle(
              color: connectionColor(context, phase),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
