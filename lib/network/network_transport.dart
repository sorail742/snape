/// Transport-agnostic messaging channel used to synchronise a game session
/// across devices (Bluetooth/WiFi via [NearbyTransport] or the internet via
/// a Firestore-backed transport).
///
/// Messages are small JSON-serialisable maps with a `type` key:
/// - `state`: full [GameSnapshot] broadcast by the host after every change.
/// - `roll_request`: sent by a client asking the host to roll for
///   `playerIndex`.
/// - `roster`: authoritative player list broadcast by the host during the
///   lobby phase.
/// - `hello`: sent by a client when it joins, announcing its name/color.
/// - `chat`: a lobby/in-game chat line.
/// High-level connectivity state a UI can show a banner for, independent of
/// the underlying transport (Bluetooth actively retries; the internet
/// transport mostly relies on Firestore's own offline queuing, so it stays
/// `connected` once the room is first seen).
enum TransportConnectionState { connected, reconnecting, disconnected }

abstract class NetworkTransport {
  /// Broadcast stream of decoded messages from every peer. Must support
  /// multiple independent listeners (game sync + chat can both subscribe).
  Stream<Map<String, dynamic>> get incoming;

  /// True once at least one remote peer is connected.
  bool get isConnected;

  /// Broadcast stream of connectivity changes, for a "reconnexion en
  /// cours…" banner. Not required to emit more than once.
  Stream<TransportConnectionState> get connectionState;

  void send(Map<String, dynamic> message);

  Future<void> dispose();
}
