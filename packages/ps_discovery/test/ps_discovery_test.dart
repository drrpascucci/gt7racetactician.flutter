import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ps_discovery/ps_discovery.dart';
import 'package:test/test.dart';

void main() {
  test('exposes reusable discovery defaults', () {
    const options = PlaystationDiscoveryOptions();

    expect(options.maxAttempts, 3);
    expect(options.discoveryPort, 9302);
    expect(options.broadcastAddress, '255.255.255.255');
  });

  test('parses standby responses from discovery payloads', () {
    const payload = 'HTTP/1.1 620 Server Standby\r\nhost-type: PS5\r\n';
    final endpoint = PlaystationDiscoveryEndpoint.tryParse(
      utf8.encode(payload),
      InternetAddress('192.168.1.20'),
    );

    expect(endpoint, isNotNull);
    expect(endpoint!.consoleType, PlaystationConsoleType.ps5);
    expect(endpoint.isStandby, isTrue);
    expect(endpoint.isAvailable, isFalse);
    expect(endpoint.address.address, '192.168.1.20');
  });

  test('retries and returns the first discovered console', () async {
    final firstSocket = FakePlaystationDiscoverySocket();
    final secondSocket = FakePlaystationDiscoverySocket(
      onSend: (socket) {
        Future<void>.delayed(const Duration(milliseconds: 5), () {
          socket.enqueueResponse(
            'HTTP/1.1 200 OK\r\nhost-type: PS4\r\n',
            InternetAddress('192.168.1.30'),
          );
        });
      },
    );

    final service = PlaystationDiscoveryService(
      socketFactory: ((_) async {
        if (!firstSocket.wasUsed) {
          firstSocket.wasUsed = true;
          return firstSocket;
        }
        return secondSocket;
      }),
    );

    final result = await service.discover(
      options: const PlaystationDiscoveryOptions(
        maxAttempts: 2,
        attemptTimeout: Duration(milliseconds: 20),
        retryDelay: Duration(milliseconds: 1),
      ),
    );

    expect(result.status, PlaystationDiscoveryStatus.discovered);
    expect(result.attempts, 2);
    expect(result.endpoint?.consoleType, PlaystationConsoleType.ps4);
    expect(result.endpoint?.address.address, '192.168.1.30');
    expect(firstSocket.broadcastEnabledValue, isTrue);
    expect(secondSocket.broadcastEnabledValue, isTrue);
  });

  test('returns a timeout result when nothing responds', () async {
    final sockets = [
      FakePlaystationDiscoverySocket(),
      FakePlaystationDiscoverySocket(),
      FakePlaystationDiscoverySocket(),
    ];
    var index = 0;

    final service = PlaystationDiscoveryService(
      socketFactory: (_) async => sockets[index++],
    );

    final result = await service.discover(
      options: const PlaystationDiscoveryOptions(
        maxAttempts: 3,
        attemptTimeout: Duration(milliseconds: 10),
        retryDelay: Duration.zero,
      ),
    );

    expect(result.status, PlaystationDiscoveryStatus.timedOut);
    expect(result.isDiscovered, isFalse);
    expect(result.attempts, 3);
    expect(sockets.every((socket) => socket.closed), isTrue);
  });
}

class FakePlaystationDiscoverySocket implements PlaystationDiscoverySocket {
  FakePlaystationDiscoverySocket({
    this.onSend,
  });

  final void Function(FakePlaystationDiscoverySocket socket)? onSend;
  final StreamController<RawSocketEvent> _controller =
      StreamController<RawSocketEvent>.broadcast();
  final List<Datagram> _responses = <Datagram>[];

  bool broadcastEnabledValue = false;
  bool closed = false;
  bool wasUsed = false;

  @override
  Stream<RawSocketEvent> get events => _controller.stream;

  @override
  set broadcastEnabled(bool value) {
    broadcastEnabledValue = value;
  }

  void enqueueResponse(String payload, InternetAddress address) {
    _responses.add(Datagram(utf8.encode(payload), address, 9302));
    _controller.add(RawSocketEvent.read);
  }

  @override
  Datagram? receive() {
    if (_responses.isEmpty) {
      return null;
    }
    return _responses.removeAt(0);
  }

  @override
  int send(List<int> buffer, InternetAddress address, int port) {
    onSend?.call(this);
    return buffer.length;
  }

  @override
  void close() {
    if (closed) {
      return;
    }
    closed = true;
    unawaited(_controller.close());
  }
}
