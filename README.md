# gt7racetactician.flutter

Android-first Flutter workspace for the GT7 telemetry port. Open the repository root as the Flutter project; the Android module lives in `android\` and the reusable Dart/Flutter packages live in `packages\`.

## Workspace layout

- root app: Android Studio Flutter shell and runtime UI
- `packages\gt7_telemetry`: GT7 UDP transport, decryptor, parser, and packet filtering
- `packages\ps_discovery`: PlayStation LAN discovery and handshake flow
- `packages\gt7_domain`: shared race/domain models and prediction contracts
- `packages\gt7_design_system`: GT7-styled Flutter theme, assets, and UI primitives

## Prerequisites

- Flutter SDK 3.11.x-compatible toolchain
- Android Studio with Flutter and Dart plugins
- Android SDK / emulator or a connected Android device

If Android Studio does not auto-detect Flutter, point it to your local SDK path before running the app.

## Android Studio smoke path

1. Open `C:\Users\danie\OneDrive\Projects\gt7racetactician.flutter` in Android Studio.
2. Wait for indexing, then run **Pub get** if prompted.
3. Select an Android emulator or attached device.
4. Run `lib\main.dart`.
5. Confirm the GT7 Race Tactician dashboard opens and the runtime shell renders without layout errors.

## Flutter CLI smoke path

```powershell
flutter pub get
flutter analyze
flutter test --concurrency=1
flutter run -d android
```

Use `--concurrency=1` on this workspace if Windows file-copy conflicts appear under `build\test_cache`.

## Testing

### Automated coverage currently in the workspace

- root app tests: config loading, runtime controller behavior, and dashboard/widget smoke rendering
- `packages\gt7_domain`: race math, enums, lap/stint prediction behavior
- `packages\gt7_telemetry`: packet decrypt/parse/filter logic and UDP client behavior
- `packages\ps_discovery`: discovery payload parsing, retry, and timeout handling
- `packages\gt7_design_system`: theme construction and widget rendering

### Run tests

```powershell
flutter test --concurrency=1

Push-Location packages\gt7_design_system; flutter test; Pop-Location
Push-Location packages\gt7_domain; dart test; Pop-Location
Push-Location packages\gt7_telemetry; dart test; Pop-Location
Push-Location packages\ps_discovery; dart test; Pop-Location
```

### Planned or manual validation still expected at handoff

- on-device Android smoke run against an emulator and a physical phone
- manual LAN discovery validation on a network that allows broadcast traffic
- manual telemetry validation against a real GT7 / PlayStation session
- optional release-build verification once signing/distribution details are defined
