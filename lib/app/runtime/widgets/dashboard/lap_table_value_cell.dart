import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

class LapTableValueCell extends StatelessWidget {
  const LapTableValueCell(this.value, {super.key, this.color, this.compact = false});

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
