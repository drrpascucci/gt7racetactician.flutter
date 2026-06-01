import 'package:gt7_domain/gt7_domain.dart';

class AppConfig {
  const AppConfig({
    required this.trackName,
    required this.raceType,
    required this.targetLaps,
    required this.targetRaceTime,
    required this.pitLaneTime,
    required this.shiftRpm,
    required this.rawLoggingEnabled,
    required this.replaySpeedMultiplier,
    this.manualPlaystationIp,
  });

  const AppConfig.defaults()
    : trackName = 'Race session',
      raceType = RaceType.lapRace,
      targetLaps = 10,
      targetRaceTime = const Duration(minutes: 15),
      pitLaneTime = const Duration(seconds: 30),
      shiftRpm = 7800,
      rawLoggingEnabled = false,
      replaySpeedMultiplier = 1.0,
      manualPlaystationIp = null;

  final String trackName;
  final RaceType raceType;
  final int targetLaps;
  final Duration targetRaceTime;
  final Duration pitLaneTime;
  final int shiftRpm;
  final bool rawLoggingEnabled;
  final double replaySpeedMultiplier;
  final String? manualPlaystationIp;

  String? get normalizedManualPlaystationIp {
    final value = manualPlaystationIp?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String get connectionKey => normalizedManualPlaystationIp ?? 'auto';

  AppConfig copyWith({
    String? trackName,
    RaceType? raceType,
    int? targetLaps,
    Duration? targetRaceTime,
    Duration? pitLaneTime,
    int? shiftRpm,
    bool? rawLoggingEnabled,
    double? replaySpeedMultiplier,
    String? manualPlaystationIp,
    bool clearManualPlaystationIp = false,
  }) {
    return AppConfig(
      trackName: trackName ?? this.trackName,
      raceType: raceType ?? this.raceType,
      targetLaps: targetLaps ?? this.targetLaps,
      targetRaceTime: targetRaceTime ?? this.targetRaceTime,
      pitLaneTime: pitLaneTime ?? this.pitLaneTime,
      shiftRpm: shiftRpm ?? this.shiftRpm,
      rawLoggingEnabled: rawLoggingEnabled ?? this.rawLoggingEnabled,
      replaySpeedMultiplier:
          replaySpeedMultiplier ?? this.replaySpeedMultiplier,
      manualPlaystationIp: clearManualPlaystationIp
          ? null
          : manualPlaystationIp ?? this.manualPlaystationIp,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'trackName': trackName,
      'raceType': raceType.name,
      'targetLaps': targetLaps,
      'targetRaceTimeMs': targetRaceTime.inMilliseconds,
      'pitLaneTimeMs': pitLaneTime.inMilliseconds,
      'shiftRpm': shiftRpm,
      'rawLoggingEnabled': rawLoggingEnabled,
      'replaySpeedMultiplier': replaySpeedMultiplier,
      'manualPlaystationIp': normalizedManualPlaystationIp,
    };
  }

  factory AppConfig.fromJson(Map<String, Object?> json) {
    final defaults = const AppConfig.defaults();
    final raceTypeName = json['raceType'] as String?;
    return AppConfig(
      trackName: (json['trackName'] as String?)?.trim().isNotEmpty == true
          ? (json['trackName'] as String).trim()
          : defaults.trackName,
      raceType: RaceType.values.firstWhere(
        (value) => value.name == raceTypeName,
        orElse: () => defaults.raceType,
      ),
      targetLaps: _readInt(json['targetLaps'], defaults.targetLaps, minimum: 1),
      targetRaceTime: Duration(
        milliseconds: _readInt(
          json['targetRaceTimeMs'],
          defaults.targetRaceTime.inMilliseconds,
          minimum: 60000,
        ),
      ),
      pitLaneTime: Duration(
        milliseconds: _readInt(
          json['pitLaneTimeMs'],
          defaults.pitLaneTime.inMilliseconds,
          minimum: 0,
        ),
      ),
      shiftRpm: _readInt(json['shiftRpm'], defaults.shiftRpm, minimum: 1000),
      rawLoggingEnabled:
          (json['rawLoggingEnabled'] as bool?) ?? defaults.rawLoggingEnabled,
      replaySpeedMultiplier: _readDouble(
        json['replaySpeedMultiplier'],
        defaults.replaySpeedMultiplier,
        minimum: 0.1,
      ),
      manualPlaystationIp: (json['manualPlaystationIp'] as String?)?.trim(),
    );
  }

  static int _readInt(Object? value, int fallback, {required int minimum}) {
    final parsed = switch (value) {
      int intValue => intValue,
      String stringValue => int.tryParse(stringValue) ?? fallback,
      _ => fallback,
    };
    return parsed < minimum ? fallback : parsed;
  }

  static double _readDouble(
    Object? value,
    double fallback, {
    required double minimum,
  }) {
    final parsed = switch (value) {
      num numValue => numValue.toDouble(),
      String stringValue => double.tryParse(stringValue) ?? fallback,
      _ => fallback,
    };
    return parsed < minimum ? fallback : parsed;
  }
}
