# gt7_domain

Shared GT7 race-domain models and prediction logic.

## Public API

- legacy-compatible `RaceType` and `RaceStrategy` enums
- `Race`, `RaceLap`, and `RaceStint` models
- fuel, lap-count, and time-race prediction helpers kept independent from UI
  code

## Usage

```dart
final race = Race(
  RaceType.lapRace,
  12,
  const Duration(minutes: 18).inMilliseconds.toDouble(),
  pitLaneTimeMs: const Duration(seconds: 30).inMilliseconds.toDouble(),
)
  ..trackName = 'Tokyo Expressway'
  ..tankCapacity = 100
  ..currentFuelLevel = 42;

race.addOrUpdateLap(
  RaceLap(
    lapNumber: 1,
    fuel: 90,
    lapTimeMs: 97000,
    position: 3,
    complete: true,
  ),
);
```

## Test focus

The package tests cover:

- enum compatibility with the legacy application
- lap-race and time-race prediction behavior
- stint calculations and lap delta defaults

## Reuse notes

- The package is pure Dart with no Flutter or app-runtime dependency.
- Public exports are limited to domain models and enums; workspace-specific
  metadata is no longer part of the API surface.
