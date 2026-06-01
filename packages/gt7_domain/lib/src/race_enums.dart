enum RaceType {
  undefined(0),
  lapRace(1),
  timeRace(2);

  const RaceType(this.legacyValue);

  final int legacyValue;
}

enum RaceStrategy {
  undefined(0),
  frontload(1),
  backload(2),
  evenload(3);

  const RaceStrategy(this.legacyValue);

  final int legacyValue;
}
