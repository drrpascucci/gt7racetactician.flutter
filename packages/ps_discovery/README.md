# ps_discovery

Pure Dart PlayStation LAN discovery for GT7 integrations.

## Public API

- `PlaystationDiscoveryService` for broadcast-based discovery with retries
- `PlaystationDiscoveryOptions` for timeout, retry, and port configuration
- `PlaystationDiscoveryEndpoint` and `PlaystationDiscoveryResult` for typed
  discovery outcomes
- `PlaystationDiscoverySocket` for test doubles or custom transport adapters

## Usage

```dart
final service = PlaystationDiscoveryService();
final result = await service.discover();

if (result.isDiscovered) {
  final endpoint = result.endpoint!;
  print('Found ${endpoint.rawHostType} at ${endpoint.address.address}');
}
```

## Reuse notes

- The package is pure Dart and has no Flutter or root-app dependency.
- Default discovery still targets the GT7/PlayStation LAN protocol, but all
  retry and socket behavior can be configured at the package boundary.
- Some Android networks and hotspots filter broadcast traffic, so callers
  should still offer manual IP entry as a fallback when discovery times out.
