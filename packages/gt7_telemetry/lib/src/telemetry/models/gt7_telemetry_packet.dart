import 'gt7_vector3.dart';
import 'gt7_wheel_values.dart';

class Gt7TelemetryPacket {
  const Gt7TelemetryPacket({
    required this.packetId,
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.angularVelocity,
    required this.orientation,
    required this.rideHeightMeters,
    required this.engineRpm,
    required this.fuelLevel,
    required this.fuelCapacity,
    required this.speedMps,
    required this.boost,
    required this.oilPressure,
    required this.waterTemperature,
    required this.oilTemperature,
    required this.tireTemperatures,
    required this.currentLap,
    required this.totalLaps,
    required this.bestLapTimeMs,
    required this.lastLapTimeMs,
    required this.timeOfDayMs,
    required this.racePosition,
    required this.totalCars,
    required this.minAlertRpm,
    required this.maxAlertRpm,
    required this.estimatedTopSpeed,
    required this.flags,
    required this.statusFlags,
    required this.motionFlags,
    required this.currentGear,
    required this.suggestedGear,
    required this.throttle,
    required this.brake,
    required this.roadPlane,
    required this.roadPlaneDistance,
    required this.wheelRps,
    required this.tireRadiusMeters,
    required this.suspensionTravelMeters,
    required this.clutchPedal,
    required this.clutchEngagement,
    required this.transmissionRpm,
    required this.transmissionTopSpeed,
    required this.gearRatios,
    required this.carCode,
  });

  final int packetId;
  final Gt7Vector3 position;
  final Gt7Vector3 velocity;
  final Gt7Vector3 rotation;
  final Gt7Vector3 angularVelocity;
  final double orientation;
  final double rideHeightMeters;
  final double engineRpm;
  final double fuelLevel;
  final double fuelCapacity;
  final double speedMps;
  final double boost;
  final double oilPressure;
  final double waterTemperature;
  final double oilTemperature;
  final Gt7WheelValues tireTemperatures;
  final int currentLap;
  final int totalLaps;
  final int bestLapTimeMs;
  final int lastLapTimeMs;
  final int timeOfDayMs;
  final int racePosition;
  final int totalCars;
  final int minAlertRpm;
  final int maxAlertRpm;
  final int estimatedTopSpeed;
  final int flags;
  final int statusFlags;
  final int motionFlags;
  final int currentGear;
  final int suggestedGear;
  final double throttle;
  final double brake;
  final Gt7Vector3 roadPlane;
  final double roadPlaneDistance;
  final Gt7WheelValues wheelRps;
  final Gt7WheelValues tireRadiusMeters;
  final Gt7WheelValues suspensionTravelMeters;
  final double clutchPedal;
  final double clutchEngagement;
  final double transmissionRpm;
  final double transmissionTopSpeed;
  final List<double> gearRatios;
  final int carCode;

  double get speedKph => speedMps * 3.6;

  double get relativeBoost => boost - 1.0;
}
