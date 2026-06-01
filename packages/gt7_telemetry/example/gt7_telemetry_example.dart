import 'dart:io';

import 'package:gt7_telemetry/gt7_telemetry.dart';

Future<void> main() async {
  final client = Gt7TelemetryClient();

  await client.bind(playstationAddress: InternetAddress('192.168.1.20'));

  final subscription = client.packets.listen((packet) {
    stdout.writeln(
      'Packet ${packet.packetId}: lap ${packet.currentLap}, '
      '${packet.engineRpm.toStringAsFixed(0)} rpm',
    );
  });

  await Future<void>.delayed(const Duration(seconds: 5));
  await subscription.cancel();
  client.dispose();
}
