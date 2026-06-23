import 'package:gt7_domain/gt7_domain.dart';

enum DashboardViewMode { tablet, smartphone }

class AppConfig {
  const AppConfig({
    required this.trackName,
    required this.raceType,
    required this.targetLaps,
    required this.targetRaceTime,
    required this.pitLaneTime,
    required this.shiftPercentage,
    required this.rawLoggingEnabled,
    required this.replaySpeedMultiplier,
    required this.tyreColdMax,
    required this.tyreOptimalMax,
    required this.tyreHotMax,
    required this.viewMode,
    this.manualPlaystationIp,
  });

  const AppConfig.defaults()
    : trackName = 'Race session',
      raceType = RaceType.lapRace,
      targetLaps = 10,
      targetRaceTime = const Duration(minutes: 15),
      pitLaneTime = const Duration(seconds: 30),
      shiftPercentage = 85,
      rawLoggingEnabled = false,
      replaySpeedMultiplier = 1.0,
      tyreColdMax = 70,
      tyreOptimalMax = 90,
      tyreHotMax = 110,
      viewMode = DashboardViewMode.tablet,
      manualPlaystationIp = null;

  final String trackName;
  final RaceType raceType;
  final int targetLaps;
  final Duration targetRaceTime;
  final Duration pitLaneTime;
  /// Short shift warning threshold as a percentage (75-100%) of max alert RPM.
  final int shiftPercentage;
  final bool rawLoggingEnabled;
  final double replaySpeedMultiplier;
  /// Tyre temp (°C) below which tyre is considered cold (blue).
  final int tyreColdMax;
  /// Tyre temp (°C) below which tyre is considered optimal (green).
  final int tyreOptimalMax;
  /// Tyre temp (°C) below which tyre is considered hot (yellow). Above = overheated (red).
  final int tyreHotMax;
  final DashboardViewMode viewMode;
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
    int? shiftPercentage,
    bool? rawLoggingEnabled,
    double? replaySpeedMultiplier,
    int? tyreColdMax,
    int? tyreOptimalMax,
    int? tyreHotMax,
    DashboardViewMode? viewMode,
    String? manualPlaystationIp,
    bool clearManualPlaystationIp = false,
  }) {
    return AppConfig(
      trackName: trackName ?? this.trackName,
      raceType: raceType ?? this.raceType,
      targetLaps: targetLaps ?? this.targetLaps,
      targetRaceTime: targetRaceTime ?? this.targetRaceTime,
      pitLaneTime: pitLaneTime ?? this.pitLaneTime,
      shiftPercentage: shiftPercentage ?? this.shiftPercentage,
      rawLoggingEnabled: rawLoggingEnabled ?? this.rawLoggingEnabled,
      replaySpeedMultiplier:
          replaySpeedMultiplier ?? this.replaySpeedMultiplier,
      tyreColdMax: tyreColdMax ?? this.tyreColdMax,
      tyreOptimalMax: tyreOptimalMax ?? this.tyreOptimalMax,
      tyreHotMax: tyreHotMax ?? this.tyreHotMax,
      viewMode: viewMode ?? this.viewMode,
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
      'shiftPercentage': shiftPercentage,
      'rawLoggingEnabled': rawLoggingEnabled,
      'replaySpeedMultiplier': replaySpeedMultiplier,
      'tyreColdMax': tyreColdMax,
      'tyreOptimalMax': tyreOptimalMax,
      'tyreHotMax': tyreHotMax,
      'viewMode': viewMode.name,
      'manualPlaystationIp': normalizedManualPlaystationIp,
    };
  }

  factory AppConfig.fromJson(Map<String, Object?> json) {
    final defaults = const AppConfig.defaults();
    final raceTypeName = json['raceType'] as String?;
    final rawCold = _readInt(json['tyreColdMax'], defaults.tyreColdMax, minimum: 40);
    final rawOptimal = _readInt(json['tyreOptimalMax'], defaults.tyreOptimalMax, minimum: 40);
    final rawHot = _readInt(json['tyreHotMax'], defaults.tyreHotMax, minimum: 40);
    // Enforce cold < optimal < hot with at least 5°C spacing
    final cold = rawCold.clamp(40, 145);
    final optimal = rawOptimal.clamp(cold + 5, 150);
    final hot = rawHot.clamp(optimal + 5, 155);
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
      shiftPercentage: _readInt(json['shiftPercentage'], defaults.shiftPercentage, minimum: 75).clamp(75, 100),
      rawLoggingEnabled:
          (json['rawLoggingEnabled'] as bool?) ?? defaults.rawLoggingEnabled,
      replaySpeedMultiplier: _readDouble(
        json['replaySpeedMultiplier'],
        defaults.replaySpeedMultiplier,
        minimum: 0.1,
      ),
      tyreColdMax: cold,
      tyreOptimalMax: optimal,
      tyreHotMax: hot,
      viewMode: DashboardViewMode.values.firstWhere(
        (v) => v.name == json['viewMode'],
        orElse: () => defaults.viewMode,
      ),
      manualPlaystationIp: (json['manualPlaystationIp'] as String?)?.trim(),
    );
  }

  static int _readInt(Object? value, int fallback, {required int minimum}) {
    final parsed = switch (value) {
      num numValue => numValue.toInt(),
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
