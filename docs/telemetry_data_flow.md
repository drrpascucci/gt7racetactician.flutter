# Telemetry Data Flow Documentation

This document describes the journey of telemetry data from the PlayStation 4/5 console to the end-user interface in the GT7 Race Tactician application.

## 1. External Data Source (The PlayStation)
*   **Emission**: Gran Turismo 7 broadcasts encrypted UDP packets on port `33740` at approximately 60Hz.
*   **Handshake**: The app (via `Gt7TelemetryClient`) sends a "Heartbeat" (ASCII character 'A') every second to port `33739` of the PlayStation's IP address to authorize the data stream.

## 2. Transport Layer (`packages/gt7_telemetry`)
*   **Reception**: `Gt7TelemetryClient` listens on a UDP socket. When a packet arrives, it is captured as a `Uint8List`.
*   **Decryption**: `Gt7PacketDecryptor` uses Salsa20 decryption with the GT7-specific XOR key to transform the raw bytes into a readable buffer.
*   **Parsing**: `Gt7PacketParser` extracts binary data from specific offsets to create a `Gt7TelemetryPacket` object. This object contains structured data such as:
    *   Speed and Engine RPM
    *   Fuel level and Capacity
    *   Tire temperatures and wear
    *   Current lap and Race position
*   **Gateway**: The `PackageTelemetryGateway` abstracts the client, exposing packets through a `Stream<Gt7TelemetryPacket>`.

## 3. Application Orchestration (`lib/app/runtime/app_runtime_controller.dart`)
*   **Stream Management**: The `AppRuntimeController` subscribes to the Gateway's stream.
*   **Handling (`_handlePacket`)**:
    *   **Live Updates**: Updates the `_latestPacket` and notifies listeners interested in high-frequency data (like RPM bars).
    *   **Domain Sync**: Calls `_updateRaceModel` and `_syncLapHistory` to feed data into the persistent domain layer.
    *   **Persistence**: Maintains the `_lapHistory` collection to track state across the entire race session.

## 4. Domain Logic (`packages/gt7_domain`)
*   **`Race` Model**: Acts as the "Source of Truth" for race strategy and state.
    *   **Calculations**: When `addOrUpdateLap` is called, it computes average fuel consumption per lap and average lap times.
    *   **Predictions**: Generates `RaceStint` objects to predict when the driver should pit and how much fuel is required to reach the finish.
    *   **Event Detection**: Monitors data changes to broadcast `RaceEvent`s (e.g., `NewLapStartedEvent`, `LowFuelEvent`, `PositionChangedEvent`).

## 5. State Exposure (ValueNotifiers)
Data is exposed to the UI through three main channels:
*   **`telemetryState`**: A `ValueNotifier<TelemetryViewState>` optimized for high-frequency updates (every 50ms). Used for gauges and live telemetry.
*   **`raceState`**: A `ValueNotifier<RaceViewState>` updated at a lower frequency (every 750ms). Used for strategy tables and long-term predictions.
*   **`raceEvents`**: A `Stream<RaceEvent>` for discrete, one-time alerts that require immediate attention.

## 6. UI Consumption (The User Interface)
*   **Gauges**: Widgets like `Gt7RpmLedBar` rebuild via `ValueListenableBuilder` when `telemetryState` changes.
*   **Dashboards**: Strategy screens display predicted pit stops and fuel targets from the `raceState`.
*   **Alerts**: Interaction layers listen to `raceEvents` to trigger UI snackbars or voice-engineer notifications (e.g., "P2 Gained" or "Low Fuel").
