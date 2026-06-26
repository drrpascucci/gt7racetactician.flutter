import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';
import 'package:gt7_domain/gt7_domain.dart';
import '../app_runtime_models.dart';

String telemetryControlTooltip(RuntimeConnectionPhase phase) {
  return switch (phase) {
    RuntimeConnectionPhase.connecting => 'Connecting...',
    RuntimeConnectionPhase.live => 'Stop telemetry',
    RuntimeConnectionPhase.error => 'Retry telemetry',
    _ => 'Start telemetry',
  };
}

Color connectionColor(BuildContext context, RuntimeConnectionPhase phase) {
  final scheme = Theme.of(context).colorScheme;
  return switch (phase) {
    RuntimeConnectionPhase.live => scheme.secondary,
    RuntimeConnectionPhase.error => scheme.error,
    RuntimeConnectionPhase.paused => scheme.tertiary,
    RuntimeConnectionPhase.stopped => scheme.secondaryContainer,
    RuntimeConnectionPhase.discovering ||
    RuntimeConnectionPhase.connecting => scheme.primary,
    RuntimeConnectionPhase.idle => scheme.outline,
  };
}

Color tyreTone(
  double temperature, {
  required int coldMax,
  required int optimalMax,
  required int hotMax,
}) {
  if (temperature <= 0) {
    return Gt7Colors.undefinedTempColor;
  }
  if (temperature < coldMax) {
    return Gt7Colors.coldTempColor; // blue — cold
  }
  if (temperature < optimalMax) {
    return Gt7Colors.optimalTempColor; // green — optimal
  }
  if (temperature < hotMax) {
    return Gt7Colors.hotTempColor; // yellow — hot
  }
  return Gt7Colors.overheatedTempColor; // red — overheated
}

Color deltaTone(BuildContext context, double milliseconds, [double? targetMs]) {
  if (milliseconds == 0) {
    return Colors.white;
  }
  final threshold = (targetMs ?? 0) * 0.005;
  if (targetMs != null && targetMs > 0 && milliseconds.abs() <= threshold) {
    return const Color(0xFF1E88E5); // Blue/Azure — similar
  }
  return milliseconds < 0 
      ? const Color(0xFF43A047) // Green — faster
      : const Color(0xFFE53935); // Red — slower
}

Map<int, double> raceDeltaByLap(RaceViewState race) {
  final values = <int, double>{};
  var cumulative = 0.0;

  for (final lap in race.laps) {
    if (lap.lapNumber <= 0) {
      continue;
    }
    if (lap.complete && lap.lapTimeMs > 0) {
      cumulative += lap.deltaFromTargetMs;
    }
    values[lap.lapNumber] = cumulative;
  }

  return values;
}

String temperatureLabel(double value) {
  if (value <= 0) {
    return '80.0';
  }
  return value < 100
      ? '${value.toStringAsFixed(1)}'
      : '${value.toStringAsFixed(0)}';
}

String relativeTimestamp(DateTime? value) {
  if (value == null) {
    return 'No packets';
  }
  final seconds = DateTime.now().difference(value).inSeconds;
  if (seconds <= 0) {
    return 'Just now';
  }
  return '${seconds}s ago';
}

String raceTypeLabel(RaceType raceType) {
  return switch (raceType) {
    RaceType.lapRace => 'Lap race',
    RaceType.timeRace => 'Time race',
    RaceType.undefined => 'Undefined',
  };
}

String formatDurationMs(double milliseconds) {
  if (milliseconds <= 0) {
    return '--';
  }

  final duration = Duration(milliseconds: milliseconds.round());
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hundredths = ((duration.inMilliseconds.remainder(1000)) ~/ 10)
      .toString()
      .padLeft(2, '0');
  return '$minutes:$seconds.$hundredths';
}

String formatSignedDurationMs(double milliseconds) {
  if (milliseconds == 0) {
    return '0.00';
  }
  final sign = milliseconds > 0 ? '+' : '-';
  return '$sign${formatDurationMs(milliseconds.abs())}';
}

String formatAdaptiveSignedDurationMs(
  double milliseconds, {
  required bool compact,
}) {
  if (!compact || milliseconds.abs() >= 60000) {
    return formatSignedDurationMs(milliseconds);
  }
  if (milliseconds == 0) {
    return '0.00';
  }
  final sign = milliseconds > 0 ? '+' : '-';
  final seconds = milliseconds.abs() / 1000;
  final precision = seconds >= 10 ? 1 : 2;
  return '$sign${seconds.toStringAsFixed(precision)}';
}
