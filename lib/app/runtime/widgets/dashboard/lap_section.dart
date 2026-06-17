import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';
import 'package:gt7_domain/gt7_domain.dart';

import '../../app_runtime_models.dart';
import '../runtime_ui_utils.dart';
import 'lap_table_header_cell.dart';
import 'lap_table_value_cell.dart';

class LapSection extends StatelessWidget {
  const LapSection({super.key, required this.race, required this.connection});

  final RaceViewState race;
  final RuntimeConnectionState connection;

  @override
  Widget build(BuildContext context) {
    var laps = race.laps.where((l) => l.lapNumber > 0).toList();
    final isNotLive = connection.phase != RuntimeConnectionPhase.live;

    if (isNotLive && laps.isEmpty) {
      // Dummy data for visualization
      laps = [
        RaceLap(lapNumber: 5, position: 2, lapTimeMs: 91200, fuel: 85, complete: true, targetTimeMs: 91500),
        RaceLap(lapNumber: 4, position: 3, lapTimeMs: 92100, fuel: 88, complete: true, targetTimeMs: 91500),
        RaceLap(lapNumber: 3, position: 3, lapTimeMs: 91450, fuel: 91, complete: true, targetTimeMs: 91500),
        RaceLap(lapNumber: 2, position: 4, lapTimeMs: 93500, fuel: 94, complete: true, targetTimeMs: 91500),
        RaceLap(lapNumber: 1, position: 4, lapTimeMs: 95000, fuel: 97, complete: true, targetTimeMs: 91500),
      ];
    }

    final raceDeltaByLapValues = raceDeltaByLap(race);
    if (isNotLive && laps.isNotEmpty && raceDeltaByLapValues.isEmpty) {
      // Approximate deltas for dummy data
      var cum = 0.0;
      for (var i = 1; i <= 5; i++) {
        final lap = laps.firstWhere((l) => l.lapNumber == i);
        cum += lap.deltaFromTargetMs;
        raceDeltaByLapValues[i] = cum;
      }
    }

    const layout = LapTableLayout();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF545454), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const rowH = 36.0;
          final maxRows = (constraints.maxHeight / rowH).floor().clamp(2, 20) - 1;
          final displayLaps = laps.reversed.take(maxRows).toList();

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
                      color: Color(0xFF333333), // Gray background for headers
                    ),
                    children: [
                      for (var i = 0; i < layout.headers.length; i++)
                        LapTableHeaderCell(
                          layout.headers[i],
                          compact: true,
                          color: Colors.grey[400],
                        ),
                    ],
                  ),
                  for (var index = 0; index < displayLaps.length; index++)
                    TableRow(
                      decoration: BoxDecoration(
                        color: index.isOdd ? const Color(0xFF222222) : Colors.black,
                      ),
                      children: buildLapTableCells(
                        context: context,
                        lap: displayLaps[index],
                        layout: layout,
                        raceDeltaMs: raceDeltaByLapValues[displayLaps[index].lapNumber] ?? 0,
                        targetAvgLapTimeMs: race.targetAvgLapTimeMs,
                        targetRaceTimeMs: race.config.targetRaceTime.inMilliseconds.toDouble(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LapTableLayout {
  const LapTableLayout();

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

List<Widget> buildLapTableCells({
  required BuildContext context,
  required RaceLap lap,
  required LapTableLayout layout,
  required double raceDeltaMs,
  required double targetAvgLapTimeMs,
  required double targetRaceTimeMs,
}) {
  final lapLabel = !lap.complete ? '${lap.lapNumber}*' : '${lap.lapNumber}';
  final averageDeltaValue = formatAdaptiveSignedDurationMs(
    lap.deltaFromTargetMs,
    compact: layout.compact,
  );
  final averageDeltaTone = deltaTone(context, lap.deltaFromTargetMs, targetAvgLapTimeMs);
  final raceDeltaValue = formatAdaptiveSignedDurationMs(
    raceDeltaMs,
    compact: layout.compact,
  );
  // For race delta, we compare with total race target? 
  // Or maybe just use the same per-lap logic but scaled? 
  // Let's use 0.5% of total race time as threshold for azure.
  final raceDeltaTone = deltaTone(context, raceDeltaMs, targetRaceTimeMs);
  final compactCells = layout.compact;

  return [
    LapTableValueCell(lapLabel, compact: compactCells),
    LapTableValueCell(
      lap.position <= 0 ? '--' : '${lap.position}',
      compact: compactCells,
    ),
    LapTableValueCell(
      lap.lapTimeMs > 0 ? formatDurationMs(lap.lapTimeMs.toDouble()) : '--',
      compact: compactCells,
    ),
    LapTableValueCell(
      averageDeltaValue,
      color: averageDeltaTone,
      compact: compactCells,
    ),
    LapTableValueCell(
      raceDeltaValue,
      color: raceDeltaTone,
      compact: compactCells,
    ),
    LapTableValueCell(
      lap.fuel <= 0 ? '--' : lap.fuel.toStringAsFixed(0),
      compact: compactCells,
    ),
  ];
}
