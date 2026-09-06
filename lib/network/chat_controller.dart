import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'network_transport.dart';

class ChatMessage {
  ChatMessage({required this.from, required this.text});
  final String from;
  final String text;
}

/// Owns the chat message list for the lifetime of a [NetworkTransport],
/// independent of whether any `ChatPanel` UI is currently on screen. This is
/// what lets messages sent while the chat sheet is closed still arrive and
/// be counted, instead of being silently dropped by a listener that only
/// existed while the sheet was open.
class ChatController extends ChangeNotifier {
  ChatController({required this.transport}) {
    _sub = transport.incoming.listen(_onMessage);
  }

  final NetworkTransport transport;
  final List<ChatMessage> messages = [];
  int unreadCount = 0;
  StreamSubscription<Map<String, dynamic>>? _sub;
  final Random _random = Random();

  /// Ids of messages already added locally via [send]. FirestoreTransport
  /// echoes a sender's own write back through the same `incoming` stream
  /// used for messages from other players (it's just listening on the
  /// collection it writes to) — without this, the sender would see their
  /// own message twice: once from the optimistic local add, once from that
  /// echo arriving back through [_onMessage].
  final Set<String> _ownMessageIds = {};

  void _onMessage(Map<String, dynamic> message) {
    if (message['type'] != 'chat') return;
    final id = message['id'] as String?;
    if (id != null && _ownMessageIds.remove(id)) return;
    messages.add(ChatMessage(
      from: message['from'] as String? ?? '?',
      text: message['text'] as String? ?? '',
    ));
    unreadCount++;
    notifyListeners();
  }

  void send(String myName, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 31)}';
    _ownMessageIds.add(id);
    transport.send({'type': 'chat', 'from': myName, 'text': trimmed, 'id': id});
    messages.add(ChatMessage(from: myName, text: trimmed));
    notifyListeners();
  }

  void markAllRead() {
    if (unreadCount == 0) return;
    unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
