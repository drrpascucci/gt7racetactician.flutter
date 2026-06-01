import 'dart:convert';
import 'dart:io';

enum PlaystationConsoleType {
  ps4,
  ps5,
  unknown,
}

enum PlaystationDiscoveryStatus {
  discovered,
  timedOut,
  error,
}

class PlaystationDiscoveryEndpoint {
  const PlaystationDiscoveryEndpoint({
    required this.address,
    required this.consoleType,
    required this.rawHostType,
    required this.responseCode,
    required this.isStandby,
  });

  final InternetAddress address;
  final PlaystationConsoleType consoleType;
  final String rawHostType;
  final int responseCode;
  final bool isStandby;

  bool get isAvailable => !isStandby;

  static PlaystationDiscoveryEndpoint? tryParse(
    List<int> payload,
    InternetAddress address,
  ) {
    final buffer = utf8.decode(payload, allowMalformed: true);
    final normalized = buffer.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');

    int? responseCode;
    String? rawHostType;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      if (trimmed.toUpperCase().startsWith('HTTP/')) {
        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          responseCode = int.tryParse(parts[1]);
        }
        continue;
      }

      final separatorIndex = trimmed.indexOf(':');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = trimmed.substring(0, separatorIndex).trim().toLowerCase();
      final value = trimmed.substring(separatorIndex + 1).trim();
      if (key == 'host-type') {
        rawHostType = value;
      }
    }

    if (responseCode == null && rawHostType == null) {
      return null;
    }

    return PlaystationDiscoveryEndpoint(
      address: address,
      consoleType: _parseConsoleType(rawHostType),
      rawHostType: rawHostType ?? 'unknown',
      responseCode: responseCode ?? 0,
      isStandby: responseCode == 620,
    );
  }

  static PlaystationConsoleType _parseConsoleType(String? rawHostType) {
    final normalized = rawHostType?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return PlaystationConsoleType.unknown;
    }
    if (normalized.contains('PS5')) {
      return PlaystationConsoleType.ps5;
    }
    if (normalized.contains('PS4')) {
      return PlaystationConsoleType.ps4;
    }
    return PlaystationConsoleType.unknown;
  }
}

class PlaystationDiscoveryResult {
  const PlaystationDiscoveryResult._({
    required this.status,
    required this.attempts,
    required this.elapsed,
    this.endpoint,
    this.errorMessage,
  });

  factory PlaystationDiscoveryResult.discovered({
    required PlaystationDiscoveryEndpoint endpoint,
    required int attempts,
    required Duration elapsed,
  }) {
    return PlaystationDiscoveryResult._(
      status: PlaystationDiscoveryStatus.discovered,
      endpoint: endpoint,
      attempts: attempts,
      elapsed: elapsed,
    );
  }

  factory PlaystationDiscoveryResult.timedOut({
    required int attempts,
    required Duration elapsed,
  }) {
    return PlaystationDiscoveryResult._(
      status: PlaystationDiscoveryStatus.timedOut,
      attempts: attempts,
      elapsed: elapsed,
      errorMessage: 'No PlayStation responded to the discovery broadcast.',
    );
  }

  factory PlaystationDiscoveryResult.error({
    required int attempts,
    required Duration elapsed,
    required String errorMessage,
  }) {
    return PlaystationDiscoveryResult._(
      status: PlaystationDiscoveryStatus.error,
      attempts: attempts,
      elapsed: elapsed,
      errorMessage: errorMessage,
    );
  }

  final PlaystationDiscoveryStatus status;
  final PlaystationDiscoveryEndpoint? endpoint;
  final int attempts;
  final Duration elapsed;
  final String? errorMessage;

  bool get isDiscovered => status == PlaystationDiscoveryStatus.discovered;
}

class PlaystationDiscoveryOptions {
  const PlaystationDiscoveryOptions({
    this.maxAttempts = 3,
    this.attemptTimeout = const Duration(milliseconds: 900),
    this.retryDelay = const Duration(milliseconds: 250),
    this.broadcastAddress = '255.255.255.255',
    this.discoveryPort = 9302,
    this.localPort = 0,
    this.discoveryQuery = defaultPlaystationDiscoveryQuery,
  }) : assert(maxAttempts > 0),
       assert(discoveryPort > 0),
       assert(localPort >= 0);

  final int maxAttempts;
  final Duration attemptTimeout;
  final Duration retryDelay;
  final String broadcastAddress;
  final int discoveryPort;
  final int localPort;
  final String discoveryQuery;

  InternetAddress get broadcastInternetAddress =>
      InternetAddress(broadcastAddress);

  List<int> get discoveryQueryBytes => ascii.encode(discoveryQuery);
}

const defaultPlaystationDiscoveryQuery =
    'SRCH * HTTP/1.1\ndevice-discovery-protocol-version:00030010';
