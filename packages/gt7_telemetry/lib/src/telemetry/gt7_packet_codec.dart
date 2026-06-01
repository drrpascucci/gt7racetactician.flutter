import 'models/gt7_telemetry_packet.dart';
import 'gt7_packet_decryptor.dart';
import 'gt7_packet_parser.dart';

class Gt7PacketCodec {
  Gt7PacketCodec({Gt7PacketDecryptor? decryptor, Gt7PacketParser? parser})
    : decryptor = decryptor ?? const Gt7PacketDecryptor(),
      parser = parser ?? const Gt7PacketParser();

  final Gt7PacketDecryptor decryptor;
  final Gt7PacketParser parser;

  Gt7TelemetryPacket decode(List<int> encryptedPacket) {
    final decrypted = decryptor.decryptBytes(encryptedPacket);
    return parser.parseBytes(decrypted);
  }
}
