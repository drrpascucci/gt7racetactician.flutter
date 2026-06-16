import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';
import 'package:gt7_domain/gt7_domain.dart';

import '../../app_runtime_models.dart';
import '../runtime_ui_utils.dart';
import 'lap_table_header_cell.dart';
import 'lap_table_value_cell.dart';

class LapSection extends StatelessWidget {
  const LapSection({super.key, required this.race});

  final RaceViewState race;

  @override
  Widget build(BuildContext context) {
    final raceDeltaByLapValues = raceDeltaByLap(race);
    const layout = LapTableLayout();

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
                            LapTableHeaderCell(
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
                          children: buildLapTableCells(
                            context: context,
                            lap: laps[index],
                            layout: layout,
                            raceDeltaMs:
                                raceDeltaByLapValues[laps[index].lapNumber] ?? 0,
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
}) {
  final gt7 = context.gt7Theme;
  final lapLabel = !lap.complete ? '${lap.lapNumber}*' : '${lap.lapNumber}';
  final lapTone = !lap.complete ? gt7.highlight : null;
  final averageDeltaValue = formatAdaptiveSignedDurationMs(
    lap.deltaFromTargetMs,
    compact: layout.compact,
  );
  final averageDeltaTone = deltaTone(context, lap.deltaFromTargetMs);
  final raceDeltaValue = formatAdaptiveSignedDurationMs(
    raceDeltaMs,
    compact: layout.compact,
  );
  final raceDeltaTone = deltaTone(context, raceDeltaMs);
  final compactCells = layout.compact;

  return [
    LapTableValueCell(lapLabel, color: lapTone, compact: compactCells),
    LapTableValueCell(
      lap.position <= 0 ? '--' : '${lap.position}',
      compact: compactCells,
    ),
    LapTableValueCell(
      lap.lapTimeMs > 0 ? formatDurationMs(lap.lapTimeMs.toDouble()) : '--',
      color: !lap.complete ? gt7.highlight : null,
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
