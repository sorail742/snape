import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'network_transport.dart';

/// Internet transport backed by a single Firestore document per room. The
/// lobby phase (room creation, join-by-code, roster) is handled directly by
/// [OnlineLobbyScreen] against the `rooms/{code}` document; this class only
/// carries what [GameController] needs once play has started (`state` /
/// `roll_request`) plus chat, mirroring [NearbyTransport]'s contract.
class FirestoreTransport implements NetworkTransport {
  FirestoreTransport({required this.roomCode, required this.isHost}) {
    final room = _roomRef;

    // `includeMetadataChanges` also fires when Firestore flips between
    // serving from local cache (offline) and a live server connection, even
    // with no data change — that's what drives the reconnecting banner.
    _subs.add(room.snapshots(includeMetadataChanges: true).listen((snap) {
      final data = snap.data();
      if (data != null) {
        _hasSeenRoom = true;
        final state = data['state'];
        if (state != null) {
          _incomingController.add({
            'type': 'state',
            'snapshot': Map<String, dynamic>.from(state as Map),
          });
        }
      }
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(
          snap.metadata.isFromCache
              ? TransportConnectionState.reconnecting
              : TransportConnectionState.connected,
        );
      }
    }));

    if (isHost) {
      _subs.add(_requestsRef.snapshots().listen((snap) {
        for (final change in snap.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final d = change.doc.data();
            if (d != null) {
              _incomingController.add({
                'type': 'roll_request',
                'playerIndex': d['playerIndex'],
              });
            }
            change.doc.reference.delete();
          }
        }
      }));
    }

    _subs.add(_chatRef.orderBy('ts').snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data();
          if (d != null) {
            _incomingController.add({
              'type': 'chat',
              'from': d['from'],
              'text': d['text'],
              'id': d['id'],
            });
          }
        }
      }
    }));

    _subs.add(_emotesRef.orderBy('ts').snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data();
          if (d != null) {
            _incomingController.add({
              'type': 'emote',
              'from': d['from'],
              'emoji': d['emoji'],
            });
          }
        }
      }
    }));
  }

  final String roomCode;
  final bool isHost;

  final _incomingController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<TransportConnectionState>.broadcast();
  final List<StreamSubscription<dynamic>> _subs = [];
  bool _hasSeenRoom = false;

  DocumentReference<Map<String, dynamic>> get _roomRef =>
      FirebaseFirestore.instance.collection('rooms').doc(roomCode);

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _roomRef.collection('requests');

  CollectionReference<Map<String, dynamic>> get _chatRef =>
      _roomRef.collection('chat');

  CollectionReference<Map<String, dynamic>> get _emotesRef =>
      _roomRef.collection('emotes');

  @override
  Stream<Map<String, dynamic>> get incoming => _incomingController.stream;

  @override
  bool get isConnected => _hasSeenRoom;

  @override
  Stream<TransportConnectionState> get connectionState => _connectionStateController.stream;

  @override
  void send(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'state':
        _roomRef.set({'state': message['snapshot']}, SetOptions(merge: true));
        break;
      case 'roll_request':
        _requestsRef.add({
          'playerIndex': message['playerIndex'],
          'ts': FieldValue.serverTimestamp(),
        });
        break;
      case 'chat':
        _chatRef.add({
          'from': message['from'],
          'text': message['text'],
          'id': message['id'],
          'ts': FieldValue.serverTimestamp(),
        });
        break;
      case 'emote':
        _emotesRef.add({
          'from': message['from'],
          'emoji': message['emoji'],
          'ts': FieldValue.serverTimestamp(),
        });
        break;
    }
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _incomingController.close();
    await _connectionStateController.close();
  }
}
