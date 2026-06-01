import 'package:ps_discovery/ps_discovery.dart';

Future<void> main() async {
  final service = PlaystationDiscoveryService();
  final result = await service.discover();

  if (!result.isDiscovered) {
    print('Discovery status: ${result.status} after ${result.attempts} attempts');
    return;
  }

  final endpoint = result.endpoint!;
  print(
    'Found ${endpoint.rawHostType} at ${endpoint.address.address}'
    '${endpoint.isStandby ? ' (standby)' : ''}',
  );
}
