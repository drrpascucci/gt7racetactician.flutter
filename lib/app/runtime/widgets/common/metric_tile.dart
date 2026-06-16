import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, this.tone});

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
