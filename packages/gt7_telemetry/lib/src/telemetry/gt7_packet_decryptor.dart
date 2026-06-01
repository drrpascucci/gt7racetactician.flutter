import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/stream/salsa20.dart';

import 'gt7_packet_exceptions.dart';

class Gt7PacketDecryptor {
  const Gt7PacketDecryptor();

  static const int minimumPacketSize = 0x44;
  static const int packetMagic = 0x47375330;
  static const int seedMask = 0xDEADBEAF;

  static final Uint8List _key = Uint8List.fromList(
    ascii.encode('Simulator Interface Packet GT7 ver 0.0').sublist(0, 32),
  );

  Uint8List decryptBytes(List<int> encrypted) {
    final bytes = Uint8List.fromList(encrypted);
    if (bytes.length < minimumPacketSize) {
      throw Gt7PacketDecryptionException(
        'GT7 packet is too small to contain a Salsa20 nonce seed.',
      );
    }

    final view = ByteData.sublistView(bytes);
    final seed = view.getUint32(0x40, Endian.little);
    final nonce = Uint8List(8);
    final nonceView = ByteData.sublistView(nonce);
    nonceView.setUint32(0, seed ^ seedMask, Endian.little);
    nonceView.setUint32(4, seed, Endian.little);

    final engine = Salsa20Engine()
      ..init(false, ParametersWithIV<KeyParameter>(KeyParameter(_key), nonce));

    final decrypted = Uint8List(bytes.length);
    engine.processBytes(bytes, 0, bytes.length, decrypted, 0);

    final magic = ByteData.sublistView(decrypted).getUint32(0, Endian.little);
    if (magic != packetMagic) {
      throw Gt7PacketDecryptionException(
        'GT7 packet magic mismatch after Salsa20 decryption.',
      );
    }

    return decrypted;
  }
}
