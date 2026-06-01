import 'dart:async';
import 'dart:io';

abstract interface class PlaystationDiscoverySocket {
  Stream<RawSocketEvent> get events;

  set broadcastEnabled(bool value);

  int send(List<int> buffer, InternetAddress address, int port);

  Datagram? receive();

  void close();
}

typedef PlaystationDiscoverySocketFactory =
    Future<PlaystationDiscoverySocket> Function(int localPort);

class RawPlaystationDiscoverySocket implements PlaystationDiscoverySocket {
  RawPlaystationDiscoverySocket._(this._socket);

  final RawDatagramSocket _socket;

  static Future<RawPlaystationDiscoverySocket> bind({
    int localPort = 0,
  }) async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      localPort,
    );
    return RawPlaystationDiscoverySocket._(socket);
  }

  @override
  Stream<RawSocketEvent> get events => _socket;

  @override
  set broadcastEnabled(bool value) {
    _socket.broadcastEnabled = value;
  }

  @override
  int send(List<int> buffer, InternetAddress address, int port) {
    return _socket.send(buffer, address, port);
  }

  @override
  Datagram? receive() => _socket.receive();

  @override
  void close() {
    _socket.close();
  }
}
