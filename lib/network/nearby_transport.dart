import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import 'network_transport.dart';

class DiscoveredEndpoint {
  DiscoveredEndpoint({required this.id, required this.name});
  final String id;
  final String name;
}

class NearbyPermissionResult {
  NearbyPermissionResult({required this.granted, required this.permanentlyDenied});
  final bool granted;
  final bool permanentlyDenied;
}

/// Local multiplayer transport over Bluetooth/WiFi Direct using Google's
/// Nearby Connections API. Uses a star topology: the host advertises and
/// accepts connections from every client; clients only ever connect to the
/// host, never to each other. Because of that, the host must relay `chat`
/// messages it receives from one client on to every other client.
class NearbyTransport implements NetworkTransport {
  NearbyTransport({required this.localUserName});

  static const _serviceId = 'com.mrmrs.serpentsparty.game';

  final String localUserName;
  final Set<String> _connectedEndpoints = {};

  final _incomingController = StreamController<Map<String, dynamic>>.broadcast();
  final _discoveredController = StreamController<DiscoveredEndpoint>.broadcast();
  final _lostController = StreamController<String>.broadcast();
  final _connectedController = StreamController<String>.broadcast();
  final _disconnectedController = StreamController<String>.broadcast();
  final _connectionStateController = StreamController<TransportConnectionState>.broadcast();

  @override
  Stream<Map<String, dynamic>> get incoming => _incomingController.stream;

  Stream<DiscoveredEndpoint> get discovered => _discoveredController.stream;
  Stream<String> get lostEndpoint => _lostController.stream;
  Stream<String> get endpointConnected => _connectedController.stream;
  Stream<String> get endpointDisconnected => _disconnectedController.stream;

  @override
  Stream<TransportConnectionState> get connectionState => _connectionStateController.stream;

  @override
  bool get isConnected => _connectedEndpoints.isNotEmpty;

  /// The client role calls this right after connecting so that, if the
  /// connection later drops mid-match, this transport can look for that
  /// same host by name and reconnect on its own — the human shouldn't have
  /// to back out to the lobby and rejoin by hand.
  String? _reconnectHostName;
  bool _reconnecting = false;

  void rememberHostForReconnect(String hostName) {
    _reconnectHostName = hostName;
  }

  int get connectedCount => _connectedEndpoints.length;

  /// Requests every runtime permission Nearby Connections needs.
  ///
  /// Deliberately does NOT request [Permission.bluetooth]: that legacy
  /// permission is a normal (install-time, non-runtime) permission on
  /// Android <12 and is superseded by the three granular ones below on
  /// Android 12+. On Android 12+ it can never resolve to granted (it isn't
  /// declared for that SDK level), so including it here would make this
  /// check fail forever regardless of what the user actually allows.
  static Future<NearbyPermissionResult> ensurePermissions() async {
    final statuses = await [
      Permission.location,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();
    final granted = statuses.values.every((s) => s.isGranted || s.isLimited);
    final permanentlyDenied = statuses.values.any((s) => s.isPermanentlyDenied);
    return NearbyPermissionResult(granted: granted, permanentlyDenied: permanentlyDenied);
  }

  Future<void> startHosting() async {
    await Nearby().startAdvertising(
      localUserName,
      Strategy.P2P_STAR,
      serviceId: _serviceId,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: (id, status) => _onConnectionResult(id, status),
      onDisconnected: _onDisconnected,
    );
  }

  Future<void> startDiscovery() async {
    await Nearby().startDiscovery(
      localUserName,
      Strategy.P2P_STAR,
      serviceId: _serviceId,
      onEndpointFound: (id, name, serviceId) {
        if (!_disposed && !_discoveredController.isClosed) {
          _discoveredController.add(DiscoveredEndpoint(id: id, name: name));
        }
      },
      onEndpointLost: (id) {
        if (id != null && !_disposed && !_lostController.isClosed) {
          _lostController.add(id);
        }
      },
    );
  }

  Future<void> connectTo(String endpointId) async {
    await Nearby().requestConnection(
      localUserName,
      endpointId,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: (id, status) => _onConnectionResult(id, status),
      onDisconnected: _onDisconnected,
    );
  }

  bool _disposed = false;

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (_disposed || payload.type != PayloadType.BYTES || payload.bytes == null) return;
        try {
          final decoded = jsonDecode(utf8.decode(payload.bytes!));
          final map = Map<String, dynamic>.from(decoded as Map);
          if (!_incomingController.isClosed) _incomingController.add(map);
          if (map['type'] == 'chat' || map['type'] == 'emote') {
            _relayToOthers(exceptEndpointId: endpointId, message: map);
          }
        } catch (_) {
          // Ignore malformed payloads.
        }
      },
    );
  }

  void _onConnectionResult(String id, Status status) {
    if (_disposed) return;
    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(id);
      if (!_connectedController.isClosed) _connectedController.add(id);
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(TransportConnectionState.connected);
      }
    }
  }

  void _onDisconnected(String id) {
    _connectedEndpoints.remove(id);
    if (_disposed || _disconnectedController.isClosed) return;
    _disconnectedController.add(id);
    if (_connectedEndpoints.isEmpty) {
      // Shown on both ends: the client actively retries below, while the
      // host just keeps advertising (already running) and waits — either
      // way the banner tells the human what's happening instead of a dice
      // that's mysteriously greyed out.
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(TransportConnectionState.reconnecting);
      }
      if (_reconnectHostName != null) {
        unawaited(_attemptReconnect());
      }
    }
  }

  /// Restarts discovery and reconnects automatically to the host we were
  /// paired with, by name (its endpoint id may change between sessions).
  /// Gives up after 30s so the player isn't stuck forever if the host
  /// really is gone.
  Future<void> _attemptReconnect() async {
    if (_disposed || _reconnecting) return;
    _reconnecting = true;
    final targetName = _reconnectHostName;
    final deadline = DateTime.now().add(const Duration(seconds: 30));

    late final StreamSubscription<DiscoveredEndpoint> matchSub;
    matchSub = discovered.listen((endpoint) {
      if (endpoint.name != targetName) return;
      unawaited(connectTo(endpoint.id).catchError((Object e) {
        debugPrint('NearbyTransport: reconnect attempt failed: $e');
      }));
    });

    try {
      await Nearby().startDiscovery(
        localUserName,
        Strategy.P2P_STAR,
        serviceId: _serviceId,
        onEndpointFound: (id, name, serviceId) {
          if (!_disposed && !_discoveredController.isClosed) {
            _discoveredController.add(DiscoveredEndpoint(id: id, name: name));
          }
        },
        onEndpointLost: (id) {
          if (id != null && !_disposed && !_lostController.isClosed) {
            _lostController.add(id);
          }
        },
      );
    } catch (e) {
      debugPrint('NearbyTransport: could not restart discovery for reconnect: $e');
    }

    while (!_disposed && _connectedEndpoints.isEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    await matchSub.cancel();
    try {
      await Nearby().stopDiscovery();
    } catch (_) {
      // Best-effort.
    }
    _reconnecting = false;

    if (_disposed) return;
    if (_connectionStateController.isClosed) return;
    _connectionStateController.add(
      _connectedEndpoints.isEmpty
          ? TransportConnectionState.disconnected
          : TransportConnectionState.connected,
    );
  }

  void _relayToOthers({
    required String exceptEndpointId,
    required Map<String, dynamic> message,
  }) {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(message)));
    for (final endpointId in _connectedEndpoints) {
      if (endpointId != exceptEndpointId) {
        _sendBytesSafely(endpointId, bytes);
      }
    }
  }

  @override
  void send(Map<String, dynamic> message) {
    if (_connectedEndpoints.isEmpty) return;
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(message)));
    for (final endpointId in _connectedEndpoints) {
      _sendBytesSafely(endpointId, bytes);
    }
  }

  /// `Nearby().sendBytesPayload` returns a Future we intentionally don't
  /// await (state broadcasts fire on every animation frame and must not
  /// block the game loop). Left unhandled, a rejected Future here becomes
  /// an uncaught async exception days later — on some devices the plugin
  /// does reject mid-transfer — which used to crash the whole app. Catch
  /// and log instead.
  void _sendBytesSafely(String endpointId, Uint8List bytes) {
    try {
      Nearby().sendBytesPayload(endpointId, bytes).catchError((Object e, StackTrace st) {
        debugPrint('NearbyTransport: sendBytesPayload failed for $endpointId: $e');
      });
    } catch (e) {
      debugPrint('NearbyTransport: sendBytesPayload threw synchronously for $endpointId: $e');
    }
  }

  Future<void> stopAdvertisingAndDiscovery() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
  }

  @override
  Future<void> dispose() async {
    // Flip the flag and stop the native side FIRST so any in-flight
    // callback that lands after this point is dropped (see the `_disposed`
    // guards above) instead of racing to add to a stream we're about to
    // close underneath it.
    _disposed = true;
    try {
      await Nearby().stopAllEndpoints();
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
    } catch (_) {
      // Best-effort: the platform side may already be stopped.
    }
    await _incomingController.close();
    await _discoveredController.close();
    await _lostController.close();
    await _connectedController.close();
    await _disconnectedController.close();
    await _connectionStateController.close();
  }
}
