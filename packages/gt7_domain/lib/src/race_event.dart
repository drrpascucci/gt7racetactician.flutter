import 'package:gt7_domain/src/race_lap.dart';

sealed class RaceEvent {}

class RaceStartedEvent extends RaceEvent {
  final int position;
  final double fuelLevel;
  RaceStartedEvent(this.position, this.fuelLevel);
}

class NewLapStartedEvent extends RaceEvent {
  final int lapNumber;
  final RaceLap? previousLap;

  NewLapStartedEvent(this.lapNumber, {this.previousLap});
}

class LowFuelEvent extends RaceEvent {
  final double fuelLevel;
  final double remainingLaps;

  LowFuelEvent(this.fuelLevel, this.remainingLaps);
}

class PositionChangedEvent extends RaceEvent {
  final int oldPosition;
  final int newPosition;

  PositionChangedEvent(this.oldPosition, this.newPosition);
}
