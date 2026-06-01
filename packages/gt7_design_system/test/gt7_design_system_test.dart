import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

void main() {
  test('exposes package assets without app dependencies', () {
    expect(Gt7AssetManifest.packageName, 'gt7_design_system');
    expect(
      Gt7AssetManifest.image(Gt7AssetManifest.raceTacticianLogo).package,
      'gt7_design_system',
    );
  });

  test('builds both material themes', () {
    final lightTheme = Gt7AppTheme.light();
    final darkTheme = Gt7AppTheme.dark();

    expect(lightTheme.useMaterial3, isTrue);
    expect(lightTheme.colorScheme.brightness, Brightness.light);
    expect(darkTheme.useMaterial3, isTrue);
    expect(darkTheme.colorScheme.brightness, Brightness.dark);
    expect(darkTheme.extension<Gt7Theme>(), isNotNull);
  });

  test('computes rpm thresholds from legacy logic', () {
    expect(Gt7RpmLedBar.activeLedCountFor(rpm: 5400, limit: 7000), 0);
    expect(Gt7RpmLedBar.activeLedCountFor(rpm: 6400, limit: 7000), 6);
    expect(Gt7RpmLedBar.shouldBlink(rpm: 6900, limit: 7000), isTrue);
  });

  testWidgets('renders pill buttons and dialog surfaces', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: Gt7AppTheme.dark(),
        home: Scaffold(
          body: Gt7DialogFrame(
            title: 'Confirm exit',
            message: 'Leave the current telemetry session?',
            actions: [
              Gt7PillButton(
                label: 'Exit',
                variant: Gt7ButtonVariant.danger,
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Confirm exit'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);

    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('renders active rpm LEDs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: Gt7AppTheme.dark(),
        home: const Scaffold(
          body: Gt7RpmLedBar(rpm: 6400, limit: 7000, label: '6400 RPM'),
        ),
      ),
    );

    expect(find.text('6400 RPM'), findsOneWidget);
    expect(find.byKey(const ValueKey('gt7-led-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('gt7-led-9')), findsOneWidget);
  });
}
