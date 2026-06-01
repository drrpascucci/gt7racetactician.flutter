import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'gt7_packet_codec.dart';
import 'gt7_packet_exceptions.dart';
import 'gt7_packet_id_filter.dart';
import 'models/gt7_telemetry_packet.dart';

class Gt7TelemetryClient {
  Gt7TelemetryClient({Gt7PacketCodec? codec, Gt7PacketIdFilter? packetIdFilter})
    : codec = codec ?? Gt7PacketCodec(),
      packetIdFilter = packetIdFilter ?? Gt7PacketIdFilter();

  static const int defaultSendPort = 33739;
  static const int defaultReceivePort = 33740;
  static const String heartbeatPayload = 'A';

  final Gt7PacketCodec codec;
  final Gt7PacketIdFilter packetIdFilter;

  final StreamController<Gt7TelemetryPacket> _packets =
      StreamController<Gt7TelemetryPacket>.broadcast();
  final StreamController<Uint8List> _rawPackets =
      StreamController<Uint8List>.broadcast();

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _socketSubscription;
  Timer? _heartbeatTimer;
  InternetAddress? _playstationAddress;
  int _sendPort = defaultSendPort;
  bool _closing = false;

  Stream<Gt7TelemetryPacket> get packets => _packets.stream;
  Stream<Uint8List> get rawPackets => _rawPackets.stream;

  int? get localPort => _socket?.port;

  Future<void> bind({
    InternetAddress? playstationAddress,
    InternetAddress? bindAddress,
    int receivePort = defaultReceivePort,
    int sendPort = defaultSendPort,
    Duration heartbeatInterval = const Duration(seconds: 1),
  }) async {
    await close();

    _closing = false;
    _playstationAddress = playstationAddress;
    _sendPort = sendPort;

    final socket = await RawDatagramSocket.bind(
      bindAddress ?? InternetAddress.anyIPv4,
      receivePort,
    );

    _socket = socket;
    _socketSubscription = socket.listen(
      _handleSocketEvent,
      onError: _packets.addError,
    );

    if (playstationAddress != null) {
      sendHeartbeat();
      _heartbeatTimer = Timer.periodic(
        heartbeatInterval,
        (_) => sendHeartbeat(),
      );
    }
  }

  void sendHeartbeat() {
    final socket = _socket;
    final playstationAddress = _playstationAddress;
    if (socket == null || playstationAddress == null) {
      return;
    }

    socket.send(heartbeatPayload.codeUnits, playstationAddress, _sendPort);
  }

  Future<void> close() async {
    if (_closing) {
      return;
    }

    _closing = true;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket?.close();
    _socket = null;
    packetIdFilter.reset();
    _closing = false;
  }

  void dispose() {
    unawaited(close());
    if (!_packets.isClosed) {
      unawaited(_packets.close());
    }
    if (!_rawPackets.isClosed) {
      unawaited(_rawPackets.close());
    }
  }

  void _handleSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }

    final socket = _socket;
    if (socket == null) {
      return;
    }

    Datagram? datagram;
    while ((datagram = socket.receive()) != null) {
      final rawBytes = Uint8List.fromList(datagram!.data);
      _rawPackets.add(rawBytes);
      try {
        final packet = codec.decode(rawBytes);
        if (packetIdFilter.shouldAccept(packet.packetId)) {
          _packets.add(packet);
        }
      } on Gt7TelemetryException catch (error, stackTrace) {
        _packets.addError(error, stackTrace);
      } catch (error, stackTrace) {
        _packets.addError(error, stackTrace);
      }
    }
  }
}
