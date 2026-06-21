import 'dart:async';
import 'dart:math';

import 'package:gt7_domain/src/race_enums.dart';
import 'package:gt7_domain/src/race_event.dart';
import 'package:gt7_domain/src/race_lap.dart';
import 'package:gt7_domain/src/race_stint.dart';

class Race {
  Race(
    this.raceType,
    this.raceLaps,
    this.raceTimeMs, {
    this.pitLaneTimeMs = 0,
    this.raceStrategy = RaceStrategy.frontload,
  }) : targetLapTimeMs = raceLaps == 0 ? 0 : raceTimeMs / raceLaps {
    reset();
  }

  final _eventController = StreamController<RaceEvent>.broadcast();
  Stream<RaceEvent> get events => _eventController.stream;

  final List<RaceLap> laps = <RaceLap>[];

  int lastRefuelLap = 1;
  int _lastEventLap = -1;
  int _lastEventPosition = -1;
  double _lastEventFuel = -1;
  bool _raceStartedFired = false;
  double avgConsumptionPerLap = 0;
  double currentFuelLevel = 100;
  double pitLaneTimeMs;
  double predictedRefuelQty = 100;
  double tankCapacity = 100;
  String trackName = '';
  bool debug = false;
  RaceType raceType;
  RaceStrategy raceStrategy;
  int targetLaps = 0;
  double targetLapTimeMs;
  double lastLapConsumption = 0;
  double currentRefuelQty = 100;
  int raceLaps;
  double raceTimeMs;

  int get predictedStop =>
      predictedStints.isNotEmpty ? predictedStints.first.endLap : -1;

  int get currentLapNumber => laps.isNotEmpty ? laps.last.lapNumber : -1;

  List<RaceStint> get predictedStints => computeStintPredictions();

  double get avgTargetTimeMs {
    if (raceLaps == 0) {
      return 0;
    }
    final pitStopAdjustmentMs = max(
      pitLaneTimeMs * (predictedStints.length - 1),
      0,
    );
    return (raceTimeMs - pitStopAdjustmentMs) / raceLaps;
  }

  double get averageConsumptionPerLap => avgConsumptionPerLap;

  List<RaceStint> computeStintPredictions() {
    final stints = <RaceStint>[];
    var remainingLaps = -1;

    if (laps.isEmpty) {
      return stints;
    }

    if (raceType == RaceType.lapRace) {
      remainingLaps = raceLaps - currentLapNumber;
    } else {
      final remainingTimeMs = raceTimeMs - _timeToLapMs(currentLapNumber);
      final averageLapTime = avgLapTimeMs();
      if (averageLapTime > 0) {
        remainingLaps = (remainingTimeMs / averageLapTime).ceil();
      }
    }

    if (remainingLaps < 0 || avgConsumptionPerLap <= 0) {
      return stints;
    }

    // Defensive check: ensure avgConsumptionPerLap is positive before division
    assert(avgConsumptionPerLap > 0, 'avgConsumptionPerLap must be > 0');
    
    final lapsWithFullTank = (tankCapacity / avgConsumptionPerLap).floor();
    final lapsWithCurrentFuel = (laps.last.fuel / avgConsumptionPerLap).floor();

    var stintStart = max(lastRefuelLap, 1);
    var stintEnd = currentLapNumber + lapsWithCurrentFuel;

    while (stintStart < raceLaps) {
      final startTimeMs = _timeToLapMs(stintStart);
      final endTimeMs =
          startTimeMs + (stintEnd - stintStart + 1) * avgLapTimeMs();

      stints.add(
        RaceStint(
          stintNumber: stints.length + 1,
          startLap: stintStart,
          startTimeMs: startTimeMs,
          endLap: stintEnd,
          endTimeMs: endTimeMs,
          predictedFuelUsed: min(
            tankCapacity,
            (stintEnd - stintStart + 1 + 0.5) * avgConsumptionPerLap,
          ),
        ),
      );

      stintStart = stintEnd + 1;
      if (raceType == RaceType.lapRace) {
        remainingLaps = raceLaps - stintEnd;
      } else {
        final remainingTimeMs = raceTimeMs - (stintEnd * avgLapTimeMs());
        final averageLapTime = avgLapTimeMs();
        if (averageLapTime > 0) {
          remainingLaps = (remainingTimeMs / averageLapTime).ceil();
        } else {
          remainingLaps = 0;
        }
      }
      stintEnd = stintStart + min<int>(lapsWithFullTank, remainingLaps) - 1;
    }

    return stints;
  }

  void addOrUpdateLap(RaceLap lap) {
    if (lap.lapNumber < 0) {
      return;
    }

    for (final existingLap in laps) {
      if (existingLap.lapNumber == lap.lapNumber) {
        final oldPosition = existingLap.position;
        existingLap.lapTimeMs = lap.lapTimeMs;
        existingLap.fuel = lap.fuel;
        existingLap.position = lap.position;

        if (oldPosition != 0 && oldPosition != lap.position) {
          _eventController.add(PositionChangedEvent(oldPosition, lap.position));
          _lastEventPosition = lap.position;
        }
        return;
      }
    }

    if (!_raceStartedFired && lap.lapNumber == 1) {
      _eventController.add(RaceStartedEvent(lap.position, lap.fuel));
      _raceStartedFired = true;
    }

    final lastLap = laps.isNotEmpty ? laps.last : null;
    final lastFuel = lastLap?.fuel ?? 100;

    lap.targetTimeMs = avgTargetTimeMs;

    final isPitStop = lastLap != null && lap.fuel > lastLap.fuel;
    if (isPitStop && lap.lapNumber > 1) {
      lastRefuelLap = lap.lapNumber;
    } else {
      final lapsSinceRefuel = lap.lapNumber - lastRefuelLap;
      if (lapsSinceRefuel > 0) {
        final refuelLap = _lapForNumber(lastRefuelLap);
        if (refuelLap != null) {
          final fuelUsedFromPitstop = refuelLap.fuel - lap.fuel;
          lastLapConsumption = lastFuel - lap.fuel;
          if (fuelUsedFromPitstop > 0) {
            avgConsumptionPerLap = fuelUsedFromPitstop / lapsSinceRefuel;
          }
        }
      }
    }

    laps.add(lap);

    if (lap.lapNumber > _lastEventLap) {
      _eventController.add(NewLapStartedEvent(lap.lapNumber, previousLap: lastLap));
      _lastEventLap = lap.lapNumber;
    }

    if (lap.position != 0 && lap.position != _lastEventPosition) {
      if (_lastEventPosition != -1) {
        _eventController.add(PositionChangedEvent(_lastEventPosition, lap.position));
      }
      _lastEventPosition = lap.position;
    }

    if (avgConsumptionPerLap > 0) {
      final remainingLaps = lap.fuel / avgConsumptionPerLap;
      if (remainingLaps <= 2.0 &&
          (lap.lapNumber > _lastEventLap ||
              _lastEventFuel == -1 ||
              (lap.fuel < _lastEventFuel - 1))) {
        _eventController.add(LowFuelEvent(lap.fuel, remainingLaps));
        _lastEventFuel = lap.fuel;
      }
    }
  }

  double elapsedTimeMs([int lapNumber = -1]) {
    var totalTimeMs = 0.0;
    for (final lap in laps) {
      if (lap.complete && (lapNumber == -1 || lap.lapNumber <= lapNumber)) {
        totalTimeMs += lap.lapTimeMs;
      }
    }
    return totalTimeMs;
  }

  double estimatedTotalTimeMs(int lapNumber) {
    final average = avgLapTimeMs(lapNumber);
    if (average == 0) {
      return 0;
    }
    return average * raceLaps;
  }

  double estimatedTotalFuelToEnd(int lapNumber) {
    if (avgConsumptionPerLap == 0) {
      return 0;
    }
    return avgConsumptionPerLap * (raceLaps - lapNumber + 1);
  }

  double avgRefuel() {
    if (predictedStints.isEmpty) {
      return 0;
    }
    var totalFuel = 0.0;
    for (final stint in predictedStints) {
      totalFuel += stint.predictedFuelUsed;
    }
    return totalFuel / predictedStints.length;
  }

  double maxRefuel() {
    var maxFuel = 0.0;
    for (final stint in predictedStints) {
      if (stint.predictedFuelUsed > maxFuel) {
        maxFuel = stint.predictedFuelUsed;
      }
    }
    return maxFuel;
  }

  double minRefuel() {
    if (predictedStints.isEmpty) {
      return 0;
    }
    var minFuel = predictedStints.first.predictedFuelUsed;
    for (final stint in predictedStints) {
      if (stint.predictedFuelUsed < minFuel) {
        minFuel = stint.predictedFuelUsed;
      }
    }
    return minFuel;
  }

  double avgLapTimeMs([int lapNumber = -1]) {
    if (laps.isEmpty || lapNumber == 0) {
      return 0;
    }
    final divisor = lapNumber == -1 ? laps.length : lapNumber;
    return elapsedTimeMs(lapNumber) / divisor;
  }

  double distanceFromTargetMs(int lapNumber) {
    final average = avgLapTimeMs(lapNumber);
    if (average == 0 || raceTimeMs == 0) {
      return 0;
    }
    return (average * raceLaps) - raceTimeMs;
  }

  void reset() {
    laps.clear();
    lastRefuelLap = 1;
    _lastEventLap = -1;
    _lastEventPosition = -1;
    _lastEventFuel = -1;
    _raceStartedFired = false;
    avgConsumptionPerLap = 0;
    tankCapacity = 100;
    predictedRefuelQty = -1;
    currentRefuelQty = 100;
    lastLapConsumption = 0;
  }

  void dispose() {
    _eventController.close();
  }

  double _timeToLapMs(int lapNumber) {
    var totalTimeMs = 0.0;
    var lapCount = 0;
    for (final lap in laps) {
      if (lap.complete && lap.lapNumber <= lapNumber) {
        lapCount += 1;
        totalTimeMs += lap.lapTimeMs;
      }
    }
    if (lapCount < lapNumber) {
      totalTimeMs += avgLapTimeMs() * (lapNumber - lapCount);
    }
    return totalTimeMs;
  }

  RaceLap? _lapForNumber(int lapNumber) {
    if (lapNumber >= 0 &&
        lapNumber < laps.length &&
        laps[lapNumber].lapNumber == lapNumber) {
      return laps[lapNumber];
    }

    for (final lap in laps) {
      if (lap.lapNumber == lapNumber) {
        return lap;
      }
    }
    return null;
  }
}
