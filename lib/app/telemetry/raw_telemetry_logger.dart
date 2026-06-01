import 'dart:io';
import 'dart:typed_data';

class RawTelemetryLogger {
  RawTelemetryLogger(this._filePath);

  final String _filePath;
  IOSink? _sink;
  bool _open = false;

  bool get isOpen => _open;
  String get filePath => _filePath;

  Future<void> open() async {
    if (_open) {
      return;
    }

    final file = File(_filePath);
    await file.parent.create(recursive: true);
    _sink = file.openWrite(mode: FileMode.writeOnly);
    _open = true;
  }

  Future<void> logPacket(Uint8List rawBytes) async {
    if (!_open || _sink == null) {
      return;
    }

    final now = DateTime.now().microsecondsSinceEpoch;
    final header = ByteData(10);
    header.setInt64(0, now, Endian.big);
    header.setUint16(8, rawBytes.length, Endian.big);
    _sink!.add(header.buffer.asUint8List());
    _sink!.add(rawBytes);
  }

  Future<void> close() async {
    if (!_open) {
      return;
    }

    _open = false;
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }
}
