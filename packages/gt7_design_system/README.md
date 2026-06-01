# gt7_design_system

Reusable Flutter design tokens and primitives for GT7-styled apps.

The package ports the legacy GT7 Race Tactician visual language into a
smartphone-first Flutter API:

- dark GT7 color palette and semantic accents
- typography and spacing tokens tuned for handheld readability
- reusable panels, pill buttons, dialog shells, and RPM LED bars
- packaged legacy logo assets for splash/about screens

## Legacy mapping

The legacy desktop UI leaned on:

- dark charcoal surfaces (`#1a1a1a`, `#2a2a2a`)
- white borders/text with yellow, green, blue, and red telemetry accents
- bold Rubik/Consolas typography
- stadium-shaped action buttons and compact zebra tables

This package preserves those semantics while reducing density and raising default
touch targets for Android phones.

## Getting started

```dart
import 'package:gt7_design_system/gt7_design_system.dart';

MaterialApp(
  theme: Gt7AppTheme.dark(),
  home: const MyTelemetryScreen(),
);
```

## Public API

- `Gt7AppTheme` and `Gt7Theme` for Material theme setup
- `Gt7Colors`, `Gt7Spacing`, and `Gt7Typography` for reusable design tokens
- `Gt7Panel`, `Gt7PillButton`, `Gt7DialogFrame`, and `Gt7RpmLedBar` for shared
  GT7-flavored widgets
- `Gt7AssetManifest` for packaged image access

## Usage

```dart
Gt7Panel(
  title: 'PlayStation connection',
  subtitle: 'Dark GT7-styled surface with phone-friendly spacing.',
  child: Column(
    children: [
      Gt7PillButton(
        label: 'Search PS',
        onPressed: () {},
      ),
      const SizedBox(height: Gt7Spacing.md),
      const Gt7RpmLedBar(
        rpm: 6400,
        limit: 7000,
      ),
    ],
  ),
);
```

Legacy desktop fonts such as Rubik and Consolas are not bundled in the source
workspace, so the package expresses their intent through weighted text styles,
tabular telemetry numerals, and system-safe fallbacks. The legacy logos are
bundled and exposed through `Gt7AssetManifest`.

## Reuse notes

- The package depends only on Flutter and its bundled assets.
- Branding is intentionally GT7-specific, but widgets and tokens are isolated
  from any root-app controller, routing, or runtime state.
- Consumers can adopt the full theme or individual primitives independently.
