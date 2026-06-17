import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

class LapTableValueCell extends StatelessWidget {
  const LapTableValueCell(this.value, {super.key, this.color, this.compact = false});

  final String value;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Gt7Spacing.xs : Gt7Spacing.sm,
        vertical: compact ? Gt7Spacing.xs : Gt7Spacing.sm,
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: compact ? 18 : 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
