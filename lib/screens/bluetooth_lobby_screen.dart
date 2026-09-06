import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../game/game_controller.dart';
import '../models/board_theme.dart';
import '../models/game_mode.dart';
import '../models/player.dart';
import '../network/chat_controller.dart';
import '../network/nearby_transport.dart';
import '../services/settings_service.dart';
import '../widgets/animated_list_entry.dart';
import '../widgets/chat_panel.dart';
import 'game_screen.dart';

enum _Role { none, host, client }

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class BluetoothLobbyScreen extends StatefulWidget {
  const BluetoothLobbyScreen({super.key});

  @override
  State<BluetoothLobbyScreen> createState() => _BluetoothLobbyScreenState();
}

class _RosterEntry {
  _RosterEntry({required this.name, required this.color, required this.avatarEmoji});
  final String name;
  final Color color;
  final String avatarEmoji;
}

class _BluetoothLobbyScreenState extends State<BluetoothLobbyScreen> {
  static const _availableColors = <Color>[
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
  ];

  final TextEditingController _nameController =
      TextEditingController(text: 'Joueur');
  Color _myColor = _availableColors[0];
  String _myAvatar = playerAvatarEmojis.first;
  BoardTheme _theme = BoardTheme.classic;

  _Role _role = _Role.none;
  NearbyTransport? _transport;
  ChatController? _chatController;
  StreamSubscription<Map<String, dynamic>>? _messageSub;
  StreamSubscription<DiscoveredEndpoint>? _discoverySub;
  StreamSubscription<String>? _connectedSub;

  final List<_RosterEntry> _roster = [];
  final List<DiscoveredEndpoint> _discovered = [];
  String? _connectingToId;
  bool _connectedToHost = false;
  String? _error;
  bool _requestingPermissions = false;
  bool _showOpenSettings = false;

  @override
  void initState() {
    super.initState();
    SettingsService.instance.loadDefaultThemeId().then((id) {
      if (mounted) setState(() => _theme = BoardTheme.byId(id));
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _discoverySub?.cancel();
    _connectedSub?.cancel();
    _chatController?.dispose();
    _transport?.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _myName => _nameController.text.trim().isEmpty
      ? 'Joueur'
      : _nameController.text.trim();

  Future<void> _pickAvatar() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          alignment: WrapAlignment.center,
          children: playerAvatarEmojis
              .map(
                (e) => IconButton(
                  iconSize: 36,
                  onPressed: () => Navigator.of(context).pop(e),
                  icon: Text(e, style: const TextStyle(fontSize: 28)),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) setState(() => _myAvatar = selected);
  }

  Future<bool> _requestPermissions() async {
    setState(() => _requestingPermissions = true);
    final result = await NearbyTransport.ensurePermissions();
    setState(() => _requestingPermissions = false);
    if (!result.granted && mounted) {
      setState(() {
        _showOpenSettings = result.permanentlyDenied;
        _lastTechnicalError = null;
        _error = result.permanentlyDenied
            ? 'Des permissions ont été refusées définitivement.'
            : 'Des permissions sont nécessaires pour trouver des joueurs à proximité.';
      });
    } else {
      setState(() => _showOpenSettings = false);
    }
    return result.granted;
  }

  /// Turns a raw exception into a short, non-technical explanation. The
  /// underlying `nearby_connections` errors are Android platform exceptions
  /// (Bluetooth/location turned off, Play Services issue, etc.) that mean
  /// nothing to a player, so we always show the same actionable checklist
  /// instead and keep the raw text only as optional technical detail.
  String _friendlyBluetoothError(Object e) {
    _lastTechnicalError = e.toString();
    _showOpenSettings = true;
    return 'Impossible de se connecter en Bluetooth pour le moment.';
  }

  String? _lastTechnicalError;

  Future<void> _becomeHost() async {
    if (!await _requestPermissions()) return;
    final transport = NearbyTransport(localUserName: _myName);
    setState(() {
      _role = _Role.host;
      _transport = transport;
      _chatController = ChatController(transport: transport);
      _roster
        ..clear()
        ..add(_RosterEntry(name: _myName, color: _myColor, avatarEmoji: _myAvatar));
      _error = null;
    });
    _messageSub = transport.incoming.listen(_onHostMessage);
    try {
      await transport.startHosting();
    } catch (e) {
      setState(() => _error = _friendlyBluetoothError(e));
    }
  }

  void _onHostMessage(Map<String, dynamic> message) {
    if (message['type'] == 'hello') {
      final name = message['name'] as String? ?? 'Joueur';
      final colorValue = message['color'] as int?;
      final avatar = message['avatar'] as String? ?? playerAvatarEmojis.first;
      setState(() {
        _roster.add(_RosterEntry(
          name: name,
          color: colorValue != null ? Color(colorValue) : Colors.grey,
          avatarEmoji: avatar,
        ));
      });
      _broadcastRoster();
    }
  }

  void _broadcastRoster() {
    _transport?.send({
      'type': 'roster',
      'players': _roster
          .map((e) => {'name': e.name, 'color': e.color.toARGB32(), 'avatar': e.avatarEmoji})
          .toList(),
    });
  }

  Future<void> _startGameAsHost() async {
    final transport = _transport;
    if (transport == null || _roster.length < 2) return;
    transport.send({
      'type': 'game_start',
      'theme': _theme.id,
      'players': _roster
          .map((e) => {'name': e.name, 'color': e.color.toARGB32(), 'avatar': e.avatarEmoji})
          .toList(),
    });
    final players =
        _roster.map((e) => Player(name: e.name, color: e.color, avatarEmoji: e.avatarEmoji)).toList();
    // Ownership of the transport moves to the GameController below: this
    // screen is about to be popped by pushReplacement, which runs our
    // dispose() — null it out here so that doesn't tear down the transport
    // the new GameScreen is about to keep using.
    _transport = null;
    _goToGame(
      controller: GameController(
        players: players,
        transport: transport,
        isHost: true,
        localPlayerIndex: 0,
      ),
    );
  }

  Future<void> _becomeClient() async {
    if (!await _requestPermissions()) return;
    final transport = NearbyTransport(localUserName: _myName);
    setState(() {
      _role = _Role.client;
      _transport = transport;
      _chatController = ChatController(transport: transport);
      _discovered.clear();
      _error = null;
    });
    _discoverySub = transport.discovered.listen((endpoint) {
      setState(() {
        if (!_discovered.any((e) => e.id == endpoint.id)) {
          _discovered.add(endpoint);
        }
      });
    });
    _connectedSub = transport.endpointConnected.listen((_) {
      setState(() => _connectedToHost = true);
      transport.send({
        'type': 'hello',
        'name': _myName,
        'color': _myColor.toARGB32(),
        'avatar': _myAvatar,
      });
    });
    _messageSub = transport.incoming.listen(_onClientMessage);
    try {
      await transport.startDiscovery();
    } catch (e) {
      setState(() => _error = _friendlyBluetoothError(e));
    }
  }

  void _onClientMessage(Map<String, dynamic> message) {
    if (message['type'] == 'roster') {
      final list = List<Map<String, dynamic>>.from(
        (message['players'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      setState(() {
        _roster
          ..clear()
          ..addAll(list.map((e) => _RosterEntry(
                name: e['name'] as String,
                color: Color(e['color'] as int),
                avatarEmoji: e['avatar'] as String? ?? playerAvatarEmojis.first,
              )));
      });
    } else if (message['type'] == 'game_start') {
      final list = List<Map<String, dynamic>>.from(
        (message['players'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      final players = list
          .map((e) => Player(
                name: e['name'] as String,
                color: Color(e['color'] as int),
                avatarEmoji: e['avatar'] as String? ?? playerAvatarEmojis.first,
              ))
          .toList();
      final myIndex = players.indexWhere((p) => p.name == _myName);
      final theme = BoardTheme.byId(message['theme'] as String? ?? 'classic');
      final transport = _transport;
      // Ownership moves to the GameController below; see the matching note
      // in _startGameAsHost for why this must not be disposed from here on.
      _transport = null;
      _goToGame(
        controller: GameController(
          players: players,
          transport: transport,
          isHost: false,
          localPlayerIndex: myIndex == -1 ? 0 : myIndex,
        ),
        theme: theme,
      );
    }
  }

  void _connectToEndpoint(DiscoveredEndpoint endpoint) async {
    setState(() => _connectingToId = endpoint.id);
    // Remembered by name (not endpoint id, which can change) so this
    // transport can find its way back to the same host on its own if the
    // connection drops mid-match.
    _transport?.rememberHostForReconnect(endpoint.name);
    try {
      await _transport?.connectTo(endpoint.id);
    } catch (e) {
      setState(() {
        _error = _friendlyBluetoothError(e);
        _connectingToId = null;
      });
    }
  }

  void _goToGame({required GameController controller, BoardTheme? theme}) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          controller: controller,
          theme: theme ?? _theme,
          mode: GameModeKind.bluetooth,
          myName: _myName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth · à proximité'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _role == _Role.none ? _buildRoleChoice() : _buildLobby(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChoice() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: _myColor,
                  child: Text(_myAvatar, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ton nom',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _availableColors.map((color) {
              final selected = color == _myColor;
              return GestureDetector(
                onTap: () => setState(() => _myColor = color),
                child: CircleAvatar(
                  backgroundColor: color,
                  radius: selected ? 18 : 14,
                  child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Thème du plateau :', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: BoardTheme.all.map((theme) {
              final selected = theme.id == _theme.id;
              return ChoiceChip(
                label: Text(theme.label),
                selected: selected,
                onSelected: (_) => setState(() => _theme = theme),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          if (_error != null) _buildErrorCard(),
          if (_requestingPermissions) const LinearProgressIndicator(),
          FilledButton.icon(
            onPressed: _requestingPermissions ? null : _becomeHost,
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('Héberger une partie'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _requestingPermissions ? null : _becomeClient,
            icon: const Icon(Icons.search),
            label: const Text('Rejoindre une partie à proximité'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bluetooth_disabled_rounded, color: Color(0xFFEF6C00)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Vérifie ces 3 points sur ce téléphone :'),
          const SizedBox(height: 6),
          const _ChecklistLine(text: 'Le Bluetooth est activé'),
          const _ChecklistLine(text: 'La localisation (GPS) est activée'),
          const _ChecklistLine(text: 'L\'application a la permission Bluetooth/position'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_showOpenSettings)
                OutlinedButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Ouvrir les réglages de l\'app'),
                ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _error = null;
                  _showOpenSettings = false;
                  _lastTechnicalError = null;
                  _role = _Role.none;
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
          if (_lastTechnicalError != null)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Détail technique', style: TextStyle(fontSize: 12)),
              children: [
                Text(
                  _lastTechnicalError!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLobby() {
    return SingleChildScrollView(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) _buildErrorCard(),
        if (_role == _Role.host) ...[
          Text(
            'En attente de joueurs… partage ton téléphone à proximité pour qu\'ils te trouvent.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text('Joueurs (${_roster.length})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._roster.map(
            (p) => AnimatedListEntry(
              key: ValueKey(p.name),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: p.color, child: Text(p.avatarEmoji)),
                title: Text(p.name),
              ),
            ),
          ),
        ] else ...[
          if (!_connectedToHost) ...[
            Text('Parties trouvées à proximité :', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_discovered.isEmpty) const Text('Recherche en cours…'),
            ..._discovered.map(
              (e) => Card(
                child: ListTile(
                  leading: const Icon(Icons.videogame_asset),
                  title: Text(e.name),
                  trailing: _connectingToId == e.id
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  onTap: () => _connectToEndpoint(e),
                ),
              ),
            ),
          ] else ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 40),
            const SizedBox(height: 8),
            const Text('Connecté ! En attente que l\'hôte lance la partie…'),
            const SizedBox(height: 16),
            Text('Joueurs (${_roster.length})', style: Theme.of(context).textTheme.titleMedium),
            ..._roster.map(
              (p) => AnimatedListEntry(
                key: ValueKey(p.name),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: p.color, child: Text(p.avatarEmoji)),
                  title: Text(p.name),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 16),
        if (_chatController != null)
          SizedBox(
            height: 220,
            child: Card(
              child: ChatPanel(controller: _chatController!, myName: _myName),
            ),
          ),
        if (_role == _Role.host) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _roster.length >= 2 ? _startGameAsHost : null,
            icon: const Icon(Icons.play_arrow),
            label: Text(
              _roster.length >= 2
                  ? 'Démarrer la partie'
                  : 'En attente d\'au moins 1 autre joueur…',
            ),
          ),
        ],
      ],
      ),
    );
  }
}
