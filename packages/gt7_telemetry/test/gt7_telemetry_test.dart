import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:gt7_telemetry/gt7_telemetry.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/stream/salsa20.dart';
import 'package:test/test.dart';

void main() {
  group('public API', () {
    test('exports the core telemetry types', () {
      expect(Gt7TelemetryClient.defaultSendPort, 33739);
      expect(Gt7TelemetryClient.defaultReceivePort, 33740);
      expect(Gt7TelemetryClient.heartbeatPayload, 'A');
      expect(Gt7PacketParser.minimumPacketSize, 0x128);
    });
  });

  group('Gt7PacketDecryptor', () {
    test('decrypts a GT7 Salsa20 packet', () {
      final expected = _preparePlaintextForEncryption(
        _buildPlainPacket(packetId: 41),
        seed: 0x11223344,
      );
      final encrypted = _encryptGt7Packet(expected, seed: 0x11223344);

      final decrypted = const Gt7PacketDecryptor().decryptBytes(encrypted);

      expect(decrypted, orderedEquals(expected));
    });

    test('rejects invalid packet magic', () {
      final encrypted = Uint8List(0x80);
      final view = ByteData.sublistView(encrypted);
      view.setUint32(0x40, 0xAABBCCDD, Endian.little);

      expect(
        () => const Gt7PacketDecryptor().decryptBytes(encrypted),
        throwsA(isA<Gt7PacketDecryptionException>()),
      );
    });
  });

  group('Gt7PacketParser', () {
    test('parses the documented telemetry subset', () {
      final packet = const Gt7PacketParser().parseBytes(
        _buildPlainPacket(packetId: 77),
      );

      expect(packet.packetId, 77);
      expect(packet.currentLap, 3);
      expect(packet.totalLaps, 12);
      expect(packet.engineRpm, closeTo(7123.0, 0.001));
      expect(packet.speedKph, closeTo(198.0, 0.001));
      expect(packet.fuelLevel, closeTo(42.5, 0.001));
      expect(packet.minAlertRpm, 6500);
      expect(packet.maxAlertRpm, 7800);
      expect(packet.currentGear, 4);
      expect(packet.suggestedGear, 5);
      expect(packet.tireTemperatures.frontLeft, closeTo(76.5, 0.001));
      expect(packet.tireTemperatures.rearRight, closeTo(79.5, 0.001));
      expect(packet.gearRatios, hasLength(8));
      expect(packet.carCode, 123456);
    });
  });

  group('Gt7PacketIdFilter', () {
    test('rejects duplicates and old packets but accepts rollover', () {
      final filter = Gt7PacketIdFilter();

      expect(filter.shouldAccept(100), isTrue);
      expect(filter.shouldAccept(100), isFalse);
      expect(filter.shouldAccept(99), isFalse);
      expect(filter.shouldAccept(101), isTrue);

      filter.reset();
      expect(filter.shouldAccept(0xFFFFFFFE), isTrue);
      expect(filter.shouldAccept(0xFFFFFFFF), isTrue);
      expect(filter.shouldAccept(0), isTrue);
      expect(filter.shouldAccept(0xFFFFFFFF), isFalse);
    });
  });

  group('Gt7TelemetryClient', () {
    test('receives UDP packets and dedupes by packet id', () async {
      final client = Gt7TelemetryClient();
      final sender = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );

      addTearDown(() async {
        sender.close();
        client.dispose();
      });

      await client.bind(
        bindAddress: InternetAddress.loopbackIPv4,
        receivePort: 0,
      );

      final receivedPackets = client.packets
          .map((packet) => packet.packetId)
          .take(2)
          .toList();

      final targetPort = client.localPort!;
      sender.send(
        _encryptGt7Packet(_buildPlainPacket(packetId: 41), seed: 0x10101010),
        InternetAddress.loopbackIPv4,
        targetPort,
      );
      sender.send(
        _encryptGt7Packet(_buildPlainPacket(packetId: 41), seed: 0x20202020),
        InternetAddress.loopbackIPv4,
        targetPort,
      );
      sender.send(
        _encryptGt7Packet(_buildPlainPacket(packetId: 42), seed: 0x30303030),
        InternetAddress.loopbackIPv4,
        targetPort,
      );

      expect(await receivedPackets, [41, 42]);
    });
  });
}

Uint8List _buildPlainPacket({required int packetId}) {
  final bytes = Uint8List(Gt7PacketParser.minimumPacketSize);
  final view = ByteData.sublistView(bytes);

  view.setUint32(0x00, Gt7PacketDecryptor.packetMagic, Endian.little);

  view.setFloat32(0x04, 1.5, Endian.little);
  view.setFloat32(0x08, 2.5, Endian.little);
  view.setFloat32(0x0C, 3.5, Endian.little);
  view.setFloat32(0x10, 4.5, Endian.little);
  view.setFloat32(0x14, 5.5, Endian.little);
  view.setFloat32(0x18, 6.5, Endian.little);
  view.setFloat32(0x1C, 0.1, Endian.little);
  view.setFloat32(0x20, 0.2, Endian.little);
  view.setFloat32(0x24, 0.3, Endian.little);
  view.setFloat32(0x28, 0.4, Endian.little);
  view.setFloat32(0x2C, 0.6, Endian.little);
  view.setFloat32(0x30, 0.7, Endian.little);
  view.setFloat32(0x34, 0.8, Endian.little);
  view.setFloat32(0x38, 0.09, Endian.little);
  view.setFloat32(0x3C, 7123.0, Endian.little);
  view.setFloat32(0x44, 42.5, Endian.little);
  view.setFloat32(0x48, 100.0, Endian.little);
  view.setFloat32(0x4C, 55.0, Endian.little);
  view.setFloat32(0x50, 1.15, Endian.little);
  view.setFloat32(0x54, 5.4, Endian.little);
  view.setFloat32(0x58, 92.0, Endian.little);
  view.setFloat32(0x5C, 104.0, Endian.little);
  view.setFloat32(0x60, 76.5, Endian.little);
  view.setFloat32(0x64, 77.5, Endian.little);
  view.setFloat32(0x68, 78.5, Endian.little);
  view.setFloat32(0x6C, 79.5, Endian.little);
  view.setUint32(0x70, packetId, Endian.little);
  view.setInt16(0x74, 3, Endian.little);
  view.setInt16(0x76, 12, Endian.little);
  view.setInt32(0x78, 91321, Endian.little);
  view.setInt32(0x7C, 92750, Endian.little);
  view.setInt32(0x80, 12345678, Endian.little);
  view.setInt16(0x84, 5, Endian.little);
  view.setInt16(0x86, 16, Endian.little);
  view.setUint16(0x88, 6500, Endian.little);
  view.setUint16(0x8A, 7800, Endian.little);
  view.setInt16(0x8C, 290, Endian.little);
  view.setUint8(0x8E, 0xA5);
  view.setUint8(0x8F, 0x5A);
  view.setUint8(0x90, 0x54);
  view.setUint8(0x91, 204);
  view.setUint8(0x92, 26);
  view.setUint8(0x93, 0x03);
  view.setFloat32(0x94, 0.11, Endian.little);
  view.setFloat32(0x98, 0.22, Endian.little);
  view.setFloat32(0x9C, 0.33, Endian.little);
  view.setFloat32(0xA0, 0.44, Endian.little);
  view.setFloat32(0xA4, 10.1, Endian.little);
  view.setFloat32(0xA8, 10.2, Endian.little);
  view.setFloat32(0xAC, 10.3, Endian.little);
  view.setFloat32(0xB0, 10.4, Endian.little);
  view.setFloat32(0xB4, 0.31, Endian.little);
  view.setFloat32(0xB8, 0.32, Endian.little);
  view.setFloat32(0xBC, 0.33, Endian.little);
  view.setFloat32(0xC0, 0.34, Endian.little);
  view.setFloat32(0xC4, 0.01, Endian.little);
  view.setFloat32(0xC8, 0.02, Endian.little);
  view.setFloat32(0xCC, 0.03, Endian.little);
  view.setFloat32(0xD0, 0.04, Endian.little);
  view.setFloat32(0xF4, 0.55, Endian.little);
  view.setFloat32(0xF8, 0.66, Endian.little);
  view.setFloat32(0xFC, 3500.0, Endian.little);
  view.setFloat32(0x100, 310.0, Endian.little);
  view.setFloat32(0x104, 3.1, Endian.little);
  view.setFloat32(0x108, 2.2, Endian.little);
  view.setFloat32(0x10C, 1.7, Endian.little);
  view.setFloat32(0x110, 1.35, Endian.little);
  view.setFloat32(0x114, 1.1, Endian.little);
  view.setFloat32(0x118, 0.95, Endian.little);
  view.setFloat32(0x11C, 0.82, Endian.little);
  view.setFloat32(0x120, 0.74, Endian.little);
  view.setInt32(0x124, 123456, Endian.little);

  return bytes;
}

Uint8List _encryptGt7Packet(Uint8List plaintext, {required int seed}) {
  final adjustedPlaintext = _preparePlaintextForEncryption(
    plaintext,
    seed: seed,
  );

  final encryptionEngine = Salsa20Engine()
    ..init(
      true,
      ParametersWithIV<KeyParameter>(KeyParameter(_gt7Key), _gt7Nonce(seed)),
    );
  final encrypted = Uint8List(adjustedPlaintext.length);
  encryptionEngine.processBytes(
    adjustedPlaintext,
    0,
    adjustedPlaintext.length,
    encrypted,
    0,
  );

  return encrypted;
}

Uint8List _preparePlaintextForEncryption(
  Uint8List plaintext, {
  required int seed,
}) {
  final keystreamEngine = Salsa20Engine()
    ..init(
      true,
      ParametersWithIV<KeyParameter>(KeyParameter(_gt7Key), _gt7Nonce(seed)),
    );
  final keystream = Uint8List(plaintext.length);
  keystreamEngine.processBytes(
    Uint8List(plaintext.length),
    0,
    plaintext.length,
    keystream,
    0,
  );

  final adjustedPlaintext = Uint8List.fromList(plaintext);
  adjustedPlaintext[0x40] = seed & 0xFF ^ keystream[0x40];
  adjustedPlaintext[0x41] = (seed >> 8) & 0xFF ^ keystream[0x41];
  adjustedPlaintext[0x42] = (seed >> 16) & 0xFF ^ keystream[0x42];
  adjustedPlaintext[0x43] = (seed >> 24) & 0xFF ^ keystream[0x43];
  return adjustedPlaintext;
}

Uint8List _gt7Nonce(int seed) {
  final nonce = Uint8List(8);
  final nonceView = ByteData.sublistView(nonce);
  nonceView.setUint32(0, seed ^ Gt7PacketDecryptor.seedMask, Endian.little);
  nonceView.setUint32(4, seed, Endian.little);
  return nonce;
}

final Uint8List _gt7Key = Uint8List.fromList(
  ascii.encode('Simulator Interface Packet GT7 ver 0.0').sublist(0, 32),
);
