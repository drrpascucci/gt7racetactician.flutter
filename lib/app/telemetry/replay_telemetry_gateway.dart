import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:gt7_telemetry/gt7_telemetry.dart';

import '../runtime/app_runtime_controller.dart';

class ReplayTelemetryGateway implements TelemetryGateway {
  ReplayTelemetryGateway({
    required this.logFilePath,
    this.speedMultiplier = 1.0,
    Gt7PacketCodec? codec,
  }) : _codec = codec ?? Gt7PacketCodec();

  final String logFilePath;
  final double speedMultiplier;
  final Gt7PacketCodec _codec;

  final StreamController<Gt7TelemetryPacket> _controller =
      StreamController<Gt7TelemetryPacket>.broadcast();

  bool _closed = false;
  StreamSubscription<void>? _replaySub;

  double get _effectiveSpeedMultiplier =>
      speedMultiplier <= 0 ? 1.0 : speedMultiplier;

  @override
  Stream<Gt7TelemetryPacket> get packets => _controller.stream;

  @override
  Stream<Uint8List>? get rawPackets => null;

  @override
  int? get localPort => null;

  @override
  Future<void> bind({
    InternetAddress? playstationAddress,
    InternetAddress? bindAddress,
    int receivePort = Gt7TelemetryClient.defaultReceivePort,
    int sendPort = Gt7TelemetryClient.defaultSendPort,
    Duration heartbeatInterval = const Duration(seconds: 1),
  }) async {
    await close();
    _closed = false;
    _replaySub = _replay().listen(null, onError: _controller.addError);
  }

  Stream<void> _replay() async* {
    final file = File(logFilePath);
    if (!await file.exists()) {
      _controller.addError(
        FileSystemException('Replay log not found', logFilePath),
      );
      return;
    }

    final bytes = await file.readAsBytes();
    final data = ByteData.sublistView(bytes);
    var offset = 0;
    int? previousTimestampUs;
    final filter = Gt7PacketIdFilter();

    while (offset + 10 <= bytes.length && !_closed) {
      final timestampUs = data.getInt64(offset, Endian.big);
      final length = data.getUint16(offset + 8, Endian.big);
      offset += 10;

      if (offset + length > bytes.length) {
        break;
      }

      final rawBytes = bytes.sublist(offset, offset + length);
      offset += length;

      if (previousTimestampUs != null) {
        final deltaUs = timestampUs - previousTimestampUs;
        if (deltaUs > 0) {
          final adjustedMs = (deltaUs / 1000 / _effectiveSpeedMultiplier)
              .round();
          if (adjustedMs > 0) {
            await Future<void>.delayed(Duration(milliseconds: adjustedMs));
          }
        }
      }
      previousTimestampUs = timestampUs;

      if (_closed) {
        break;
      }

      try {
        final packet = _codec.decode(rawBytes);
        if (filter.shouldAccept(packet.packetId)) {
          _controller.add(packet);
        }
      } catch (_) {
        // Skip malformed packets so replay can continue.
      }
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _replaySub?.cancel();
    _replaySub = null;
  }

  @override
  void dispose() {
    _closed = true;
    unawaited(_replaySub?.cancel());
    _replaySub = null;
    if (!_controller.isClosed) {
      unawaited(_controller.close());
    }
  }
}
