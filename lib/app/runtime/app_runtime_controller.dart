import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:gt7_domain/gt7_domain.dart';
import 'package:gt7_telemetry/gt7_telemetry.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ps_discovery/ps_discovery.dart';

import '../config/app_config.dart';
import '../config/app_config_service.dart';
import '../telemetry/raw_telemetry_logger.dart';
import '../telemetry/replay_telemetry_gateway.dart';
import 'app_runtime_models.dart';

abstract interface class DiscoveryGateway {
  Future<PlaystationDiscoveryResult> discover({
    PlaystationDiscoveryOptions options = const PlaystationDiscoveryOptions(),
  });
}

abstract interface class TelemetryGateway {
  Stream<Gt7TelemetryPacket> get packets;
  Stream<Uint8List>? get rawPackets;

  int? get localPort;

  Future<void> bind({
    InternetAddress? playstationAddress,
    InternetAddress? bindAddress,
    int receivePort = Gt7TelemetryClient.defaultReceivePort,
    int sendPort = Gt7TelemetryClient.defaultSendPort,
    Duration heartbeatInterval = const Duration(seconds: 1),
  });

  Future<void> close();

  void dispose();
}

class PackageDiscoveryGateway implements DiscoveryGateway {
  PackageDiscoveryGateway([PlaystationDiscoveryService? service])
    : _service = service ?? PlaystationDiscoveryService();

  final PlaystationDiscoveryService _service;

  @override
  Future<PlaystationDiscoveryResult> discover({
    PlaystationDiscoveryOptions options = const PlaystationDiscoveryOptions(),
  }) {
    return _service.discover(options: options);
  }
}

class PackageTelemetryGateway implements TelemetryGateway {
  PackageTelemetryGateway([Gt7TelemetryClient? client])
    : _client = client ?? Gt7TelemetryClient();

  final Gt7TelemetryClient _client;

  @override
  Stream<Gt7TelemetryPacket> get packets => _client.packets;

  @override
  Stream<Uint8List> get rawPackets => _client.rawPackets;

  @override
  int? get localPort => _client.localPort;

  @override
  Future<void> bind({
    InternetAddress? playstationAddress,
    InternetAddress? bindAddress,
    int receivePort = Gt7TelemetryClient.defaultReceivePort,
    int sendPort = Gt7TelemetryClient.defaultSendPort,
    Duration heartbeatInterval = const Duration(seconds: 1),
  }) {
    return _client.bind(
      playstationAddress: playstationAddress,
      bindAddress: bindAddress,
      receivePort: receivePort,
      sendPort: sendPort,
      heartbeatInterval: heartbeatInterval,
    );
  }

  @override
  Future<void> close() => _client.close();

  @override
  void dispose() => _client.dispose();
}

class AppRuntimeController extends ChangeNotifier with WidgetsBindingObserver {
  AppRuntimeController({
    required this.configService,
    DiscoveryGateway? discoveryGateway,
    TelemetryGateway? telemetryGateway,
    this.discoveryOptions = const PlaystationDiscoveryOptions(),
    this.heartbeatInterval = const Duration(seconds: 1),
    this.slowRefreshInterval = const Duration(milliseconds: 750),
    this.telemetryRefreshInterval = const Duration(milliseconds: 50),
  }) : _discoveryGateway = discoveryGateway ?? PackageDiscoveryGateway(),
       _primaryTelemetryGateway = telemetryGateway ?? PackageTelemetryGateway(),
       telemetryState = ValueNotifier<TelemetryViewState>(
         TelemetryViewState.empty(),
       ),
       raceState = ValueNotifier<RaceViewState>(
         RaceViewState.initial(configService.config),
       ) {
    _telemetryGateway = _primaryTelemetryGateway;
    _race = Race(
      configService.config.raceType,
      configService.config.targetLaps,
      configService.config.targetRaceTime.inMilliseconds.toDouble(),
      pitLaneTimeMs: configService.config.pitLaneTime.inMilliseconds.toDouble(),
    );
  }

  final AppConfigService configService;
  final DiscoveryGateway _discoveryGateway;
  final TelemetryGateway _primaryTelemetryGateway;
  late TelemetryGateway _telemetryGateway;
  ReplayTelemetryGateway? _replayTelemetryGateway;
  final PlaystationDiscoveryOptions discoveryOptions;
  final Duration heartbeatInterval;
  final Duration slowRefreshInterval;
  final Duration telemetryRefreshInterval;

  final ValueNotifier<TelemetryViewState> telemetryState;
  final ValueNotifier<RaceViewState> raceState;

  late final Race _race;
  Stream<RaceEvent> get raceEvents => _race.events;

  RuntimeConnectionState _connectionState = RuntimeConnectionState.idle();
  RuntimeConnectionState get connectionState => _connectionState;

  final SplayTreeMap<int, RaceLap> _lapHistory = SplayTreeMap<int, RaceLap>();
  StreamSubscription<Gt7TelemetryPacket>? _packetSubscription;
  StreamSubscription<Uint8List>? _rawPacketSubscription;
  Timer? _slowStateTimer;
  Timer? _telemetryStateTimer;
  Gt7TelemetryPacket? _latestPacket;
  DateTime? _lastTelemetryStateEmissionAt;
  DateTime? _latestPacketAt;
  Gt7WheelValues _minimumTireTemperatures = _zeroWheelValues;
  Gt7WheelValues _maximumTireTemperatures = _zeroWheelValues;
  InternetAddress? _playstationAddress;
  int _packetsReceived = 0;
  int? _currentLapNumber;
  int _connectionGeneration = 0;
  bool _telemetryRequested = false;
  bool _usingManualAddress = false;
  bool _replayMode = false;
  bool _initialized = false;
  bool _disposed = false;
  bool _lifecyclePaused = false;
  RawTelemetryLogger? _logger;
  Future<void> _rawLoggingOperation = Future<void>.value();
  String? _activeLogFilePath;
  String? _lastReplayLogFilePath;
  String? _logsDirectoryPath;

  bool get hasSelectedPlaystation => _replayMode || _playstationAddress != null;
  bool get isReplayMode => _replayMode;
  String? get activeLogFilePath => _activeLogFilePath;
  String? get lastReplayLogFilePath => _lastReplayLogFilePath;
  double get activeReplaySpeedMultiplier => _replayMode
      ? _replayTelemetryGateway?.speedMultiplier ?? 1.0
      : configService.config.replaySpeedMultiplier;

  Future<String?> getTelemetryLogsDirectoryPath() async {
    try {
      return await _ensureLogsDirectoryPath();
    } catch (_) {
      return _logsDirectoryPath;
    }
  }

  Future<String?> findLatestReplayLogFilePath() async {
    try {
      return await _findLatestReplayLogFilePath();
    } catch (_) {
      return _lastReplayLogFilePath;
    }
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    await _attachTelemetryGateway(_telemetryGateway);
    await configService.load();
    if (_disposed) {
      return;
    }
    configService.addListener(_handleConfigChanged);
    _slowStateTimer = Timer.periodic(
      slowRefreshInterval,
      (_) => _emitRaceState(),
    );
    _setConnectionState(
      RuntimeConnectionState(
        phase: RuntimeConnectionPhase.idle,
        headline: 'Select PlayStation',
        detail: 'Search the network or enter the console IP to continue.',
        updatedAt: DateTime.now(),
      ),
    );
    _emitTelemetryStateImmediately();
    _emitRaceState();
  }

  Future<void> reconnect() async {
    if (_replayMode) {
      await startReplay(
        speedMultiplier: configService.config.replaySpeedMultiplier,
      );
      return;
    }
    if (hasSelectedPlaystation) {
      await startTelemetry();
      return;
    }
    await discoverPlaystation();
  }

  Future<void> resetSession() async {
    _lapHistory.clear();
    _currentLapNumber = null;
    _minimumTireTemperatures = _zeroWheelValues;
    _maximumTireTemperatures = _zeroWheelValues;
    _emitTelemetryStateImmediately();
    _emitRaceState();
  }

  Future<void> updateConfig(AppConfig config) async {
    await configService.save(config);
  }

  void _handleConfigChanged() {
    if (_disposed) {
      return;
    }

    _emitRaceState();
    _emitTelemetryStateImmediately();
    unawaited(_syncRawLogging());
    if (_replayMode || !_usingManualAddress) {
      return;
    }

    final manualIp = configService.config.normalizedManualPlaystationIp;
    if (manualIp == null) {
      unawaited(changePlaystation());
      return;
    }

    final parsedAddress = InternetAddress.tryParse(manualIp);
    if (parsedAddress == null) {
      _setConnectionState(
        RuntimeConnectionState(
          phase: RuntimeConnectionPhase.error,
          headline: 'Invalid endpoint',
          detail: 'Manual PlayStation IP "$manualIp" is not valid.',
          usingManualAddress: true,
          updatedAt: DateTime.now(),
        ),
      );
      _emitTelemetryStateImmediately(
        errorMessage: 'Manual PlayStation IP is invalid.',
      );
      return;
    }

    final targetChanged = _playstationAddress?.address != parsedAddress.address;
    _playstationAddress = parsedAddress;
    if (!targetChanged) {
      return;
    }

    if (_telemetryRequested) {
      unawaited(startTelemetry());
      return;
    }

    _setConnectionState(_stoppedState());
    _emitTelemetryStateImmediately();
  }

  void _handlePacket(Gt7TelemetryPacket packet) {
    _latestPacket = packet;
    _latestPacketAt = DateTime.now();
    _packetsReceived += 1;
    _updateRaceModel(packet);
    _syncLapHistory(packet);
    _syncTireTemperatureExtremes(packet.tireTemperatures);

    if (_connectionState.phase != RuntimeConnectionPhase.live) {
      final replaySpeedLabel = activeReplaySpeedMultiplier.toStringAsFixed(
        activeReplaySpeedMultiplier.truncateToDouble() ==
                activeReplaySpeedMultiplier
            ? 0
            : 1,
      );
      _setConnectionState(
        RuntimeConnectionState(
          phase: RuntimeConnectionPhase.live,
          headline: _replayMode
              ? 'REPLAY x$replaySpeedLabel'
              : 'Telemetry live',
          detail: _replayMode
              ? (_lastReplayLogFilePath ?? 'Replaying recorded telemetry')
              : _playstationAddress == null
              ? 'Receiving packets'
              : 'Receiving packets from ${_playstationAddress!.address}',
          playstationAddress: _playstationAddress,
          usingManualAddress: _usingManualAddress,
          updatedAt: DateTime.now(),
        ),
      );
    }

    _scheduleTelemetryStateRefresh();
  }

  void _handleTelemetryError(Object error, [StackTrace? stackTrace]) {
    _setConnectionState(
      RuntimeConnectionState(
        phase: RuntimeConnectionPhase.error,
        headline: 'Telemetry error',
        detail: '$error',
        playstationAddress: _playstationAddress,
        usingManualAddress: _usingManualAddress,
        updatedAt: DateTime.now(),
      ),
    );
    _emitTelemetryStateImmediately(errorMessage: '$error');
  }

  void _updateRaceModel(Gt7TelemetryPacket packet) {
    final config = configService.config;
    _race.raceType = config.raceType;
    _race.raceLaps = packet.totalLaps > 0 ? packet.totalLaps : config.targetLaps;
    _race.raceTimeMs = config.targetRaceTime.inMilliseconds.toDouble();
    _race.pitLaneTimeMs = config.pitLaneTime.inMilliseconds.toDouble();
    _race.trackName = config.trackName;
    _race.tankCapacity = packet.fuelCapacity > 0 ? packet.fuelCapacity : 100;
    _race.currentFuelLevel = packet.fuelLevel;
  }

  void _syncLapHistory(Gt7TelemetryPacket packet) {
    final lapNumber = packet.currentLap < 1 ? 1 : packet.currentLap;

    if (_lapHistory.isEmpty) {
      final lap0 = RaceLap(
        lapNumber: 0,
        fuel: packet.fuelCapacity > 0 ? packet.fuelCapacity : packet.fuelLevel,
        position: packet.racePosition,
        complete: true,
      );
      _lapHistory[0] = lap0;
      _race.addOrUpdateLap(lap0);
    }

    if (_currentLapNumber != null && lapNumber < _currentLapNumber!) {
      _lapHistory.clear();
      _race.reset();
      _currentLapNumber = null;
      final lap0 = RaceLap(
        lapNumber: 0,
        fuel: packet.fuelCapacity > 0 ? packet.fuelCapacity : packet.fuelLevel,
        position: packet.racePosition,
        complete: true,
      );
      _lapHistory[0] = lap0;
      _race.addOrUpdateLap(lap0);
    }

    if (_currentLapNumber != null && lapNumber > _currentLapNumber!) {
      final completedLapNumber = lapNumber - 1;
      final completedLap = RaceLap(
        lapNumber: completedLapNumber,
        fuel: packet.fuelLevel,
        lapTimeMs: packet.lastLapTimeMs.toDouble(),
        position: packet.racePosition,
        complete: true,
      );
      _lapHistory[completedLapNumber] = completedLap;
      _race.addOrUpdateLap(completedLap);
    }

    _currentLapNumber = lapNumber;
    final currentLap = _lapHistory.putIfAbsent(
      lapNumber,
      () => RaceLap(lapNumber: lapNumber),
    );
    currentLap
      ..fuel = packet.fuelLevel
      ..lapTimeMs = packet.lastLapTimeMs.toDouble()
      ..position = packet.racePosition
      ..complete = false;
    _race.addOrUpdateLap(currentLap);
  }

  Future<void> discoverPlaystation() async {
    if (_disposed || !_initialized) {
      return;
    }

    final generation = ++_connectionGeneration;
    _telemetryRequested = false;
    await _closeActiveTelemetry();
    if (_replayMode) {
      _replayMode = false;
      await _disposeReplayGateway();
      await _attachTelemetryGateway(_primaryTelemetryGateway);
    }

    if (_lifecyclePaused) {
      _setConnectionState(
        RuntimeConnectionState(
          phase: RuntimeConnectionPhase.paused,
          headline: 'Runtime paused',
          detail: 'Waiting for the app to resume.',
          playstationAddress: _playstationAddress,
          usingManualAddress: _usingManualAddress,
          updatedAt: DateTime.now(),
        ),
      );
      _emitTelemetryStateImmediately();
      return;
    }

    _playstationAddress = null;
    _usingManualAddress = false;
    _setConnectionState(
      RuntimeConnectionState(
        phase: RuntimeConnectionPhase.discovering,
        headline: 'Searching for PlayStation',
        detail: 'Broadcast discovery is active.',
        updatedAt: DateTime.now(),
      ),
    );
    _emitTelemetryStateImmediately();

    final result = await _discoveryGateway.discover(options: discoveryOptions);
    if (!_isCurrentGeneration(generation)) {
      return;
    }

    if (!result.isDiscovered || result.endpoint == null) {
      _setConnectionState(
        RuntimeConnectionState(
          phase: RuntimeConnectionPhase.error,
          headline: 'Discovery unavailable',
          detail: result.errorMessage ?? 'No PlayStation responded.',
          updatedAt: DateTime.now(),
        ),
      );
      _emitTelemetryStateImmediately(errorMessage: result.errorMessage);
      return;
    }

    if (!result.endpoint!.isAvailable) {
      _playstationAddress = result.endpoint!.address;
      _usingManualAddress = false;
      _setConnectionState(
        RuntimeConnectionState(
          phase: RuntimeConnectionPhase.error,
          headline: 'Console unavailable',
          detail:
              'Discovered PlayStation at ${result.endpoint!.address.address} is in standby.',
          playstationAddress: result.endpoint!.address,
          updatedAt: DateTime.now(),
        ),
      );
      _emitTelemetryStateImmediately(
        errorMessage: 'Wake the PlayStation, then reconnect.',
      );
      return;
    }

    _playstationAddress = result.endpoint!.address;
    _usingManualAddress = false;
    _setConnectionState(_stoppedState(headline: 'PlayStation ready'));
    _emitTelemetryStateImmediately();
  }

  Future<void> selectManualPlaystation(String manualIp) async {
    final trimmedIp = manualIp.trim();
    final parsedAddress = InternetAddress.tryParse(trimmedIp);
    if (parsedAddress == null) {
      _playstationAddress = null;
      _usingManualAddress = true;
      _setConnectionState(
        RuntimeConnectionState(
          phase: RuntimeConnectionPhase.error,
          headline: 'Invalid endpoint',
          detail: 'Manual PlayStation IP "$trimmedIp" is not valid.',
          usingManualAddress: true,
          updatedAt: DateTime.now(),
        ),
      );
      _emitTelemetryStateImmediately(
        errorMessage: 'Manual PlayStation IP is invalid.',
      );
      return;
    }

    await updateConfig(
      configService.config.copyWith(manualPlaystationIp: trimmedIp),
    );
    _playstationAddress = parsedAddress;
    _usingManualAddress = true;
    _telemetryRequested = false;
    _setConnectionState(_stoppedState(headline: 'Manual endpoint ready'));
    _emitTelemetryStateImmediately();
  }

  Future<void> clearManualPlaystation() async {
    if (configService.config.normalizedManualPlaystationIp == null) {
      return;
    }
    await updateConfig(
      configService.config.copyWith(clearManualPlaystationIp: true),
    );
  }

  Future<void> changePlaystation() async {
    _connectionGeneration += 1;
    _telemetryRequested = false;
    await _closeActiveTelemetry();
    if (_replayMode) {
      _replayMode = false;
      await _disposeReplayGateway();
      await _attachTelemetryGateway(_primaryTelemetryGateway);
    }
    _playstationAddress = null;
    _usingManualAddress = false;
    _setConnectionState(
      RuntimeConnectionState(
        phase: RuntimeConnectionPhase.idle,
        headline: 'Select PlayStation',
        detail: 'Search the network or enter the console IP to continue.',
        updatedAt: DateTime.now(),
      ),
    );
    _emitTelemetryStateImmediately();
  }

  Future<void> startTelemetry() async {
    if (_disposed || !_initialized) {
      return;
    }
    if (_playstationAddress == null) {
      _setConnectionState(
        RuntimeConnectionState(
          phase: RuntimeConnectionPhase.error,
          headline: 'No PlayStation selected',
          detail: 'Search the network or enter the console IP first.',
          updatedAt: DateTime.now(),
        ),
      );
      _emitTelemetryStateImmediately(
        errorMessage: 'Select a PlayStation before starting telemetry.',
      );
      return;
    }
    _telemetryRequested = true;
    final generation = ++_connectionGeneration;
    await _closeActiveTelemetry();
    if (_replayMode) {
      _replayMode = false;
      await _disposeReplayGateway();
      await _attachTelemetryGateway(_primaryTelemetryGateway);
    }
    await _bindTelemetry(
      address: _playstationAddress!,
      generation: generation,
      headline: _usingManualAddress
          ? 'Connecting to manual endpoint'
          : 'Connecting to PlayStation',
      detail: _playstationAddress!.address,
      usingManualAddress: _usingManualAddress,
    );
  }

  Future<void> stopTelemetry() async {
    _connectionGeneration += 1;
    _telemetryRequested = false;
    await _closeActiveTelemetry();
    if (_replayMode) {
      _replayMode = false;
      await _disposeReplayGateway();
      await _attachTelemetryGateway(_primaryTelemetryGateway);
    }
    if (_playstationAddress == null) {
      _setConnectionState(RuntimeConnectionState.idle());
    } else {
      _setConnectionState(_stoppedState());
    }
    _emitTelemetryStateImmediately();
  }

  Future<void> toggleTelemetry() async {
    if (_connectionState.canStop) {
      await stopTelemetry();
      return;
    }
    await startTelemetry();
  }

  Future<void> startReplay({
    String? logFilePath,
    double? speedMultiplier,
  }) async {
    if (_disposed || !_initialized) {
      return;
    }

    final replayPath = logFilePath ?? await _findLatestReplayLogFilePath();
    if (replayPath == null) {
      _setConnectionState(
        RuntimeConnectionState(
          phase: RuntimeConnectionPhase.error,
          headline: 'Replay unavailable',
          detail: 'No telemetry log was found to replay.',
          playstationAddress: _playstationAddress,
          usingManualAddress: _usingManualAddress,
          updatedAt: DateTime.now(),
        ),
      );
      _emitTelemetryStateImmediately(
        errorMessage: 'Record a telemetry session before starting replay.',
      );
      return;
    }

    final generation = ++_connectionGeneration;
    _telemetryRequested = false;
    await _closeActiveTelemetry();
    await _disposeReplayGateway();

    _replayMode = true;
    _lastReplayLogFilePath = replayPath;
    final gateway = ReplayTelemetryGateway(
      logFilePath: replayPath,
      speedMultiplier:
          speedMultiplier ?? configService.config.replaySpeedMultiplier,
    );
    _replayTelemetryGateway = gateway;
    await _attachTelemetryGateway(gateway);
    _setConnectionState(
      RuntimeConnectionState(
        phase: RuntimeConnectionPhase.connecting,
        headline: 'Starting replay',
        detail: replayPath,
        playstationAddress: _playstationAddress,
        usingManualAddress: _usingManualAddress,
        updatedAt: DateTime.now(),
      ),
    );
    _emitTelemetryStateImmediately();

    try {
      await gateway.bind(heartbeatInterval: heartbeatInterval);
      if (!_isCurrentGeneration(generation)) {
        await gateway.close();
      }
    } catch (error) {
      if (!_isCurrentGeneration(generation)) {
        return;
      }
      _setConnectionState(
        RuntimeConnectionState(
          phase: RuntimeConnectionPhase.error,
          headline: 'Replay failed',
          detail: '$error',
          playstationAddress: _playstationAddress,
          usingManualAddress: _usingManualAddress,
          updatedAt: DateTime.now(),
        ),
      );
      _emitTelemetryStateImmediately(errorMessage: '$error');
    }
  }

  Future<void> stopReplay() async {
    if (!_replayMode) {
      return;
    }

    _connectionGeneration += 1;
    await _closeActiveTelemetry();
    await _disposeReplayGateway();
    _replayMode = false;
    await _attachTelemetryGateway(_primaryTelemetryGateway);

    if (_playstationAddress == null) {
      _setConnectionState(RuntimeConnectionState.idle());
    } else {
      _setConnectionState(_stoppedState());
    }
    _emitTelemetryStateImmediately();
  }

  Future<void> _attachTelemetryGateway(TelemetryGateway gateway) async {
    await _packetSubscription?.cancel();
    await _rawPacketSubscription?.cancel();
    _telemetryGateway = gateway;
    _packetSubscription = gateway.packets.listen(
      _handlePacket,
      onError: _handleTelemetryError,
    );
    final rawPackets = gateway.rawPackets;
    _rawPacketSubscription = rawPackets?.listen(_handleRawPacket);
  }

  void _handleRawPacket(Uint8List rawBytes) {
    final logger = _logger;
    if (logger == null || !_loggerShouldBeActive) {
      return;
    }

    final packetCopy = Uint8List.fromList(rawBytes);
    _rawLoggingOperation = _rawLoggingOperation.then((_) async {
      if (!_loggerShouldBeActive || _logger != logger) {
        return;
      }
      try {
        await logger.logPacket(packetCopy);
      } catch (_) {
        await _stopRawLogging();
      }
    });
  }

  bool get _loggerShouldBeActive {
    return !_replayMode &&
        configService.config.rawLoggingEnabled &&
        _logger != null;
  }

  Future<void> _syncRawLogging() async {
    final shouldLog =
        !_replayMode &&
        configService.config.rawLoggingEnabled &&
        _telemetryGateway.rawPackets != null &&
        (_telemetryRequested ||
            _connectionState.phase == RuntimeConnectionPhase.connecting ||
            _connectionState.phase == RuntimeConnectionPhase.live);

    if (shouldLog) {
      await _startRawLogging();
      return;
    }

    await _stopRawLogging();
  }

  Future<void> _startRawLogging() async {
    if (_logger?.isOpen ?? false) {
      return;
    }

    try {
      final logsDirectoryPath = await _ensureLogsDirectoryPath();
      final filePath =
          '$logsDirectoryPath${Platform.pathSeparator}session_${DateTime.now().microsecondsSinceEpoch}.gt7log';
      final logger = RawTelemetryLogger(filePath);
      await logger.open();
      _logger = logger;
      _activeLogFilePath = filePath;
      _lastReplayLogFilePath = filePath;
      if (!_disposed) {
        notifyListeners();
      }
    } catch (_) {
      _logger = null;
      _activeLogFilePath = null;
    }
  }

  Future<void> _stopRawLogging() async {
    final logger = _logger;
    if (logger == null) {
      if (_activeLogFilePath != null) {
        _activeLogFilePath = null;
        if (!_disposed) {
          notifyListeners();
        }
      }
      return;
    }

    _logger = null;
    final previousPath = _activeLogFilePath;
    _activeLogFilePath = null;
    try {
      await _rawLoggingOperation;
    } catch (_) {
      // Ignore pending write failures when shutting down best-effort logging.
    }
    await logger.close();
    _lastReplayLogFilePath = previousPath ?? logger.filePath;
    _rawLoggingOperation = Future<void>.value();
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _closeActiveTelemetry() async {
    await _stopRawLogging();
    await _telemetryGateway.close();
  }

  Future<void> _disposeReplayGateway() async {
    final gateway = _replayTelemetryGateway;
    _replayTelemetryGateway = null;
    if (gateway == null) {
      return;
    }
    gateway.dispose();
  }

  Future<String> _ensureLogsDirectoryPath() async {
    final cachedPath = _logsDirectoryPath;
    if (cachedPath != null) {
      return cachedPath;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final logsDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}telemetry_logs',
    );
    await logsDirectory.create(recursive: true);
    _logsDirectoryPath = logsDirectory.path;
    return logsDirectory.path;
  }

  Future<String?> _findLatestReplayLogFilePath() async {
    final logsDirectoryPath = await _ensureLogsDirectoryPath();
    final logsDirectory = Directory(logsDirectoryPath);
    if (!await logsDirectory.exists()) {
      return _lastReplayLogFilePath;
    }

    File? latestFile;
    DateTime? latestModified;
    await for (final entity in logsDirectory.list()) {
      if (entity is! File || !entity.path.endsWith('.gt7log')) {
        continue;
      }

      final modified = await entity.lastModified();
      if (latestModified == null || modified.isAfter(latestModified)) {
        latestModified = modified;
        latestFile = entity;
      }
    }

    _lastReplayLogFilePath = latestFile?.path ?? _lastReplayLogFilePath;
    return _lastReplayLogFilePath;
  }

  Future<void> _bindTelemetry({
    required InternetAddress address,
    required int generation,
    required String headline,
    required String detail,
    required bool usingManualAddress,
  }) async {
    _playstationAddress = address;
    _usingManualAddress = usingManualAddress;
    _setConnectionState(
      RuntimeConnectionState(
        phase: RuntimeConnectionPhase.connecting,
        headline: headline,
        detail: detail,
        playstationAddress: address,
        usingManualAddress: usingManualAddress,
        updatedAt: DateTime.now(),
      ),
    );
    _emitTelemetryStateImmediately();

    try {
      await _syncRawLogging();
      await _telemetryGateway.bind(
        playstationAddress: address,
        heartbeatInterval: heartbeatInterval,
      );
      if (!_isCurrentGeneration(generation)) {
        await _telemetryGateway.close();
        await _stopRawLogging();
      }
    } catch (error) {
      await _stopRawLogging();
      if (!_isCurrentGeneration(generation)) {
        return;
      }
      _setConnectionState(
        RuntimeConnectionState(
          phase: RuntimeConnectionPhase.error,
          headline: 'Bind failed',
          detail: '$error',
          playstationAddress: address,
          usingManualAddress: usingManualAddress,
          updatedAt: DateTime.now(),
        ),
      );
      _emitTelemetryStateImmediately(errorMessage: '$error');
    }
  }

  RuntimeConnectionState _stoppedState({
    String headline = 'Telemetry stopped',
  }) {
    return RuntimeConnectionState(
      phase: RuntimeConnectionPhase.stopped,
      headline: headline,
      detail: _playstationAddress == null
          ? 'Select a PlayStation to continue.'
          : 'Ready on ${_playstationAddress!.address}. Press start to read telemetry.',
      playstationAddress: _playstationAddress,
      usingManualAddress: _usingManualAddress,
      updatedAt: DateTime.now(),
    );
  }

  bool _isCurrentGeneration(int generation) {
    return !_disposed &&
        !_lifecyclePaused &&
        generation == _connectionGeneration;
  }

  Race _buildRaceSnapshot() {
    if (_latestPacket != null) {
      _updateRaceModel(_latestPacket!);
    }
    return _race;
  }

  void _emitTelemetryState({String? errorMessage}) {
    telemetryState.value = TelemetryViewState(
      connectionPhase: _connectionState.phase,
      packet: _latestPacket,
      playstationAddress: _playstationAddress,
      usingManualAddress: _usingManualAddress,
      packetsReceived: _packetsReceived,
      minimumTireTemperatures: _minimumTireTemperatures,
      maximumTireTemperatures: _maximumTireTemperatures,
      lastPacketAt: _latestPacketAt,
      errorMessage:
          errorMessage ??
          (_connectionState.phase == RuntimeConnectionPhase.error
              ? _connectionState.detail
              : null),
    );
  }

  void _scheduleTelemetryStateRefresh() {
    if (_disposed || telemetryRefreshInterval <= Duration.zero) {
      _emitTelemetryStateImmediately();
      return;
    }

    final now = DateTime.now();
    final lastEmissionAt = _lastTelemetryStateEmissionAt;
    if (lastEmissionAt == null ||
        now.difference(lastEmissionAt) >= telemetryRefreshInterval) {
      _emitTelemetryState();
      _lastTelemetryStateEmissionAt = now;
      return;
    }

    _telemetryStateTimer ??= Timer(
      telemetryRefreshInterval - now.difference(lastEmissionAt),
      () {
        _telemetryStateTimer = null;
        if (_disposed) {
          return;
        }
        _emitTelemetryState();
        _lastTelemetryStateEmissionAt = DateTime.now();
      },
    );
  }

  void _emitTelemetryStateImmediately({String? errorMessage}) {
    _telemetryStateTimer?.cancel();
    _telemetryStateTimer = null;
    _emitTelemetryState(errorMessage: errorMessage);
    _lastTelemetryStateEmissionAt = DateTime.now();
  }

  void _emitRaceState() {
    raceState.value = RaceViewState.fromRace(
      config: configService.config,
      race: _buildRaceSnapshot(),
    );
  }

  void _setConnectionState(RuntimeConnectionState state) {
    _connectionState = state;
    notifyListeners();
  }

  void _syncTireTemperatureExtremes(Gt7WheelValues values) {
    _minimumTireTemperatures = Gt7WheelValues(
      frontLeft: _mergeMinimum(
        _minimumTireTemperatures.frontLeft,
        values.frontLeft,
      ),
      frontRight: _mergeMinimum(
        _minimumTireTemperatures.frontRight,
        values.frontRight,
      ),
      rearLeft: _mergeMinimum(
        _minimumTireTemperatures.rearLeft,
        values.rearLeft,
      ),
      rearRight: _mergeMinimum(
        _minimumTireTemperatures.rearRight,
        values.rearRight,
      ),
    );
    _maximumTireTemperatures = Gt7WheelValues(
      frontLeft: _mergeMaximum(
        _maximumTireTemperatures.frontLeft,
        values.frontLeft,
      ),
      frontRight: _mergeMaximum(
        _maximumTireTemperatures.frontRight,
        values.frontRight,
      ),
      rearLeft: _mergeMaximum(
        _maximumTireTemperatures.rearLeft,
        values.rearLeft,
      ),
      rearRight: _mergeMaximum(
        _maximumTireTemperatures.rearRight,
        values.rearRight,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _lifecyclePaused = false;
        if (_telemetryRequested && _playstationAddress != null) {
          unawaited(startTelemetry());
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _lifecyclePaused = true;
        if (_telemetryRequested || _replayMode) {
          unawaited(_closeActiveTelemetry());
          _setConnectionState(
            RuntimeConnectionState(
              phase: RuntimeConnectionPhase.paused,
              headline: 'Runtime paused',
              detail: _replayMode
                  ? 'Replay is suspended with app lifecycle.'
                  : 'Telemetry socket is suspended with app lifecycle.',
              playstationAddress: _playstationAddress,
              usingManualAddress: _usingManualAddress,
              updatedAt: DateTime.now(),
            ),
          );
          _emitTelemetryStateImmediately();
        }
        break;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    configService.removeListener(_handleConfigChanged);
    _slowStateTimer?.cancel();
    _telemetryStateTimer?.cancel();
    final replayGateway = _replayTelemetryGateway;
    unawaited(_packetSubscription?.cancel());
    unawaited(_rawPacketSubscription?.cancel());
    unawaited(_stopRawLogging());
    _telemetryGateway.dispose();
    if (!identical(_primaryTelemetryGateway, _telemetryGateway)) {
      _primaryTelemetryGateway.dispose();
    }
    if (replayGateway != null && !identical(replayGateway, _telemetryGateway)) {
      replayGateway.dispose();
    }
    telemetryState.dispose();
    raceState.dispose();
    _race.dispose();
    super.dispose();
  }
}

const _zeroWheelValues = Gt7WheelValues(
  frontLeft: 0,
  frontRight: 0,
  rearLeft: 0,
  rearRight: 0,
);

double _mergeMinimum(double previous, double next) {
  if (next <= 0) {
    return previous;
  }
  if (previous <= 0) {
    return next;
  }
  return next < previous ? next : previous;
}

double _mergeMaximum(double previous, double next) {
  if (next <= 0) {
    return previous;
  }
  return next > previous ? next : previous;
}
