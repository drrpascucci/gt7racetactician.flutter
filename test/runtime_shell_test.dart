import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_design_system/gt7_design_system.dart';
import 'package:gt7_domain/gt7_domain.dart';
import 'package:gt7_telemetry/gt7_telemetry.dart';
import 'package:gt7_race_tactitian/app/config/app_config.dart';
import 'package:gt7_race_tactitian/app/config/app_config_service.dart';
import 'package:gt7_race_tactitian/app/runtime/app_runtime_controller.dart';
import 'package:gt7_race_tactitian/app/runtime/app_runtime_models.dart';
import 'package:gt7_race_tactitian/app/runtime/runtime_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'shows discovery first, then renders the dashboard after console selection',
    (tester) async {
      final controller = await _pumpRuntimeShell(
        tester,
        physicalSize: const Size(1920, 1600),
      );

      expect(find.text('Enter IP or search for PlayStation'), findsOneWidget);
      expect(find.text('Search PS'), findsOneWidget);
      expect(find.text("Let's GO!"), findsOneWidget);
      await _seedDashboardState(tester, controller);

      expect(tester.takeException(), isNull);
      final viewportHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final trackField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Track name',
      );

      expect(find.text('GT7 Race Tactician'), findsOneWidget);
      expect(find.textContaining('RPM'), findsOneWidget);
      expect(find.text('START'), findsNothing);
      expect(find.text('Reconnect'), findsNothing);
      expect(find.text('Reset'), findsNothing);
      expect(find.byTooltip('Start telemetry'), findsOneWidget);
      expect(find.byTooltip('Reconnect'), findsOneWidget);
      expect(find.byTooltip('Reset session'), findsOneWidget);
      expect(find.textContaining('192.168.0.42'), findsOneWidget);
      expect(find.text('Race settings'), findsNothing);
      expect(find.text('Connection settings'), findsNothing);
      expect(find.text('Apply manual IP'), findsNothing);
      expect(trackField, findsNothing);
      expect(find.text('Strategy'), findsOneWidget);
      expect(find.text('Last laps'), findsOneWidget);
      expect(find.text('FL'), findsOneWidget);
      expect(
        tester.getRect(find.byTooltip('Start telemetry')).bottom,
        lessThanOrEqualTo(viewportHeight),
      );
      expect(
        tester.getRect(find.text('Last laps')).bottom,
        lessThanOrEqualTo(viewportHeight),
      );
      expect(
        tester.getRect(find.text('FL')).bottom,
        lessThanOrEqualTo(viewportHeight),
      );
      final openSettingsButton = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byTooltip('Open settings'),
          matching: find.byType(ElevatedButton),
        ),
      );
      openSettingsButton.onPressed!.call();
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Session setup'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Race settings'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Race settings'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Connection settings'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Connection settings'), findsOneWidget);
      expect(find.text('Apply manual IP'), findsOneWidget);
      expect(trackField, findsOneWidget);

      controller.dispose();
      await tester.pump();
    },
  );

  testWidgets('keeps primary dashboard blocks readable on compact widths', (
    tester,
  ) async {
    final controller = await _pumpDashboardShell(
      tester,
      physicalSize: const Size(1440, 1800),
    );

    expect(tester.takeException(), isNull);

    expect(find.textContaining('RPM'), findsOneWidget);
    expect(find.byTooltip('Start telemetry'), findsOneWidget);
    expect(find.text('Strategy'), findsOneWidget);
    expect(find.text('Last laps'), findsOneWidget);
    expect(find.text('FL'), findsOneWidget);

    controller.dispose();
    await tester.pump();
  });

  testWidgets('keeps tyre temps in a value-only 2x2 grid on narrow screens', (
    tester,
  ) async {
    final controller = await _pumpDashboardShell(
      tester,
      physicalSize: const Size(720, 1800),
    );

    await tester.pumpAndSettle();

    final fl = tester.getTopLeft(find.text('73.0°'));
    final fr = tester.getTopLeft(find.text('74.0°'));
    final rl = tester.getTopLeft(find.text('89.0°'));
    final rr = tester.getTopLeft(find.text('90.0°'));

    expect(fr.dx, greaterThan(fl.dx));
    expect(rl.dy, greaterThan(fl.dy));
    expect(rr.dx, greaterThan(rl.dx));
    expect(rr.dy, greaterThan(fr.dy));
    expect(find.text('FL'), findsOneWidget);
    expect(find.text('FR'), findsOneWidget);
    expect(find.text('RL'), findsOneWidget);
    expect(find.text('RR'), findsOneWidget);
    expect(find.text('MIN'), findsNothing);
    expect(find.text('MAX'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('L 71.0°  H 77.0°'),
      ),
      findsNothing,
    );

    controller.dispose();
    await tester.pump();
  });

  testWidgets('hides tyre min/max entirely on very tight screens', (
    tester,
  ) async {
    final controller = await _pumpDashboardShell(
      tester,
      physicalSize: const Size(560, 1800),
    );

    await tester.pumpAndSettle();

    expect(find.text('FL'), findsOneWidget);
    expect(find.text('FR'), findsOneWidget);
    expect(find.text('RL'), findsOneWidget);
    expect(find.text('RR'), findsOneWidget);
    expect(find.text('MIN'), findsNothing);
    expect(find.text('MAX'), findsNothing);
    expect(find.text('73.0°'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('L 71.0°  H 77.0°'),
      ),
      findsNothing,
    );

    controller.dispose();
    await tester.pump();
  });

  testWidgets(
    'compresses controls and hides numeric RPM before the LED bar on narrow widths',
    (tester) async {
      final controller = await _pumpDashboardShell(
        tester,
        physicalSize: const Size(720, 1800),
      );
      final viewportHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      expect(tester.takeException(), isNull);

      expect(find.byKey(const ValueKey('gt7-led-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('gt7-led-9')), findsOneWidget);
      expect(find.text('7350'), findsNothing);
      expect(find.text('RPM'), findsNothing);
      expect(find.text('START'), findsNothing);
      expect(find.byTooltip('Start telemetry'), findsOneWidget);
      expect(find.text('Reconnect'), findsNothing);
      expect(find.byTooltip('Reconnect'), findsOneWidget);
      expect(find.text('Reset'), findsNothing);
      expect(find.byTooltip('Reset session'), findsOneWidget);
      expect(find.text('Change PlayStation'), findsNothing);
      expect(find.byTooltip('Change PlayStation'), findsOneWidget);
      expect(find.text('Open settings'), findsNothing);
      expect(find.byTooltip('Open settings'), findsOneWidget);
      expect(find.textContaining('192.168.0.42'), findsNothing);
      expect(find.textContaining('packets'), findsNothing);
      expect(find.text('Speed'), findsNothing);
      expect(find.text('Gear'), findsNothing);
      expect(find.text('Position'), findsNothing);
      expect(find.text('Recent laps first...'), findsNothing);
      expect(find.text('2x2 live layout'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              RegExp(r'\b4\s*/\s*12\b').hasMatch(widget.text.toPlainText()),
        ),
        findsNothing,
      );
      expect(
        tester.getRect(find.byTooltip('Start telemetry')).bottom,
        lessThanOrEqualTo(viewportHeight),
      );
      expect(
        tester.getRect(find.text('Strategy')).bottom,
        lessThanOrEqualTo(viewportHeight),
      );
      expect(
        tester.getRect(find.text('Last laps')).bottom,
        lessThanOrEqualTo(viewportHeight),
      );

      controller.dispose();
      await tester.pump();
    },
  );

  testWidgets('compresses the lap table on narrow, short screens', (
    tester,
  ) async {
    final controller = await _pumpDashboardShell(
      tester,
      physicalSize: const Size(760, 1280),
    );

    await _setLapHistory(
      tester,
      controller,
      laps: [
        RaceLap(
          lapNumber: 1,
          fuel: 92,
          lapTimeMs: 97000,
          position: 4,
          complete: true,
          targetTimeMs: 96000,
        ),
        RaceLap(
          lapNumber: 2,
          fuel: 84,
          lapTimeMs: 96800,
          position: 3,
          complete: true,
          targetTimeMs: 96000,
        ),
        RaceLap(
          lapNumber: 3,
          fuel: 76,
          lapTimeMs: 96500,
          position: 3,
          complete: true,
          targetTimeMs: 96000,
        ),
        RaceLap(
          lapNumber: 4,
          fuel: 68,
          lapTimeMs: 96000,
          position: 2,
          complete: true,
          targetTimeMs: 96000,
        ),
        RaceLap(
          lapNumber: 5,
          fuel: 60,
          lapTimeMs: 94300,
          position: 2,
          complete: true,
          targetTimeMs: 96000,
        ),
        RaceLap(
          lapNumber: 6,
          fuel: 52,
          lapTimeMs: 93800,
          position: 2,
          complete: true,
          targetTimeMs: 96000,
        ),
        RaceLap(
          lapNumber: 7,
          fuel: 45,
          lapTimeMs: 34200,
          position: 2,
          complete: false,
          targetTimeMs: 96000,
        ),
      ],
    );

    expect(find.text('Lap'), findsOneWidget);
    expect(find.text('Pos'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Avg Δ'), findsOneWidget);
    expect(find.text('Race Δ'), findsOneWidget);
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('State'), findsNothing);
    expect(find.text('Info'), findsNothing);
    expect(find.text('7*'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);

    controller.dispose();
    await tester.pump();
  });

  testWidgets('double-tap on main area toggles to smartphone mode', (
    tester,
  ) async {
    final controller = await _pumpDashboardShell(
      tester,
      physicalSize: const Size(1440, 1800),
    );

    // Tablet mode default: lap table visible
    expect(find.text('Last laps'), findsOneWidget);
    expect(find.text('LAST'), findsNothing);
    expect(find.text('DRIVER ASSIST'), findsOneWidget);

    // Switch to smartphone mode via config (same effect as double-tap)
    await controller.updateConfig(
      controller.configService.config.copyWith(
        viewMode: DashboardViewMode.smartphone,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last laps'), findsNothing);
    expect(find.text('LAST'), findsOneWidget);
    expect(find.text('AVG'), findsOneWidget);
    expect(find.text('DRIVER ASSIST'), findsNothing);

    // Switch back to tablet mode
    await controller.updateConfig(
      controller.configService.config.copyWith(
        viewMode: DashboardViewMode.tablet,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last laps'), findsOneWidget);
    expect(find.text('LAST'), findsNothing);
    expect(find.text('DRIVER ASSIST'), findsOneWidget);

    controller.dispose();
    await tester.pump();
  });

  testWidgets('smartphone mode shows pace indicator and fuel boxes', (
    tester,
  ) async {
    final controller = await _pumpRuntimeShell(
      tester,
      physicalSize: const Size(1440, 1800),
    );
    await _seedDashboardState(tester, controller);

    await controller.updateConfig(
      controller.configService.config.copyWith(
        viewMode: DashboardViewMode.smartphone,
      ),
    );
    await tester.pumpAndSettle();

    // Lap table hidden, smartphone grid visible
    expect(find.text('Last laps'), findsNothing);
    expect(find.text('LAST'), findsOneWidget);
    expect(find.text('AVG'), findsOneWidget);
    expect(find.text('DRIVER ASSIST'), findsNothing);
    // Tyre section integrated in grid
    expect(find.text('FL'), findsOneWidget);
    // Fuel/stop boxes present
    expect(find.text('NEXT STOP'), findsOneWidget);
    expect(find.text('TOT STOPS'), findsOneWidget);

    controller.dispose();
    await tester.pump();
  });
}

Future<AppRuntimeController> _pumpRuntimeShell(
  WidgetTester tester, {
  required Size physicalSize,
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 2;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final config = AppConfig.defaults().copyWith(
    trackName: 'Tokyo Expressway',
    targetLaps: 12,
    targetRaceTime: const Duration(minutes: 18),
    shiftPercentage: 85,
  );
  final controller = AppRuntimeController(
    configService: AppConfigService(initialConfig: config),
  );

  await controller.initialize();

  await tester.pumpWidget(
    MaterialApp(
      theme: Gt7AppTheme.light(),
      darkTheme: Gt7AppTheme.dark(),
      home: RuntimeShell(controller: controller),
    ),
  );
  await tester.pump();

  return controller;
}

Future<AppRuntimeController> _pumpDashboardShell(
  WidgetTester tester, {
  required Size physicalSize,
}) async {
  final controller = await _pumpRuntimeShell(
    tester,
    physicalSize: physicalSize,
  );
  await _seedDashboardState(tester, controller);

  return controller;
}

Future<void> _seedDashboardState(
  WidgetTester tester,
  AppRuntimeController controller,
) async {
  await controller.selectManualPlaystation('192.168.0.42');
  await tester.pumpAndSettle();

  controller.telemetryState.value = TelemetryViewState(
    connectionPhase: RuntimeConnectionPhase.stopped,
    packet: _packet(),
    packetsReceived: 128,
    minimumTireTemperatures: const Gt7WheelValues(
      frontLeft: 71,
      frontRight: 72,
      rearLeft: 85,
      rearRight: 86,
    ),
    maximumTireTemperatures: const Gt7WheelValues(
      frontLeft: 77,
      frontRight: 78,
      rearLeft: 91,
      rearRight: 92,
    ),
  );

  await _setLapHistory(
    tester,
    controller,
    laps: [
      RaceLap(lapNumber: 0, fuel: 100, position: 3, complete: true),
      RaceLap(
        lapNumber: 1,
        fuel: 90,
        lapTimeMs: 97000,
        position: 3,
        complete: true,
      ),
      RaceLap(
        lapNumber: 2,
        fuel: 79,
        lapTimeMs: 96500,
        position: 2,
        complete: true,
      ),
      RaceLap(
        lapNumber: 3,
        fuel: 66,
        lapTimeMs: 96200,
        position: 2,
        complete: true,
      ),
      RaceLap(
        lapNumber: 4,
        fuel: 42,
        lapTimeMs: 0,
        position: 2,
        complete: false,
      ),
    ],
  );
}

Future<void> _setLapHistory(
  WidgetTester tester,
  AppRuntimeController controller, {
  required List<RaceLap> laps,
}) async {
  final config = controller.configService.config;
  final race =
      Race(
          RaceType.lapRace,
          12,
          const Duration(minutes: 18).inMilliseconds.toDouble(),
          pitLaneTimeMs: const Duration(seconds: 30).inMilliseconds.toDouble(),
        )
        ..trackName = 'Tokyo Expressway'
        ..tankCapacity = 100
        ..currentFuelLevel = 42;
  for (final lap in laps) {
    race.addOrUpdateLap(lap);
  }
  controller.raceState.value = RaceViewState.fromRace(
    config: config,
    race: race,
  );

  await tester.pump();
}

Gt7TelemetryPacket _packet() {
  const zeroVector = Gt7Vector3(x: 0, y: 0, z: 0);
  const zeroWheels = Gt7WheelValues(
    frontLeft: 0,
    frontRight: 0,
    rearLeft: 0,
    rearRight: 0,
  );

  return const Gt7TelemetryPacket(
    packetId: 7,
    position: zeroVector,
    velocity: zeroVector,
    rotation: zeroVector,
    angularVelocity: zeroVector,
    orientation: 0,
    rideHeightMeters: 0,
    engineRpm: 7350,
    fuelLevel: 42,
    fuelCapacity: 100,
    speedMps: 61,
    boost: 1,
    oilPressure: 0,
    waterTemperature: 92,
    oilTemperature: 101,
    tireTemperatures: Gt7WheelValues(
      frontLeft: 73,
      frontRight: 74,
      rearLeft: 89,
      rearRight: 90,
    ),
    currentLap: 4,
    totalLaps: 12,
    bestLapTimeMs: 96200,
    lastLapTimeMs: 96200,
    timeOfDayMs: 0,
    racePosition: 2,
    totalCars: 16,
    minAlertRpm: 6500,
    maxAlertRpm: 7800,
    estimatedTopSpeed: 280,
    flags: 0,
    statusFlags: 0,
    motionFlags: 0,
    currentGear: 5,
    suggestedGear: 6,
    throttle: 0.82,
    brake: 0.05,
    roadPlane: zeroVector,
    roadPlaneDistance: 0,
    wheelRps: zeroWheels,
    tireRadiusMeters: zeroWheels,
    suspensionTravelMeters: zeroWheels,
    clutchPedal: 0,
    clutchEngagement: 0,
    transmissionRpm: 3500,
    transmissionTopSpeed: 310,
    gearRatios: [3.1, 2.2, 1.7, 1.35, 1.1, 0.95],
    carCode: 123456,
  );
}
