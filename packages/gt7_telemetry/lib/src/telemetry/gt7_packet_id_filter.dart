class Gt7PacketIdFilter {
  int? _lastAcceptedPacketId;

  int? get lastAcceptedPacketId => _lastAcceptedPacketId;

  bool shouldAccept(int packetId) {
    final lastAcceptedPacketId = _lastAcceptedPacketId;
    if (lastAcceptedPacketId == null) {
      _lastAcceptedPacketId = packetId;
      return true;
    }

    final difference = (packetId - lastAcceptedPacketId) & 0xFFFFFFFF;
    if (difference == 0 || difference >= 0x80000000) {
      return false;
    }

    _lastAcceptedPacketId = packetId;
    return true;
  }

  void reset() {
    _lastAcceptedPacketId = null;
  }
}
