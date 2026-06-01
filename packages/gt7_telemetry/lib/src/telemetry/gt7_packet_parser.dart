import 'dart:typed_data';

import 'gt7_packet_decryptor.dart';
import 'gt7_packet_exceptions.dart';
import 'models/gt7_telemetry_packet.dart';
import 'models/gt7_vector3.dart';
import 'models/gt7_wheel_values.dart';

class Gt7PacketParser {
  const Gt7PacketParser();

  static const int minimumPacketSize = 0x128;

  Gt7TelemetryPacket parseBytes(List<int> decrypted) {
    final bytes = Uint8List.fromList(decrypted);
    if (bytes.length < minimumPacketSize) {
      throw Gt7InvalidPacketException(
        'GT7 packet is too small to contain the expected telemetry payload.',
      );
    }

    final view = ByteData.sublistView(bytes);
    final magic = view.getUint32(0, Endian.little);
    if (magic != Gt7PacketDecryptor.packetMagic) {
      throw Gt7InvalidPacketException('GT7 packet magic is invalid.');
    }

    final gearData = view.getUint8(0x90);

    return Gt7TelemetryPacket(
      packetId: view.getUint32(0x70, Endian.little),
      position: _vector3(view, 0x04),
      velocity: _vector3(view, 0x10),
      rotation: _vector3(view, 0x1C),
      angularVelocity: _vector3(view, 0x2C),
      orientation: view.getFloat32(0x28, Endian.little),
      rideHeightMeters: view.getFloat32(0x38, Endian.little),
      engineRpm: view.getFloat32(0x3C, Endian.little),
      fuelLevel: view.getFloat32(0x44, Endian.little),
      fuelCapacity: view.getFloat32(0x48, Endian.little),
      speedMps: view.getFloat32(0x4C, Endian.little),
      boost: view.getFloat32(0x50, Endian.little),
      oilPressure: view.getFloat32(0x54, Endian.little),
      waterTemperature: view.getFloat32(0x58, Endian.little),
      oilTemperature: view.getFloat32(0x5C, Endian.little),
      tireTemperatures: _wheelValues(view, 0x60),
      currentLap: view.getInt16(0x74, Endian.little),
      totalLaps: view.getInt16(0x76, Endian.little),
      bestLapTimeMs: view.getInt32(0x78, Endian.little),
      lastLapTimeMs: view.getInt32(0x7C, Endian.little),
      timeOfDayMs: view.getInt32(0x80, Endian.little),
      racePosition: view.getInt16(0x84, Endian.little),
      totalCars: view.getInt16(0x86, Endian.little),
      minAlertRpm: view.getUint16(0x88, Endian.little),
      maxAlertRpm: view.getUint16(0x8A, Endian.little),
      estimatedTopSpeed: view.getInt16(0x8C, Endian.little),
      flags: view.getUint8(0x8E),
      statusFlags: view.getUint8(0x8F),
      motionFlags: view.getUint8(0x93),
      currentGear: gearData & 0x0F,
      suggestedGear: gearData >> 4,
      throttle: view.getUint8(0x91) / 255.0,
      brake: view.getUint8(0x92) / 255.0,
      roadPlane: _vector3(view, 0x94),
      roadPlaneDistance: view.getFloat32(0xA0, Endian.little),
      wheelRps: _wheelValues(view, 0xA4),
      tireRadiusMeters: _wheelValues(view, 0xB4),
      suspensionTravelMeters: _wheelValues(view, 0xC4),
      clutchPedal: view.getFloat32(0xF4, Endian.little),
      clutchEngagement: view.getFloat32(0xF8, Endian.little),
      transmissionRpm: view.getFloat32(0xFC, Endian.little),
      transmissionTopSpeed: view.getFloat32(0x100, Endian.little),
      gearRatios: List<double>.unmodifiable([
        view.getFloat32(0x104, Endian.little),
        view.getFloat32(0x108, Endian.little),
        view.getFloat32(0x10C, Endian.little),
        view.getFloat32(0x110, Endian.little),
        view.getFloat32(0x114, Endian.little),
        view.getFloat32(0x118, Endian.little),
        view.getFloat32(0x11C, Endian.little),
        view.getFloat32(0x120, Endian.little),
      ]),
      carCode: view.getInt32(0x124, Endian.little),
    );
  }

  Gt7Vector3 _vector3(ByteData view, int offset) {
    return Gt7Vector3(
      x: view.getFloat32(offset, Endian.little),
      y: view.getFloat32(offset + 4, Endian.little),
      z: view.getFloat32(offset + 8, Endian.little),
    );
  }

  Gt7WheelValues _wheelValues(ByteData view, int offset) {
    return Gt7WheelValues(
      frontLeft: view.getFloat32(offset, Endian.little),
      frontRight: view.getFloat32(offset + 4, Endian.little),
      rearLeft: view.getFloat32(offset + 8, Endian.little),
      rearRight: view.getFloat32(offset + 12, Endian.little),
    );
  }
}
