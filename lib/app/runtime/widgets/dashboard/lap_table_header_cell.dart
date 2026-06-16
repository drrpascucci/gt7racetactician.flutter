import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

class LapTableHeaderCell extends StatelessWidget {
  const LapTableHeaderCell(this.label, {super.key, this.compact = false, this.color});

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
          ).copyWith(fontSize: 12),
        ),
      ),
    );
  }
}
