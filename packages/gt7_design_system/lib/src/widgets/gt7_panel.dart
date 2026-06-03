import 'package:flutter/material.dart';

import 'package:gt7_design_system/src/theme/gt7_theme.dart';
import 'package:gt7_design_system/src/tokens/gt7_spacing.dart';
import 'package:gt7_design_system/src/tokens/gt7_typography.dart';

class Gt7Panel extends StatelessWidget {
  const Gt7Panel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = Gt7Spacing.panelInsets,
    this.alternate = false,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool alternate;

  @override
  Widget build(BuildContext context) {
    final gt7 = context.gt7Theme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: alternate ? gt7.panelAlt : gt7.panel,
        borderRadius: BorderRadius.circular(Gt7Spacing.radiusPanel),
        border: Border.all(color: gt7.border),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || trailing != null) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF424242),
                  borderRadius: BorderRadius.circular(Gt7Spacing.radiusPanel),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Gt7Spacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title != null)
                              Text(
                                title!,
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            if (subtitle != null) ...[
                              const SizedBox(height: Gt7Spacing.xs),
                              Text(
                                subtitle!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: Gt7Spacing.md),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Gt7Spacing.md),
            ],
            DefaultTextStyle(
              style: Gt7Typography.textTheme(
                Theme.of(context).colorScheme,
              ).bodyLarge!,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
