class RaceStint {
  RaceStint({
    required this.stintNumber,
    required this.startLap,
    required this.startTimeMs,
    required this.endLap,
    required this.endTimeMs,
    required this.predictedFuelUsed,
  });

  final int stintNumber;
  final int startLap;
  final int endLap;
  final double predictedFuelUsed;
  final double startTimeMs;
  final double endTimeMs;

  @override
  String toString() {
    return 'RaceStint('
        'stint=$stintNumber,'
        'startLap=$startLap,'
        'endLap=$endLap,'
        'predictedFuelUsed=$predictedFuelUsed,'
        'startTimeMs=$startTimeMs,'
        'endTimeMs=$endTimeMs'
        ')';
  }
}
