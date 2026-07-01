import 'package:gt7_domain/gt7_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Race enums', () {
    test('preserve legacy values', () {
      expect(RaceType.undefined.legacyValue, 0);
      expect(RaceType.lapRace.legacyValue, 1);
      expect(RaceType.timeRace.legacyValue, 2);
      expect(RaceStrategy.undefined.legacyValue, 0);
      expect(RaceStrategy.frontload.legacyValue, 1);
      expect(RaceStrategy.backload.legacyValue, 2);
      expect(RaceStrategy.evenload.legacyValue, 3);
    });
  });

  group('Race domain', () {
    test('keeps lap zero sentinel semantics in lap races', () {
      final race = Race(
        RaceType.lapRace,
        10,
        900000,
        pitLaneTimeMs: 30000,
        raceStrategy: RaceStrategy.frontload,
      );

      race.addOrUpdateLap(
        RaceLap(
          lapNumber: 0,
          fuel: 100,
          lapTimeMs: 0,
          position: 1,
          complete: true,
        ),
      );
      race.addOrUpdateLap(
        RaceLap(
          lapNumber: 1,
          fuel: 90,
          lapTimeMs: 90000,
          position: 1,
          complete: true,
        ),
      );
      race.addOrUpdateLap(
        RaceLap(
          lapNumber: 2,
          fuel: 80,
          lapTimeMs: 92000,
          position: 1,
          complete: true,
        ),
      );

      expect(race.currentLapNumber, 2);
      expect(race.avgLapTimeMs(), closeTo(60666.666666666664, 0.000001));
      expect(race.averageConsumptionPerLap, 10);
      expect(race.distanceFromTargetMs(2), 10000);
      expect(race.predictedStop, 10);
      expect(race.estimatedTotalFuelToEnd(2), 90);

      final stint = race.predictedStints.single;
      expect(stint.startLap, 1);
      expect(stint.endLap, 10);
      expect(stint.predictedFuelUsed, 100);
      expect(race.avgTargetTimeMs, 90000);
    });

    test(
      'detects pit stops from fuel increases and preserves consumption on refuel lap',
      () {
        final race = Race(RaceType.lapRace, 10, 900000, pitLaneTimeMs: 30000);

        for (final lap in <RaceLap>[
          RaceLap(
            lapNumber: 0,
            fuel: 100,
            lapTimeMs: 0,
            position: 1,
            complete: true,
          ),
          RaceLap(
            lapNumber: 1,
            fuel: 90,
            lapTimeMs: 90000,
            position: 1,
            complete: true,
          ),
          RaceLap(
            lapNumber: 2,
            fuel: 80,
            lapTimeMs: 92000,
            position: 1,
            complete: true,
          ),
        ]) {
          race.addOrUpdateLap(lap);
        }

        race.addOrUpdateLap(
          RaceLap(
            lapNumber: 3,
            fuel: 95,
            lapTimeMs: 120000,
            position: 1,
            complete: true,
          ),
        );

        expect(race.lastRefuelLap, 3);
        expect(race.averageConsumptionPerLap, 10);
        expect(race.lastLapConsumption, 10);
        expect(race.predictedStop, 12);

        race.addOrUpdateLap(
          RaceLap(
            lapNumber: 4,
            fuel: 84,
            lapTimeMs: 91000,
            position: 1,
            complete: true,
          ),
        );

        expect(race.averageConsumptionPerLap, 11);
        expect(race.lastLapConsumption, 11);
      },
    );

    test('applies legacy time-race stint prediction behavior', () {
      final race = Race(RaceType.timeRace, 10, 600000, pitLaneTimeMs: 30000);

      for (final lap in <RaceLap>[
        RaceLap(
          lapNumber: 0,
          fuel: 100,
          lapTimeMs: 0,
          position: 1,
          complete: true,
        ),
        RaceLap(
          lapNumber: 1,
          fuel: 25,
          lapTimeMs: 100000,
          position: 1,
          complete: true,
        ),
        RaceLap(
          lapNumber: 2,
          fuel: 15,
          lapTimeMs: 100000,
          position: 1,
          complete: true,
        ),
      ]) {
        race.addOrUpdateLap(lap);
      }

      expect(race.avgLapTimeMs(), closeTo(66666.66666666667, 0.000001));
      expect(race.averageConsumptionPerLap, 42.5);
      expect(race.predictedStop, 2);
      expect(race.avgTargetTimeMs, 45000);

      final stints = race.predictedStints;
      expect(stints, hasLength(6));
      expect(stints[0].startLap, 1);
      expect(stints[0].endLap, 2);
      expect(stints[0].predictedFuelUsed, closeTo(100, 0.001));
      expect(stints[1].startLap, 3);
      expect(stints[1].endLap, 4);
      expect(stints[1].predictedFuelUsed, closeTo(100, 0.001));
      expect(stints[2].startLap, 5);
      expect(stints[2].endLap, 6);
      expect(stints[3].startLap, 7);
      expect(stints[3].endLap, 8);
      expect(stints[4].startLap, 9);
      expect(stints[4].endLap, 9);
      expect(stints[5].startLap, 10);
      expect(stints[5].endLap, 10);

    });

    test('lap delta returns zero until a target is set', () {
      final lap = RaceLap(lapNumber: 1, lapTimeMs: 90000);

      expect(lap.deltaFromTargetMs, 0);

      lap.targetTimeMs = 89500;

      expect(lap.deltaFromTargetMs, 500);
    });

    test('handles zero fuel consumption gracefully', () {
      final race = Race(RaceType.lapRace, 10, 900000, pitLaneTimeMs: 30000);

      // Add laps with no fuel consumption
      race.addOrUpdateLap(
        RaceLap(
          lapNumber: 0,
          fuel: 100,
          lapTimeMs: 0,
          position: 1,
          complete: true,
        ),
      );
      race.addOrUpdateLap(
        RaceLap(
          lapNumber: 1,
          fuel: 100,
          lapTimeMs: 90000,
          position: 1,
          complete: true,
        ),
      );
      race.addOrUpdateLap(
        RaceLap(
          lapNumber: 2,
          fuel: 100,
          lapTimeMs: 92000,
          position: 1,
          complete: true,
        ),
      );

      expect(race.averageConsumptionPerLap, 0);
      expect(race.predictedStints, isEmpty);
      expect(race.estimatedTotalFuelToEnd(2), 0);
    });
  });
}
