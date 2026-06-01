import 'package:gt7_domain/gt7_domain.dart';
import 'package:test/test.dart';

void main() {
  test('exports reusable race-domain types', () {
    expect(RaceType.lapRace.legacyValue, 1);

    final lap = RaceLap(lapNumber: 2, fuel: 80, lapTimeMs: 92000);

    expect(lap.lapNumber, 2);
    expect(lap.deltaFromTargetMs, 0);
  });
}
