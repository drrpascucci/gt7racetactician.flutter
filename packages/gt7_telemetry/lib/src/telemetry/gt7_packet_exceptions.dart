class Gt7TelemetryException implements Exception {
  Gt7TelemetryException(this.message);

  final String message;

  @override
  String toString() => 'Gt7TelemetryException: $message';
}

class Gt7InvalidPacketException extends Gt7TelemetryException {
  Gt7InvalidPacketException(super.message);
}

class Gt7PacketDecryptionException extends Gt7TelemetryException {
  Gt7PacketDecryptionException(super.message);
}
