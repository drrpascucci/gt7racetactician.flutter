import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_domain/gt7_domain.dart';
import 'package:gt7_telemetry/gt7_telemetry.dart';
import 'package:gt7_telemetry_app/app/config/app_config.dart';
import 'package:gt7_telemetry_app/app/config/app_config_service.dart';
import 'package:gt7_telemetry_app/app/runtime/app_runtime_controller.dart';
import 'package:gt7_telemetry_app/app/runtime/app_runtime_models.dart';
import 'package:ps_discovery/ps_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfigService', () {
    test('loads and normalizes stored config values', () async {
      final store = MemoryAppConfigStore();
      await store.write(
        AppConfig.defaults()
            .copyWith(
              trackName: 'Spa',
              raceType: RaceType.timeRace,
              targetLaps: 18,
              targetRaceTime: Duration(minutes: 30),
              pitLaneTime: Duration(seconds: 42),
              shiftPercentage: 85,
              manualPlaystationIp: ' 192.168.0.12 ',
            )
            .toJson(),
      );

      final service = AppConfigService(store: store);
      await service.load();

      expect(service.config.trackName, 'Spa');
      expect(service.config.raceType, RaceType.timeRace);
      expect(service.config.targetLaps, 18);
      expect(service.config.targetRaceTime, const Duration(minutes: 30));
      expect(service.config.pitLaneTime, const Duration(seconds: 42));
      expect(service.config.shiftPercentage, 85);
      expect(service.config.normalizedManualPlaystationIp, '192.168.0.12');
    });
  });

  group('AppRuntimeController', () {
    test('binds to a manual IP and builds lap-aware race state', () async {
      final configService = AppConfigService(
        initialConfig: AppConfig.defaults().copyWith(
          trackName: 'Suzuka',
          targetLaps: 5,
          targetRaceTime: Duration(minutes: 10),
        ),
      );
      final discovery = FakeDiscoveryGateway();
      final telemetry = FakeTelemetryGateway();
      final controller = AppRuntimeController(
        configService: configService,
        discoveryGateway: discovery,
        telemetryGateway: telemetry,
        slowRefreshInterval: const Duration(milliseconds: 5),
        telemetryRefreshInterval: Duration.zero,
      );

      addTearDown(controller.dispose);
      await controller.initialize();

      expect(discovery.calls, 0);
      expect(telemetry.bindCalls, 0);
      expect(controller.connectionState.phase, RuntimeConnectionPhase.idle);

      await controller.selectManualPlaystation('192.168.0.42');
      expect(controller.connectionState.phase, RuntimeConnectionPhase.stopped);

      await controller.startTelemetry();
      expect(telemetry.boundAddresses.single.address, '192.168.0.42');
      expect(
        controller.connectionState.phase,
        RuntimeConnectionPhase.connecting,
      );

      telemetry.emit(_packet(packetId: 1, currentLap: 1, fuelLevel: 90));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      telemetry.emit(
        _packet(
          packetId: 2,
          currentLap: 2,
          lastLapTimeMs: 90000,
          fuelLevel: 80,
          tireTemperatures: const Gt7WheelValues(
            frontLeft: 74,
            frontRight: 75,
            rearLeft: 82,
            rearRight: 83,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      telemetry.emit(
        _packet(
          packetId: 3,
          currentLap: 2,
          lastLapTimeMs: 90000,
          fuelLevel: 60,
          tireTemperatures: const Gt7WheelValues(
            frontLeft: 71,
            frontRight: 78,
            rearLeft: 86,
            rearRight: 81,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.connectionState.phase, RuntimeConnectionPhase.live);
      expect(controller.telemetryState.value.currentLap, 2);
      expect(controller.raceState.value.completedLapCount, 1);
      expect(controller.raceState.value.lastCompletedLap?.lapTimeMs, 90000);
      expect(controller.raceState.value.averageLapTimeMs, 90000);
      expect(controller.raceState.value.averageConsumptionPerLap, 20);
      expect(controller.raceState.value.currentLapNumber, 2);
      expect(controller.raceState.value.estimatedTotalTimeMs, 450000);
      expect(controller.raceState.value.distanceFromTargetMs, -150000);
      expect(
        controller.telemetryState.value.minimumTireTemperatures.frontLeft,
        71,
      );
      expect(
        controller.telemetryState.value.maximumTireTemperatures.rearLeft,
        86,
      );
    });

    test('restarts discovery around lifecycle pause and resume', () async {
      final configService = AppConfigService();
      final discovery = FakeDiscoveryGateway(
        result: PlaystationDiscoveryResult.discovered(
          endpoint: PlaystationDiscoveryEndpoint(
            address: InternetAddress('10.0.0.5'),
            consoleType: PlaystationConsoleType.ps5,
            rawHostType: 'PS5',
            responseCode: 200,
            isStandby: false,
          ),
          attempts: 1,
          elapsed: const Duration(milliseconds: 25),
        ),
      );
      final telemetry = FakeTelemetryGateway();
      final controller = AppRuntimeController(
        configService: configService,
        discoveryGateway: discovery,
        telemetryGateway: telemetry,
        slowRefreshInterval: const Duration(milliseconds: 5),
        telemetryRefreshInterval: Duration.zero,
      );

      addTearDown(controller.dispose);
      await controller.initialize();

      expect(discovery.calls, 0);

      await controller.discoverPlaystation();
      expect(discovery.calls, 1);
      expect(controller.connectionState.phase, RuntimeConnectionPhase.stopped);

      await controller.startTelemetry();
      expect(telemetry.boundAddresses.single.address, '10.0.0.5');

      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.connectionState.phase, RuntimeConnectionPhase.paused);
      expect(telemetry.closeCalls, greaterThanOrEqualTo(1));

      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(discovery.calls, 1);
      expect(telemetry.bindCalls, 2);
    });

    test(
      'coalesces telemetry view updates to the configured cadence',
      () async {
        final configService = AppConfigService(
          initialConfig: AppConfig.defaults().copyWith(
            manualPlaystationIp: '192.168.0.42',
          ),
        );
        final telemetry = FakeTelemetryGateway();
        final controller = AppRuntimeController(
          configService: configService,
          telemetryGateway: telemetry,
          slowRefreshInterval: const Duration(milliseconds: 5),
          telemetryRefreshInterval: const Duration(milliseconds: 80),
        );

        addTearDown(controller.dispose);
        await controller.initialize();
        await controller.selectManualPlaystation('192.168.0.42');
        await controller.startTelemetry();

        var telemetryNotifications = 0;
        controller.telemetryState.addListener(() {
          telemetryNotifications += 1;
        });

        telemetry.emit(_packet(packetId: 1, currentLap: 1, fuelLevel: 92));
        telemetry.emit(_packet(packetId: 2, currentLap: 1, fuelLevel: 90));
        telemetry.emit(_packet(packetId: 3, currentLap: 1, fuelLevel: 88));

        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(telemetryNotifications, 0);

        await Future<void>.delayed(const Duration(milliseconds: 90));
        expect(telemetryNotifications, 1);
        expect(controller.telemetryState.value.packet?.packetId, 3);
        expect(controller.telemetryState.value.packetsReceived, 3);
      },
    );

    test(
      'does not bind telemetry when discovery finds a standby console',
      () async {
        final configService = AppConfigService();
        final discovery = FakeDiscoveryGateway(
          result: PlaystationDiscoveryResult.discovered(
            endpoint: PlaystationDiscoveryEndpoint(
              address: InternetAddress('10.0.0.8'),
              consoleType: PlaystationConsoleType.ps5,
              rawHostType: 'PS5',
              responseCode: 620,
              isStandby: true,
            ),
            attempts: 1,
            elapsed: const Duration(milliseconds: 25),
          ),
        );
        final telemetry = FakeTelemetryGateway();
        final controller = AppRuntimeController(
          configService: configService,
          discoveryGateway: discovery,
          telemetryGateway: telemetry,
        );

        addTearDown(controller.dispose);
        await controller.initialize();
        await controller.discoverPlaystation();

        expect(telemetry.bindCalls, 0);
        expect(controller.connectionState.phase, RuntimeConnectionPhase.error);
        expect(
          controller.connectionState.playstationAddress?.address,
          '10.0.0.8',
        );
        expect(controller.telemetryState.value.usingManualAddress, isFalse);
        expect(
          controller.telemetryState.value.errorMessage,
          'Wake the PlayStation, then reconnect.',
        );
      },
    );

    test('stops telemetry without losing the selected console', () async {
      final controller = AppRuntimeController(
        configService: AppConfigService(),
        telemetryGateway: FakeTelemetryGateway(),
      );

      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.selectManualPlaystation('192.168.0.42');
      await controller.startTelemetry();
      await controller.stopTelemetry();

      expect(controller.hasSelectedPlaystation, isTrue);
      expect(controller.connectionState.phase, RuntimeConnectionPhase.stopped);
      expect(
        controller.connectionState.playstationAddress?.address,
        '192.168.0.42',
      );
    });
  });
}

class FakeDiscoveryGateway implements DiscoveryGateway {
  FakeDiscoveryGateway({PlaystationDiscoveryResult? result})
    : result =
          result ??
          PlaystationDiscoveryResult.timedOut(
            attempts: 1,
            elapsed: const Duration(milliseconds: 1),
          );

  final PlaystationDiscoveryResult result;
  int calls = 0;

  @override
  Future<PlaystationDiscoveryResult> discover({
    PlaystationDiscoveryOptions options = const PlaystationDiscoveryOptions(),
  }) async {
    calls += 1;
    return result;
  }
}

class FakeTelemetryGateway implements TelemetryGateway {
  final StreamController<Gt7TelemetryPacket> _controller =
      StreamController<Gt7TelemetryPacket>.broadcast();
  final List<InternetAddress> boundAddresses = <InternetAddress>[];
  int bindCalls = 0;
  int closeCalls = 0;

  @override
  Stream<Gt7TelemetryPacket> get packets => _controller.stream;

  @override
  Stream<Uint8List>? get rawPackets => null;

  @override
  int? get localPort => 33740;

  @override
  Future<void> bind({
    InternetAddress? playstationAddress,
    InternetAddress? bindAddress,
    int receivePort = Gt7TelemetryClient.defaultReceivePort,
    int sendPort = Gt7TelemetryClient.defaultSendPort,
    Duration heartbeatInterval = const Duration(seconds: 1),
  }) async {
    bindCalls += 1;
    if (playstationAddress != null) {
      boundAddresses.add(playstationAddress);
    }
  }

  @override
  Future<void> close() async {
    closeCalls += 1;
  }

  @override
  void dispose() {
    unawaited(_controller.close());
  }

  void emit(Gt7TelemetryPacket packet) {
    _controller.add(packet);
  }
}

Gt7TelemetryPacket _packet({
  required int packetId,
  required int currentLap,
  int totalLaps = 5,
  int lastLapTimeMs = 0,
  double fuelLevel = 100,
  Gt7WheelValues? tireTemperatures,
}) {
  const zeroVector = Gt7Vector3(x: 0, y: 0, z: 0);
  const zeroWheels = Gt7WheelValues(
    frontLeft: 0,
    frontRight: 0,
    rearLeft: 0,
    rearRight: 0,
  );

  return Gt7TelemetryPacket(
    packetId: packetId,
    position: zeroVector,
    velocity: zeroVector,
    rotation: zeroVector,
    angularVelocity: zeroVector,
    orientation: 0,
    rideHeightMeters: 0,
    engineRpm: 7200,
    fuelLevel: fuelLevel,
    fuelCapacity: 100,
    speedMps: 50,
    boost: 1,
    oilPressure: 0,
    waterTemperature: 0,
    oilTemperature: 0,
    tireTemperatures: tireTemperatures ?? zeroWheels,
    currentLap: currentLap,
    totalLaps: totalLaps,
    bestLapTimeMs: lastLapTimeMs,
    lastLapTimeMs: lastLapTimeMs,
    timeOfDayMs: 0,
    racePosition: 3,
    totalCars: 16,
    minAlertRpm: 6500,
    maxAlertRpm: 7800,
    estimatedTopSpeed: 280,
    flags: 0,
    statusFlags: 0,
    motionFlags: 0,
    currentGear: 4,
    suggestedGear: 5,
    throttle: 0.8,
    brake: 0,
    roadPlane: zeroVector,
    roadPlaneDistance: 0,
    wheelRps: zeroWheels,
    tireRadiusMeters: zeroWheels,
    suspensionTravelMeters: zeroWheels,
    clutchPedal: 0,
    clutchEngagement: 0,
    transmissionRpm: 3500,
    transmissionTopSpeed: 310,
    gearRatios: const [3.1, 2.2, 1.7, 1.35, 1.1, 0.95],
    carCode: 123456,
  );
}
