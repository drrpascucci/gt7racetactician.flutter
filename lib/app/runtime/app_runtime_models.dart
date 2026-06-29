import 'dart:io';

import 'package:gt7_domain/gt7_domain.dart';
import 'package:gt7_telemetry/gt7_telemetry.dart';

import '../config/app_config.dart';

const _emptyWheelValues = Gt7WheelValues(
  frontLeft: 0,
  frontRight: 0,
  rearLeft: 0,
  rearRight: 0,
  isEmpty: true
);

enum RuntimeConnectionPhase {
  idle,
  discovering,
  stopped,
  connecting,
  live,
  paused,
  error,
}

class RuntimeConnectionState {
  const RuntimeConnectionState({
    required this.phase,
    required this.headline,
    this.detail,
    this.playstationAddress,
    this.usingManualAddress = false,
    this.updatedAt,
  });

  factory RuntimeConnectionState.idle() {
    return const RuntimeConnectionState(
      phase: RuntimeConnectionPhase.idle,
      headline: 'Select PlayStation',
    );
  }

  final RuntimeConnectionPhase phase;
  final String headline;
  final String? detail;
  final InternetAddress? playstationAddress;
  final bool usingManualAddress;
  final DateTime? updatedAt;

  bool get isBusy =>
      phase == RuntimeConnectionPhase.discovering ||
      phase == RuntimeConnectionPhase.connecting;

  bool get canStart =>
      phase == RuntimeConnectionPhase.stopped ||
      phase == RuntimeConnectionPhase.error;

  bool get canStop =>
      phase == RuntimeConnectionPhase.connecting ||
      phase == RuntimeConnectionPhase.live;

  RuntimeConnectionState copyWith({
    RuntimeConnectionPhase? phase,
    String? headline,
    String? detail,
    InternetAddress? playstationAddress,
    bool? usingManualAddress,
  }) {
    return RuntimeConnectionState(
      phase: phase ?? this.phase,
      headline: headline ?? this.headline,
      detail: detail ?? this.detail,
      playstationAddress: playstationAddress ?? this.playstationAddress,
      usingManualAddress: usingManualAddress ?? this.usingManualAddress,
      updatedAt: DateTime.now(),
    );
  }
}

class TelemetryViewState {
  const TelemetryViewState({
    required this.connectionPhase,
    required this.packetsReceived,
    this.packet,
    this.playstationAddress,
    this.usingManualAddress = false,
    this.minimumTireTemperatures = _emptyWheelValues,
    this.maximumTireTemperatures = _emptyWheelValues,
    this.totalDistanceMeters = 0,
    this.lastPacketAt,
    this.errorMessage,
  });

  factory TelemetryViewState.empty() {
    return const TelemetryViewState(
      connectionPhase: RuntimeConnectionPhase.idle,
      packetsReceived: 0,
      totalDistanceMeters: 0,
    );
  }

  final RuntimeConnectionPhase connectionPhase;
  final Gt7TelemetryPacket? packet;
  final InternetAddress? playstationAddress;
  final bool usingManualAddress;
  final int packetsReceived;
  final double totalDistanceMeters;
  final Gt7WheelValues minimumTireTemperatures;
  final Gt7WheelValues maximumTireTemperatures;
  final DateTime? lastPacketAt;
  final String? errorMessage;

  bool get hasLivePacket => packet != null;
  double get speedKph => packet?.speedKph ?? 0;
  double get fuelLevel => packet?.fuelLevel ?? 0;
  double get fuelCapacity => packet?.fuelCapacity ?? 0;
  double get fuelPercent =>
      fuelCapacity <= 0 ? 0 : (fuelLevel / fuelCapacity) * 100;
  double get engineRpm => packet?.engineRpm ?? 0;
  int get currentLap => packet?.currentLap ?? 0;
  int get totalLaps => packet?.totalLaps ?? 0;
  int get position => packet?.racePosition ?? 0;
  Gt7WheelValues get tireTemperatures =>
      packet?.tireTemperatures ?? _emptyWheelValues;
}

class RaceViewState {
  const RaceViewState({
    required this.config,
    required this.laps,
    required this.predictedStints,
    required this.currentLapNumber,
    required this.completedLapCount,
    required this.averageLapTimeMs,
    required this.averageConsumptionPerLap,
    required this.predictedStopLap,
    required this.estimatedFuelToEnd,
    required this.estimatedTotalTimeMs,
    required this.distanceFromTargetMs,
    required this.targetAvgLapTimeMs,
    required this.lastUpdatedAt,
    this.elapsedTime = Duration.zero,
    this.totalDistanceMeters = 0,
    this.lapDistanceMeters = 0,
    this.trackLength = 0,
    this.currentLap,
    this.lastCompletedLap,
  });

  factory RaceViewState.initial(AppConfig config) {
    return RaceViewState(
      config: config,
      laps: const <RaceLap>[],
      predictedStints: const <RaceStint>[],
      currentLapNumber: 0,
      completedLapCount: 0,
      averageLapTimeMs: 0,
      averageConsumptionPerLap: 0,
      predictedStopLap: -1,
      estimatedFuelToEnd: 0,
      estimatedTotalTimeMs: 0,
      distanceFromTargetMs: 0,
      targetAvgLapTimeMs: 0,
      totalDistanceMeters: 0,
      lapDistanceMeters: 0,
      trackLength: 0,
      lastUpdatedAt: DateTime.now(),
      elapsedTime: Duration.zero,
    );
  }

  factory RaceViewState.fromRace({
    required AppConfig config,
    required Race race,
    double totalDistanceMeters = 0,
    Duration elapsedTime = Duration.zero,
  }) {
    final laps = List<RaceLap>.unmodifiable(
      race.laps.map(
        (lap) => RaceLap(
          lapNumber: lap.lapNumber,
          fuel: lap.fuel,
          lapTimeMs: lap.lapTimeMs,
          position: lap.position,
          complete: lap.complete,
          targetTimeMs: lap.targetTimeMs,
          distanceMeters: lap.distanceMeters,
        ),
      ),
    );
    final currentLap = laps.isEmpty ? null : laps.last;
    final completedLaps = laps
        .where((lap) => lap.complete && lap.lapNumber > 0)
        .toList(growable: false);
    final lastCompletedLap = completedLaps.isEmpty ? null : completedLaps.last;
    final lapNumberForEstimates = race.currentLapNumber <= 0
        ? completedLaps.length
        : race.currentLapNumber;
    final averageLapTimeMs = completedLaps.isEmpty
        ? 0.0
        : completedLaps.fold<double>(0, (total, lap) => total + lap.lapTimeMs) /
              completedLaps.length;
    final estimatedTotalTimeMs = averageLapTimeMs <= 0
        ? 0.0
        : averageLapTimeMs * config.targetLaps;
    final distanceFromTargetMs = estimatedTotalTimeMs <= 0
        ? 0.0
        : estimatedTotalTimeMs - config.targetRaceTime.inMilliseconds;

    final predictedStints = List<RaceStint>.unmodifiable(race.predictedStints);
    final pitStopAdjustmentMs =
        race.pitLaneTimeMs * (predictedStints.length - 1).clamp(0, 999);
    final targetAvgLapTimeMs = race.raceLaps <= 0
        ? 0.0
        : (race.raceTimeMs - pitStopAdjustmentMs) / race.raceLaps;

    return RaceViewState(
      config: config,
      laps: laps,
      predictedStints: predictedStints,
      currentLap: currentLap,
      lastCompletedLap: lastCompletedLap,
      currentLapNumber: race.currentLapNumber < 0 ? 0 : race.currentLapNumber,
      completedLapCount: completedLaps.length,
      averageLapTimeMs: averageLapTimeMs,
      averageConsumptionPerLap: race.averageConsumptionPerLap,
      predictedStopLap: race.predictedStop,
      estimatedFuelToEnd: lapNumberForEstimates <= 0
          ? 0
          : race.estimatedTotalFuelToEnd(lapNumberForEstimates),
      estimatedTotalTimeMs: estimatedTotalTimeMs,
      distanceFromTargetMs: distanceFromTargetMs,
      targetAvgLapTimeMs: targetAvgLapTimeMs,
      totalDistanceMeters: totalDistanceMeters,
      lapDistanceMeters: race.laps.isNotEmpty ? race.laps.last.distanceMeters : 0,
      trackLength: race.trackLength,
      lastUpdatedAt: DateTime.now(),
      elapsedTime: elapsedTime,
    );
  }

  final AppConfig config;
  final List<RaceLap> laps;
  final List<RaceStint> predictedStints;
  final RaceLap? currentLap;
  final RaceLap? lastCompletedLap;
  final int currentLapNumber;
  final int completedLapCount;
  final double averageLapTimeMs;
  final double averageConsumptionPerLap;
  /// Target average lap time adjusted for predicted pit stops (ms).
  final double targetAvgLapTimeMs;
  final int predictedStopLap;
  final double estimatedFuelToEnd;
  final double estimatedTotalTimeMs;
  final double distanceFromTargetMs;
  final double totalDistanceMeters;
  final double lapDistanceMeters;
  final double trackLength;
  final DateTime lastUpdatedAt;
  final Duration elapsedTime;

  Duration get remainingTime {
    final remaining = config.targetRaceTime - elapsedTime;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  int get remainingLaps {
    if (config.targetLaps <= 0) return 0;
    if (currentLapNumber <= 0) return config.targetLaps;
    final remaining = config.targetLaps - currentLapNumber + 1;
    return remaining < 0 ? 0 : remaining;
  }
}
