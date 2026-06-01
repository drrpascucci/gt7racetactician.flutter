class RaceLap implements Comparable<RaceLap> {
  RaceLap({
    required this.lapNumber,
    this.fuel = 0,
    this.lapTimeMs = 0,
    this.position = 0,
    this.complete = false,
    this.targetTimeMs = 0,
  });

  final int lapNumber;
  double fuel;
  double lapTimeMs;
  double targetTimeMs;
  int position;
  bool complete;

  double get deltaFromTargetMs {
    if (targetTimeMs == 0) {
      return 0;
    }
    return lapTimeMs - targetTimeMs;
  }

  void copyValues(RaceLap other) {
    fuel = other.fuel;
    lapTimeMs = other.lapTimeMs;
    targetTimeMs = other.targetTimeMs;
    position = other.position;
    complete = other.complete;
  }

  @override
  int compareTo(RaceLap other) => lapNumber.compareTo(other.lapNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RaceLap &&
          runtimeType == other.runtimeType &&
          lapNumber == other.lapNumber;

  @override
  int get hashCode => lapNumber.hashCode;

  @override
  String toString() {
    return 'RaceLap('
        'lap=$lapNumber,'
        'lapTime=$lapTimeMs,'
        'target=$targetTimeMs,'
        'fuel=$fuel,'
        'position=$position,'
        'complete=$complete'
        ')';
  }
}
