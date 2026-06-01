import 'package:gt7_domain/gt7_domain.dart';

void main() {
  final race = Race(
    RaceType.lapRace,
    5,
    const Duration(minutes: 8).inMilliseconds.toDouble(),
  );

  race.addOrUpdateLap(
    RaceLap(
      lapNumber: 1,
      fuel: 92,
      lapTimeMs: 94000,
      position: 2,
      complete: true,
    ),
  );

  print('Average lap: ${race.avgLapTimeMs()} ms');
}
