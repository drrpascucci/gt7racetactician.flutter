import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';
import 'package:gt7_domain/gt7_domain.dart';

import '../config/app_config.dart';
import 'app_runtime_controller.dart';
import 'app_runtime_models.dart';

Future<void> _openSettingsScreen(
  BuildContext context,
  AppRuntimeController controller,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => _RuntimeSettingsScreen(controller: controller),
    ),
  );
}

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
                  child: _DiscoveryStage(
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
              builder: (context, _) => _DashboardScreen(
                controller: controller,
                config: controller.configService.config,
                telemetry: controller.telemetryState.value,
                connection: controller.connectionState,
                race: controller.raceState.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DiscoveryStage extends StatefulWidget {
  const _DiscoveryStage({
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
  State<_DiscoveryStage> createState() => _DiscoveryStageState();
}

class _DiscoveryStageState extends State<_DiscoveryStage> {
  late final TextEditingController _manualIpController;

  @override
  void initState() {
    super.initState();
    _manualIpController = TextEditingController(
      text: widget.config.normalizedManualPlaystationIp ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _DiscoveryStage oldWidget) {
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
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none,
                ),
                hintText: '192.168.1.9',
                hintStyle: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(height: Gt7Spacing.lg),
          Gt7PillButton(
            label: widget.connection.phase == RuntimeConnectionPhase.discovering
                ? 'Searching...'
                : 'Search PS',
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
              Gt7PillButton(
                label: "Let's GO!",
                onPressed: widget.connection.isBusy ? null : _applyManualIp,
              ),
              Gt7PillButton(
                label: 'Exit',
                variant: Gt7ButtonVariant.danger,
                onPressed: () => exit(0),
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

class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen({
    required this.controller,
    required this.config,
    required this.telemetry,
    required this.connection,
    required this.race,
  });

  final AppRuntimeController controller;
  final AppConfig config;
  final TelemetryViewState telemetry;
  final RuntimeConnectionState connection;
  final RaceViewState race;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showStatusBar = constraints.maxWidth >= 500;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ROW 1 — header: logo + RPM display + LED bar
            SizedBox(
              height: 44,
              child: _DashboardTopBar(config: config, telemetry: telemetry),
            ),
            // ROW 1b — strategy banner (full width)
            _StrategySection(race: race),
            Container(height: 1, color: const Color(0xFF333333)),
            // ROW 2 — main content (Expanded)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT: lap table (~80%)
                  Expanded(flex: 80, child: _LapSection(race: race)),
                  Container(width: 1, color: const Color(0xFF333333)),
                  // RIGHT: tyre temps (~20%)
                  Expanded(flex: 20, child: _TyreSection(telemetry: telemetry)),
                ],
              ),
            ),
            // ROW 3 — button toolbar
            SizedBox(
              height: 44,
              child: _DashboardToolbar(
                controller: controller,
                connection: connection,
              ),
            ),
            if (showStatusBar)
              _DashboardStatusBar(telemetry: telemetry, connection: connection),
          ],
        );
      },
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({required this.config, required this.telemetry});

  final AppConfig config;
  final TelemetryViewState telemetry;

  @override
  Widget build(BuildContext context) {
    final rpm = telemetry.engineRpm;
    final rpmLimit = config.shiftRpm > 0
        ? config.shiftRpm.toDouble()
        : (telemetry.packet?.maxAlertRpm.toDouble() ?? 7800);
    final rpmFraction = rpmLimit > 0 ? (rpm / rpmLimit).clamp(0.0, 1.0) : 0.0;

    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo area
          SizedBox(
            width: 80,
            child: Text(
              'GT7 Race Tactician',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFFE60000),
                fontSize: 8,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // RPM display: value text + thin progress bar
          SizedBox(
            width: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rpm.toStringAsFixed(0)} RPM',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 14,
                    fontFamily: 'RobotoMono',
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(
                    value: rpmFraction,
                    backgroundColor: const Color(0xFF222222),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00E676),
                    ),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Gear LED bar — fills remaining space
          Expanded(
            child: Gt7RpmLedBar(rpm: rpm, limit: rpmLimit, compact: true),
          ),
        ],
      ),
    );
  }
}

class _DashboardToolbar extends StatelessWidget {
  const _DashboardToolbar({required this.controller, required this.connection});

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactToolbar = constraints.maxWidth < 320;

        return Container(
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _ToolbarIconButton(
                icon: Icons.settings,
                tooltip: 'Open settings',
                onPressed: () => _openSettingsScreen(context, controller),
              ),
              const SizedBox(width: 4),
              _ToolbarIconButton(
                icon: Icons.refresh,
                tooltip: 'Reconnect',
                onPressed: isBusy ? null : controller.reconnect,
              ),
              SizedBox(width: compactToolbar ? 4 : 6),
              Flexible(
                fit: FlexFit.loose,
                child: Tooltip(
                  message: _telemetryControlTooltip(phase),
                  child: ElevatedButton(
                    onPressed: isBusy ? null : controller.toggleTelemetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: simBtnBg,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: compactToolbar ? 8 : 10,
                      ),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(
                          color: isLive
                              ? const Color(0xFFFF4444)
                              : const Color(0xFF555555),
                        ),
                      ),
                      textStyle: TextStyle(
                        fontSize: compactToolbar ? 9 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(simBtnLabel, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
              SizedBox(width: compactToolbar ? 4 : 6),
              if (compactToolbar)
                _ToolbarIconButton(
                  icon: Icons.replay,
                  tooltip: 'Reset session',
                  onPressed: controller.resetSession,
                )
              else
                Flexible(
                  fit: FlexFit.loose,
                  child: Tooltip(
                    message: 'Reset session',
                    child: TextButton(
                      onPressed: controller.resetSession,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFAAAAAA),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: Color(0xFF555555)),
                        ),
                        textStyle: const TextStyle(fontSize: 10),
                      ),
                      child: const Text(
                        '▶ REPLAY',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              _ToolbarIconButton(
                icon: Icons.sports_esports,
                tooltip: 'Change PlayStation',
                onPressed: controller.changePlaystation,
              ),
              if (!compactToolbar) const Spacer(),
            ],
          ),
        );
      },
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            icon,
            size: 16,
            color: onPressed != null
                ? const Color(0xFFAAAAAA)
                : const Color(0xFF555555),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _StrategySection extends StatelessWidget {
  const _StrategySection({required this.race});

  final RaceViewState race;

  @override
  Widget build(BuildContext context) {
    final config = race.config;
    final raceLength = config.raceType == RaceType.timeRace
        ? '${config.targetRaceTime.inMinutes} min'
        : '${config.targetLaps} laps';
    final avgTargetMs = config.targetLaps <= 0
        ? 0.0
        : config.targetRaceTime.inMilliseconds / config.targetLaps;
    final bannerText = race.predictedStopLap <= 0
        ? 'GO TO THE END'
        : 'PIT LAP ${race.predictedStopLap}';
    final targetLabel = _formatDurationMs(
      config.targetRaceTime.inMilliseconds.toDouble(),
    );
    final avgLabel = _formatDurationMs(avgTargetMs);

    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF282828),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: const Text(
              'DRIVER ASSIST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 13,
                  color: const Color(0xFF222222),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'Strategy',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 7,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        color: const Color(0xFF1A1A1A),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        child: Text(
                          bannerText,
                          style: const TextStyle(
                            color: Color(0xFFFFB300),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Length: $raceLength',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Target: $targetLabel',
                                style: const TextStyle(
                                  color: Color(0xFF64B5F6),
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Avg: $avgLabel',
                                style: const TextStyle(
                                  color: Color(0xFFFFB300),
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LapSection extends StatelessWidget {
  const _LapSection({required this.race});

  final RaceViewState race;

  @override
  Widget build(BuildContext context) {
    final raceDeltaByLap = _raceDeltaByLap(race);
    const layout = _LapTableLayout();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 13,
          color: const Color(0xFF222222),
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              'Last laps',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 7),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const rowH = 24.0;
              final maxRows =
                  (constraints.maxHeight / rowH).floor().clamp(2, 12) - 1;
              final laps = race.laps
                  .where((l) => l.lapNumber > 0)
                  .toList()
                  .reversed
                  .take(maxRows)
                  .toList();

              return ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  maxHeight: double.infinity,
                  child: Table(
                    columnWidths: layout.columnWidths,
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder.symmetric(
                      inside: const BorderSide(
                        color: Color(0xFF333333),
                        width: 0.5,
                      ),
                    ),
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C2C2C),
                        ),
                        children: [
                          for (var i = 0; i < layout.headers.length; i++)
                            _LapTableHeaderCell(
                              layout.headers[i],
                              compact: true,
                              color: i == 3
                                  ? const Color(0xFFFFB300)
                                  : i == 4
                                  ? const Color(0xFF64B5F6)
                                  : null,
                            ),
                        ],
                      ),
                      for (var index = 0; index < laps.length; index++)
                        TableRow(
                          decoration: BoxDecoration(
                            color: !laps[index].complete
                                ? const Color(0xFF1A3A5C)
                                : index.isEven
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFF212121),
                          ),
                          children: _buildLapTableCells(
                            context: context,
                            lap: laps[index],
                            layout: layout,
                            raceDeltaMs:
                                raceDeltaByLap[laps[index].lapNumber] ?? 0,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TyreSection extends StatelessWidget {
  const _TyreSection({required this.telemetry});

  final TelemetryViewState telemetry;

  @override
  Widget build(BuildContext context) {
    final temps = telemetry.tireTemperatures;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TyreTile(label: 'FL', temp: temps.frontLeft),
              ),
              Container(width: 1, color: const Color(0xFF333333)),
              Expanded(
                child: _TyreTile(label: 'FR', temp: temps.frontRight),
              ),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFF333333)),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TyreTile(label: 'RL', temp: temps.rearLeft),
              ),
              Container(width: 1, color: const Color(0xFF333333)),
              Expanded(
                child: _TyreTile(label: 'RR', temp: temps.rearRight),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TyreTile extends StatelessWidget {
  const _TyreTile({required this.label, required this.temp});

  final String label;
  final double temp;

  @override
  Widget build(BuildContext context) {
    final tone = _tyreTone(context, temp);
    return Container(
      color: const Color(0xFF222222),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 6,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Text(
              _temperatureLabel(temp),
              style: TextStyle(
                color: tone,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatusBar extends StatelessWidget {
  const _DashboardStatusBar({
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
      height: 22,
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text(
            'Pkt: ${telemetry.packet?.packetId ?? 0}  |',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 9),
          ),
          const SizedBox(width: 4),
          Text(
            'IP: ${connection.playstationAddress?.address ?? "--"}',
            style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 9),
          ),
          const SizedBox(width: 4),
          const Text(
            '|  Status:',
            style: TextStyle(color: Color(0xFF888888), fontSize: 9),
          ),
          const SizedBox(width: 2),
          Text(
            statusText,
            style: TextStyle(
              color: _connectionColor(context, phase),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPanel extends StatefulWidget {
  const _ConnectionPanel({
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
  State<_ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<_ConnectionPanel> {
  late final TextEditingController _manualIpController;

  @override
  void initState() {
    super.initState();
    _manualIpController = TextEditingController(
      text: widget.config.normalizedManualPlaystationIp ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _ConnectionPanel oldWidget) {
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
    final address = widget.connection.playstationAddress?.address;

    return Gt7Panel(
      title: 'Connection settings',
      subtitle: widget.connection.headline,
      trailing: _StatusBadge(
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
              _MetricTile(
                label: 'Endpoint',
                value:
                    address ??
                    (widget.connection.usingManualAddress
                        ? 'Manual target'
                        : 'Broadcast discovery'),
              ),
              _MetricTile(
                label: 'Source',
                value: widget.connection.usingManualAddress
                    ? 'Manual IP'
                    : 'Discovery',
                tone: widget.connection.usingManualAddress
                    ? gt7.userInput
                    : gt7.highlight,
              ),
              _MetricTile(
                label: 'Last packet',
                value: _relativeTimestamp(widget.telemetry.lastPacketAt),
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
              Gt7PillButton(
                label: 'Apply manual IP',
                onPressed: _applyManualIp,
                variant: Gt7ButtonVariant.secondary,
              ),
              Gt7PillButton(label: 'Auto discovery', onPressed: _clearManualIp),
              Gt7PillButton(
                label: 'Reconnect',
                onPressed: widget.controller.reconnect,
              ),
              Gt7PillButton(
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

class _LapTableLayout {
  const _LapTableLayout();

  bool get compact => true;

  List<String> get headers => const [
    'Lap',
    'Pos',
    'Time',
    'Avg Δ',
    'Race Δ',
    'Fuel',
  ];

  Map<int, TableColumnWidth> get columnWidths => const {
    0: FixedColumnWidth(34),
    1: FixedColumnWidth(38),
    2: FlexColumnWidth(2.4),
    3: FlexColumnWidth(1.8),
    4: FlexColumnWidth(2.0),
    5: FlexColumnWidth(1.8),
  };
}

List<Widget> _buildLapTableCells({
  required BuildContext context,
  required RaceLap lap,
  required _LapTableLayout layout,
  required double raceDeltaMs,
}) {
  final gt7 = context.gt7Theme;
  final lapLabel = !lap.complete ? '${lap.lapNumber}*' : '${lap.lapNumber}';
  final lapTone = !lap.complete ? gt7.highlight : null;
  final averageDeltaValue = _formatAdaptiveSignedDurationMs(
    lap.deltaFromTargetMs,
    compact: layout.compact,
  );
  final averageDeltaTone = _deltaTone(context, lap.deltaFromTargetMs);
  final raceDeltaValue = _formatAdaptiveSignedDurationMs(
    raceDeltaMs,
    compact: layout.compact,
  );
  final raceDeltaTone = _deltaTone(context, raceDeltaMs);
  final compactCells = layout.compact;

  return [
    _LapTableValueCell(lapLabel, color: lapTone, compact: compactCells),
    _LapTableValueCell(
      lap.position <= 0 ? '--' : '${lap.position}',
      compact: compactCells,
    ),
    _LapTableValueCell(
      lap.lapTimeMs > 0 ? _formatDurationMs(lap.lapTimeMs.toDouble()) : '--',
      color: !lap.complete ? gt7.highlight : null,
      compact: compactCells,
    ),
    _LapTableValueCell(
      averageDeltaValue,
      color: averageDeltaTone,
      compact: compactCells,
    ),
    _LapTableValueCell(
      raceDeltaValue,
      color: raceDeltaTone,
      compact: compactCells,
    ),
    _LapTableValueCell(
      lap.fuel <= 0 ? '--' : lap.fuel.toStringAsFixed(0),
      compact: compactCells,
    ),
  ];
}

class _LapTableHeaderCell extends StatelessWidget {
  const _LapTableHeaderCell(this.label, {this.compact = false, this.color});

  final String label;
  final bool compact;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final gt7 = context.gt7Theme;

    return ColoredBox(
      color: gt7.panel,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gt7Spacing.xs,
          vertical: Gt7Spacing.xs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Gt7Typography.tableHeader(
            color ?? gt7.description,
          ).copyWith(fontSize: 11),
        ),
      ),
    );
  }
}

class _LapTableValueCell extends StatelessWidget {
  const _LapTableValueCell(this.value, {this.color, this.compact = false});

  final String value;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gt7 = context.gt7Theme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Gt7Spacing.xs : Gt7Spacing.sm,
        vertical: compact ? Gt7Spacing.xs : Gt7Spacing.sm,
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Gt7Typography.tableCell(
          color ?? gt7.telemetry,
        ).copyWith(fontSize: compact ? 12 : 13),
      ),
    );
  }
}

class _RuntimeSettingsScreen extends StatelessWidget {
  const _RuntimeSettingsScreen({required this.controller});

  final AppRuntimeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller,
        controller.configService,
        controller.telemetryState,
      ]),
      builder: (context, _) {
        final config = controller.configService.config;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: SafeArea(
            child: ListView(
              padding: Gt7Spacing.screenInsets,
              children: [
                _SettingsOverviewPanel(
                  config: config,
                  connection: controller.connectionState,
                  telemetry: controller.telemetryState.value,
                ),
                const SizedBox(height: Gt7Spacing.lg),
                _RaceSettingsPanel(
                  initialConfig: config,
                  onSave: controller.updateConfig,
                ),
                const SizedBox(height: Gt7Spacing.lg),
                _ConnectionPanel(
                  controller: controller,
                  config: config,
                  telemetry: controller.telemetryState.value,
                  connection: controller.connectionState,
                ),
                const SizedBox(height: Gt7Spacing.lg),
                _DebugTelemetryPanel(controller: controller, config: config),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DebugTelemetryPanel extends StatelessWidget {
  const _DebugTelemetryPanel({required this.controller, required this.config});

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
      trailing: _StatusBadge(
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
                builder: (context, snapshot) => _MetricTile(
                  label: 'Logs directory',
                  value: snapshot.data ?? 'Unavailable',
                ),
              ),
              _MetricTile(
                label: 'Active log file',
                value: controller.activeLogFilePath ?? 'Idle',
              ),
              FutureBuilder<String?>(
                future: controller.findLatestReplayLogFilePath(),
                builder: (context, snapshot) => _MetricTile(
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
            initialValue: selectedSpeed,
            decoration: const InputDecoration(labelText: 'Replay speed'),
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
              ElevatedButton(
                onPressed: () async {
                  await controller.startReplay(
                    speedMultiplier: config.replaySpeedMultiplier,
                  );
                },
                child: const Text('Replay last session'),
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

class _SettingsOverviewPanel extends StatelessWidget {
  const _SettingsOverviewPanel({
    required this.config,
    required this.connection,
    required this.telemetry,
  });

  final AppConfig config;
  final RuntimeConnectionState connection;
  final TelemetryViewState telemetry;

  @override
  Widget build(BuildContext context) {
    return Gt7Panel(
      title: 'Session setup',
      subtitle:
          'Race targets, shift point, connection preferences and debug tools live here.',
      trailing: _StatusBadge(
        label: connection.phase.name.toUpperCase(),
        color: _connectionColor(context, connection.phase),
      ),
      child: Wrap(
        spacing: Gt7Spacing.md,
        runSpacing: Gt7Spacing.md,
        children: [
          _MetricTile(label: 'Track', value: config.trackName),
          _MetricTile(
            label: 'Race type',
            value: _raceTypeLabel(config.raceType),
          ),
          _MetricTile(
            label: 'Target',
            value: config.raceType == RaceType.timeRace
                ? '${config.targetRaceTime.inMinutes} min'
                : '${config.targetLaps} laps',
          ),
          _MetricTile(label: 'Shift RPM', value: '${config.shiftRpm}'),
          _MetricTile(
            label: 'Manual IP',
            value: config.normalizedManualPlaystationIp ?? 'Auto discovery',
          ),
          _MetricTile(
            label: 'Packets',
            value: '${telemetry.packetsReceived}',
            tone: telemetry.packetsReceived > 0
                ? context.gt7Theme.telemetry
                : context.gt7Theme.description,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final gt7 = context.gt7Theme;

    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.all(Gt7Spacing.md),
      decoration: BoxDecoration(
        color: gt7.panelAlt,
        borderRadius: BorderRadius.circular(Gt7Spacing.radiusMedium),
        border: Border.all(color: gt7.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: gt7.description),
          ),
          const SizedBox(height: Gt7Spacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: tone ?? gt7.telemetry),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Gt7Spacing.radiusPill),
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gt7Spacing.sm,
          vertical: Gt7Spacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _RaceSettingsPanel extends StatefulWidget {
  const _RaceSettingsPanel({required this.initialConfig, required this.onSave});

  final AppConfig initialConfig;
  final Future<void> Function(AppConfig config) onSave;

  @override
  State<_RaceSettingsPanel> createState() => _RaceSettingsPanelState();
}

class _RaceSettingsPanelState extends State<_RaceSettingsPanel> {
  late final TextEditingController _trackController;
  late final TextEditingController _lapsController;
  late final TextEditingController _minutesController;
  late final TextEditingController _pitLaneController;
  late final TextEditingController _shiftRpmController;
  late RaceType _raceType;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    _trackController = TextEditingController(text: config.trackName);
    _lapsController = TextEditingController(text: '${config.targetLaps}');
    _minutesController = TextEditingController(
      text: '${config.targetRaceTime.inMinutes}',
    );
    _pitLaneController = TextEditingController(
      text: '${config.pitLaneTime.inSeconds}',
    );
    _shiftRpmController = TextEditingController(text: '${config.shiftRpm}');
    _raceType = config.raceType;
  }

  @override
  void didUpdateWidget(covariant _RaceSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final config = widget.initialConfig;
    if (_trackController.text != config.trackName) {
      _trackController.text = config.trackName;
    }
    if (_lapsController.text != '${config.targetLaps}') {
      _lapsController.text = '${config.targetLaps}';
    }
    if (_minutesController.text != '${config.targetRaceTime.inMinutes}') {
      _minutesController.text = '${config.targetRaceTime.inMinutes}';
    }
    if (_pitLaneController.text != '${config.pitLaneTime.inSeconds}') {
      _pitLaneController.text = '${config.pitLaneTime.inSeconds}';
    }
    if (_shiftRpmController.text != '${config.shiftRpm}') {
      _shiftRpmController.text = '${config.shiftRpm}';
    }
    if (_raceType != config.raceType) {
      _raceType = config.raceType;
    }
  }

  @override
  void dispose() {
    _trackController.dispose();
    _lapsController.dispose();
    _minutesController.dispose();
    _pitLaneController.dispose();
    _shiftRpmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Gt7Panel(
      title: 'Race settings',
      subtitle: 'Tune the race target, pit assumptions and shift point.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _trackController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Track name'),
          ),
          const SizedBox(height: Gt7Spacing.md),
          DropdownButtonFormField<RaceType>(
            initialValue: _raceType,
            decoration: const InputDecoration(labelText: 'Race type'),
            items: RaceType.values
                .where((value) => value != RaceType.undefined)
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_raceTypeLabel(value)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _raceType = value;
              });
            },
          ),
          const SizedBox(height: Gt7Spacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lapsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Target laps'),
                ),
              ),
              const SizedBox(width: Gt7Spacing.md),
              Expanded(
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _raceType == RaceType.timeRace
                        ? 'Total minutes'
                        : 'Target minutes',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gt7Spacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pitLaneController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pit lane seconds',
                  ),
                ),
              ),
              const SizedBox(width: Gt7Spacing.md),
              Expanded(
                child: TextField(
                  controller: _shiftRpmController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Shift RPM'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gt7Spacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: Gt7PillButton(label: 'Save settings', onPressed: _save),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final original = widget.initialConfig;
    await widget.onSave(
      original.copyWith(
        trackName: _trackController.text.trim().isEmpty
            ? original.trackName
            : _trackController.text.trim(),
        raceType: _raceType,
        targetLaps: _readInt(
          _lapsController.text,
          original.targetLaps,
          minimum: 1,
        ),
        targetRaceTime: Duration(
          minutes: _readInt(
            _minutesController.text,
            original.targetRaceTime.inMinutes,
            minimum: 1,
          ),
        ),
        pitLaneTime: Duration(
          seconds: _readInt(
            _pitLaneController.text,
            original.pitLaneTime.inSeconds,
            minimum: 0,
          ),
        ),
        shiftRpm: _readInt(
          _shiftRpmController.text,
          original.shiftRpm,
          minimum: 1000,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Race settings saved.')));
  }

  int _readInt(String value, int fallback, {required int minimum}) {
    final parsed = int.tryParse(value.trim()) ?? fallback;
    return parsed < minimum ? fallback : parsed;
  }
}

String _telemetryControlTooltip(RuntimeConnectionPhase phase) {
  return switch (phase) {
    RuntimeConnectionPhase.connecting => 'Connecting...',
    RuntimeConnectionPhase.live => 'Stop telemetry',
    RuntimeConnectionPhase.error => 'Retry telemetry',
    _ => 'Start telemetry',
  };
}

Color _connectionColor(BuildContext context, RuntimeConnectionPhase phase) {
  final scheme = Theme.of(context).colorScheme;
  return switch (phase) {
    RuntimeConnectionPhase.live => scheme.secondary,
    RuntimeConnectionPhase.error => scheme.error,
    RuntimeConnectionPhase.paused => scheme.tertiary,
    RuntimeConnectionPhase.stopped => scheme.secondaryContainer,
    RuntimeConnectionPhase.discovering ||
    RuntimeConnectionPhase.connecting => scheme.primary,
    RuntimeConnectionPhase.idle => scheme.outline,
  };
}

Color _tyreTone(BuildContext context, double temperature) {
  final gt7 = context.gt7Theme;
  if (temperature <= 0) {
    return gt7.textMuted;
  }
  if (temperature < 70) {
    return gt7.computed;
  }
  if (temperature < 95) {
    return gt7.positive;
  }
  if (temperature < 105) {
    return gt7.warning;
  }
  return gt7.danger;
}

Color _deltaTone(BuildContext context, double milliseconds) {
  final gt7 = context.gt7Theme;
  if (milliseconds == 0) {
    return gt7.equal;
  }
  return milliseconds < 0 ? gt7.positive : gt7.warning;
}

Map<int, double> _raceDeltaByLap(RaceViewState race) {
  final values = <int, double>{};
  var cumulative = 0.0;

  for (final lap in race.laps) {
    if (lap.lapNumber <= 0) {
      continue;
    }
    if (lap.complete && lap.lapTimeMs > 0) {
      cumulative += lap.deltaFromTargetMs;
    }
    values[lap.lapNumber] = cumulative;
  }

  return values;
}

String _temperatureLabel(double value) {
  if (value <= 0) {
    return '--';
  }
  return '${value.toStringAsFixed(1)}°';
}

String _relativeTimestamp(DateTime? value) {
  if (value == null) {
    return 'No packets';
  }
  final seconds = DateTime.now().difference(value).inSeconds;
  if (seconds <= 0) {
    return 'Just now';
  }
  return '${seconds}s ago';
}

String _raceTypeLabel(RaceType raceType) {
  return switch (raceType) {
    RaceType.lapRace => 'Lap race',
    RaceType.timeRace => 'Time race',
    RaceType.undefined => 'Undefined',
  };
}

String _formatDurationMs(double milliseconds) {
  if (milliseconds <= 0) {
    return '--';
  }

  final duration = Duration(milliseconds: milliseconds.round());
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hundredths = ((duration.inMilliseconds.remainder(1000)) ~/ 10)
      .toString()
      .padLeft(2, '0');
  return '$minutes:$seconds.$hundredths';
}

String _formatSignedDurationMs(double milliseconds) {
  if (milliseconds == 0) {
    return '0.00';
  }
  final sign = milliseconds > 0 ? '+' : '-';
  return '$sign${_formatDurationMs(milliseconds.abs())}';
}

String _formatAdaptiveSignedDurationMs(
  double milliseconds, {
  required bool compact,
}) {
  if (!compact || milliseconds.abs() >= 60000) {
    return _formatSignedDurationMs(milliseconds);
  }
  if (milliseconds == 0) {
    return '0.00';
  }
  final sign = milliseconds > 0 ? '+' : '-';
  final seconds = milliseconds.abs() / 1000;
  final precision = seconds >= 10 ? 1 : 2;
  return '$sign${seconds.toStringAsFixed(precision)}';
}
