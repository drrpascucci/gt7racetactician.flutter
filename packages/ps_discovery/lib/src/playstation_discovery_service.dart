import 'dart:async';
import 'dart:io';

import 'package:ps_discovery/src/playstation_discovery_models.dart';
import 'package:ps_discovery/src/playstation_discovery_socket.dart';

class PlaystationDiscoveryService {
  PlaystationDiscoveryService({
    PlaystationDiscoverySocketFactory? socketFactory,
  }) : _socketFactory =
           socketFactory ?? ((localPort) => RawPlaystationDiscoverySocket.bind(localPort: localPort));

  final PlaystationDiscoverySocketFactory _socketFactory;

  Future<PlaystationDiscoveryResult> discover({
    PlaystationDiscoveryOptions options = const PlaystationDiscoveryOptions(),
  }) async {
    final stopwatch = Stopwatch()..start();
    var attempts = 0;
    String? lastError;

    while (attempts < options.maxAttempts) {
      attempts += 1;

      final attemptResult = await _discoverOnce(
        options: options,
        attempts: attempts,
        stopwatch: stopwatch,
      );

      if (attemptResult.isDiscovered) {
        return attemptResult;
      }

      if (attemptResult.status == PlaystationDiscoveryStatus.error) {
        lastError = attemptResult.errorMessage;
      }

      if (attempts < options.maxAttempts && options.retryDelay > Duration.zero) {
        await Future<void>.delayed(options.retryDelay);
      }
    }

    stopwatch.stop();
    if (lastError != null) {
      return PlaystationDiscoveryResult.error(
        attempts: attempts,
        elapsed: stopwatch.elapsed,
        errorMessage: lastError,
      );
    }

    return PlaystationDiscoveryResult.timedOut(
      attempts: attempts,
      elapsed: stopwatch.elapsed,
    );
  }

  Future<PlaystationDiscoveryResult> _discoverOnce({
    required PlaystationDiscoveryOptions options,
    required int attempts,
    required Stopwatch stopwatch,
  }) async {
    PlaystationDiscoverySocket? socket;
    StreamSubscription<RawSocketEvent>? subscription;
    final completer = Completer<PlaystationDiscoveryEndpoint?>();

    try {
      socket = await _socketFactory(options.localPort);
      final activeSocket = socket;
      activeSocket.broadcastEnabled = true;
      subscription = activeSocket.events.listen((event) {
        if (event != RawSocketEvent.read || completer.isCompleted) {
          return;
        }

        Datagram? datagram;
        while ((datagram = activeSocket.receive()) != null) {
          final endpoint = PlaystationDiscoveryEndpoint.tryParse(
            datagram!.data,
            datagram.address,
          );
          if (endpoint != null) {
            completer.complete(endpoint);
            return;
          }
        }
      });

      final sentBytes = activeSocket.send(
        options.discoveryQueryBytes,
        options.broadcastInternetAddress,
        options.discoveryPort,
      );

      if (sentBytes <= 0) {
        return PlaystationDiscoveryResult.error(
          attempts: attempts,
          elapsed: stopwatch.elapsed,
          errorMessage: 'Failed to send the discovery broadcast.',
        );
      }

      final endpoint = await completer.future.timeout(
        options.attemptTimeout,
        onTimeout: () => null,
      );

      if (endpoint == null) {
        return PlaystationDiscoveryResult.timedOut(
          attempts: attempts,
          elapsed: stopwatch.elapsed,
        );
      }

      return PlaystationDiscoveryResult.discovered(
        endpoint: endpoint,
        attempts: attempts,
        elapsed: stopwatch.elapsed,
      );
    } on SocketException catch (error) {
      return PlaystationDiscoveryResult.error(
        attempts: attempts,
        elapsed: stopwatch.elapsed,
        errorMessage: error.message,
      );
    } catch (error) {
      return PlaystationDiscoveryResult.error(
        attempts: attempts,
        elapsed: stopwatch.elapsed,
        errorMessage: 'Discovery failed: $error',
      );
    } finally {
      await subscription?.cancel();
      socket?.close();
    }
  }
}
