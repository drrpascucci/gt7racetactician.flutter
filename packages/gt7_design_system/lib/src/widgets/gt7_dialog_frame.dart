import 'package:flutter/material.dart';

import 'package:gt7_design_system/src/theme/gt7_theme.dart';
import 'package:gt7_design_system/src/tokens/gt7_spacing.dart';
import 'package:gt7_design_system/src/tokens/gt7_typography.dart';
import 'package:gt7_design_system/src/widgets/gt7_panel.dart';

class Gt7DialogFrame extends StatelessWidget {
  const Gt7DialogFrame({
    super.key,
    required this.title,
    this.message,
    this.child,
    this.actions = const <Widget>[],
    this.maxWidth = 420,
  });

  final String title;
  final String? message;
  final Widget? child;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final gt7 = context.gt7Theme;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Gt7Panel(
          title: title,
          padding: Gt7Spacing.dialogInsets,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message != null) ...[
                Text(
                  message!,
                  style: Gt7Typography.textTheme(
                    Theme.of(context).colorScheme,
                  ).bodyLarge?.copyWith(color: gt7.telemetry),
                ),
                if (child != null) const SizedBox(height: Gt7Spacing.md),
              ],
              // ignore: use_null_aware_elements
              if (child != null) child!,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: Gt7Spacing.lg),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: Gt7Spacing.sm,
                  runSpacing: Gt7Spacing.sm,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
