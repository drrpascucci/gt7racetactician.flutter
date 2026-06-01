# gt7_telemetry

Pure Dart GT7 telemetry transport and packet decoding.

## Public API

- `Gt7TelemetryClient` for UDP binding, heartbeats, and packet streaming
- `Gt7PacketCodec`, `Gt7PacketDecryptor`, and `Gt7PacketParser` for lower-level
  transport and decoding control
- `Gt7TelemetryPacket`, `Gt7Vector3`, and `Gt7WheelValues` for decoded data
- `Gt7PacketIdFilter` and typed exceptions for dedupe and error handling

## Current protocol subset

The package currently parses packet id, lap/timing, fuel, RPM, throttle/brake,
gears, speed, tire temperatures, tire rotation/radius, suspension travel, car
position/velocity, alert RPMs, and car code.

Track metadata and the less-understood extended packet variants are not covered
yet.

## Reuse notes

- The package is pure Dart and has no dependency on the root Flutter app.
- Networking is isolated behind `dart:io`; callers provide IP addresses and own
  reconnection policy.
- GT7-specific protocol constants remain by design, but no app-workspace
  metadata leaks through the public API anymore.

## Usage

```dart
final client = Gt7TelemetryClient();

await client.bind(
  playstationAddress: InternetAddress('192.168.1.20'),
);

client.packets.listen((packet) {
  print('${packet.packetId}: ${packet.engineRpm} rpm');
});
```
