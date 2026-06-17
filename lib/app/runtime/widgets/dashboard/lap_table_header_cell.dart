import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

class LapTableHeaderCell extends StatelessWidget {
  const LapTableHeaderCell(this.label, {super.key, this.compact = false, this.color});

  final String label;
  final bool compact;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Gt7Spacing.xs,
        vertical: Gt7Spacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? Colors.grey[400]!,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
