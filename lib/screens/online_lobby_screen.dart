import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_controller.dart';
import '../models/board_theme.dart';
import '../models/game_mode.dart';
import '../models/player.dart';
import '../network/chat_controller.dart';
import '../network/firestore_transport.dart';
import '../services/firebase_bootstrap.dart';
import '../services/settings_service.dart';
import '../widgets/animated_list_entry.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/chat_panel.dart';
import 'game_screen.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  late final Future<String?> _initFuture = FirebaseBootstrap.ensureInitialized();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('En ligne · Internet'),
      ),
      body: FutureBuilder<String?>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data != null) {
            return _FirebaseSetupNeeded(error: snapshot.data!);
          }
          return const _OnlineLobbyBody();
        },
      ),
    );
  }
}

class _FirebaseSetupNeeded extends StatelessWidget {
  const _FirebaseSetupNeeded({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: Colors.orange),
              const SizedBox(height: 12),
              Text(
                'Le mode en ligne n\'est pas encore configuré',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pour activer le jeu en ligne (Firebase), à faire une seule fois :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const _Step(n: 1, text: 'Crée un projet gratuit sur console.firebase.google.com'),
              const _Step(n: 2, text: 'Active Firestore Database dans ce projet (mode test)'),
              const _Step(
                n: 3,
                text: 'Dans le dossier du projet Flutter, lance :\n'
                    'dart pub global activate flutterfire_cli\n'
                    'flutterfire configure',
              ),
              const _Step(n: 4, text: 'Relance l\'application'),
              const SizedBox(height: 20),
              ExpansionTile(
                title: const Text('Détail technique de l\'erreur'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(error, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});
  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 12, child: Text('$n', style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _OnlineLobbyBody extends StatefulWidget {
  const _OnlineLobbyBody();

  @override
  State<_OnlineLobbyBody> createState() => _OnlineLobbyBodyState();
}

enum _Role { none, host, client }

class _OnlineLobbyBodyState extends State<_OnlineLobbyBody> {
  static const _availableColors = <Color>[
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
  ];
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  final TextEditingController _nameController = TextEditingController(text: 'Joueur');
  final TextEditingController _codeController = TextEditingController();
  Color _myColor = _availableColors[0];
  String _myAvatar = playerAvatarEmojis.first;
  BoardTheme _theme = BoardTheme.classic;
  bool _isPublic = false;

  /// Distinguishes this player's own entry in Firestore's `players` array
  /// from everyone else's, even when names/colors/avatars are left at their
  /// identical defaults — otherwise `arrayUnion` silently collapses two
  /// byte-for-byte identical map entries into one, and two players who
  /// never customized anything would appear as a single "Joueur".
  final String _myId = '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 31)}';

  _Role _role = _Role.none;
  String? _roomCode;
  String? _error;
  bool _busy = false;
  bool _navigated = false;
  FirestoreTransport? _transport;
  ChatController? _chatController;

  String get _myName =>
      _nameController.text.trim().isEmpty ? 'Joueur' : _nameController.text.trim();

  DocumentReference<Map<String, dynamic>>? get _roomRef =>
      _roomCode == null ? null : FirebaseFirestore.instance.collection('rooms').doc(_roomCode);

  @override
  void initState() {
    super.initState();
    SettingsService.instance.loadDefaultThemeId().then((id) {
      if (mounted) setState(() => _theme = BoardTheme.byId(id));
    });
  }

  @override
  void dispose() {
    _chatController?.dispose();
    _transport?.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

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

  String _generateCode() {
    final random = Random();
    return List.generate(5, (_) => _codeChars[random.nextInt(_codeChars.length)]).join();
  }

  Future<void> _createRoom() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final firestore = FirebaseFirestore.instance;
      String code = _generateCode();
      for (var attempt = 0; attempt < 5; attempt++) {
        final existing = await firestore.collection('rooms').doc(code).get();
        if (!existing.exists) break;
        code = _generateCode();
      }
      await firestore.collection('rooms').doc(code).set({
        'status': 'lobby',
        'theme': _theme.id,
        'isPublic': _isPublic,
        'hostName': _myName,
        'players': [
          {'id': _myId, 'name': _myName, 'color': _myColor.toARGB32(), 'avatar': _myAvatar},
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _role = _Role.host;
        _roomCode = code;
        _transport = FirestoreTransport(roomCode: code, isHost: true);
        _chatController = ChatController(transport: _transport!);
      });
    } catch (e) {
      setState(() => _error = 'Impossible de créer le salon : $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Entre un code de salon.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ref = FirebaseFirestore.instance.collection('rooms').doc(code);
      final snap = await ref.get();
      if (!snap.exists) {
        setState(() => _error = 'Aucun salon avec ce code.');
        return;
      }
      await ref.update({
        'players': FieldValue.arrayUnion([
          {'id': _myId, 'name': _myName, 'color': _myColor.toARGB32(), 'avatar': _myAvatar},
        ]),
      });
      setState(() {
        _role = _Role.client;
        _roomCode = code;
        _transport = FirestoreTransport(roomCode: code, isHost: false);
        _chatController = ChatController(transport: _transport!);
      });
    } catch (e) {
      setState(() => _error = 'Impossible de rejoindre : $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  /// Watches a match without joining it: connects the same read-only
  /// transport as a client, but never adds itself to the room's roster, so
  /// [GameController.isSpectator] keeps the dice permanently disabled.
  Future<void> _watchRoom(String code) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ref = FirebaseFirestore.instance.collection('rooms').doc(code);
      final snap = await ref.get();
      final data = snap.data();
      if (!snap.exists || data == null) {
        setState(() => _error = 'Aucun salon avec ce code.');
        return;
      }
      final playersData = List<Map<String, dynamic>>.from(
        (data['players'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      final players = playersData
          .map((e) => Player(
                name: e['name'] as String,
                color: Color(e['color'] as int),
                avatarEmoji: e['avatar'] as String? ?? playerAvatarEmojis.first,
              ))
          .toList();
      if (players.isEmpty) {
        setState(() => _error = 'Ce salon n\'a pas encore de joueurs à regarder.');
        return;
      }
      final transport = FirestoreTransport(roomCode: code, isHost: false);
      final theme = BoardTheme.byId(data['theme'] as String? ?? 'classic');
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GameScreen(
            controller: GameController(
              players: players,
              transport: transport,
              isHost: false,
              isSpectator: true,
            ),
            theme: theme,
            mode: GameModeKind.online,
            titleOverride: 'Spectateur',
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Impossible de regarder ce salon : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startGame(List<Map<String, dynamic>> players) async {
    await _roomRef?.set({'status': 'playing'}, SetOptions(merge: true));
  }

  void _goToGame({
    required List<Map<String, dynamic>> playersData,
    required bool isHost,
    required String themeId,
  }) {
    if (_navigated) return;
    _navigated = true;
    final players = playersData
        .map((e) => Player(
              name: e['name'] as String,
              color: Color(e['color'] as int),
              avatarEmoji: e['avatar'] as String? ?? playerAvatarEmojis.first,
            ))
        .toList();
    // Match by the unique id we embedded when creating/joining the room,
    // not by name — two players can share the same (possibly default) name.
    final myIndex = playersData.indexWhere((e) => e['id'] == _myId);
    // Ownership of the transport moves to the GameController below: this
    // screen is about to be popped by pushReplacement, which will run our
    // dispose() and, until now, closed the transport it had just handed off
    // — killing all further sync (state + chat) for both peers after the
    // very first move. Null it out here so our dispose() leaves it alone.
    final transport = _transport;
    _transport = null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          controller: GameController(
            players: players,
            transport: transport,
            isHost: isHost,
            localPlayerIndex: myIndex == -1 ? 0 : myIndex,
          ),
          theme: BoardTheme.byId(themeId),
          mode: GameModeKind.online,
          myName: _myName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _role == _Role.none ? _buildRoleChoice() : _buildLobby(),
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
                  decoration: const InputDecoration(labelText: 'Ton nom', border: OutlineInputBorder()),
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
          const SizedBox(height: 24),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Color(0xFFEF6C00)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          if (_busy) const LinearProgressIndicator(),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v ?? false),
            title: const Text('Salon public'),
            subtitle: const Text('Visible par tout le monde, sans code à partager'),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _createRoom,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Créer un salon'),
          ),
          const SizedBox(height: 16),
          const Text('— ou —', textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Code du salon',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _joinRoom,
            icon: const Icon(Icons.login),
            label: const Text('Rejoindre'),
          ),
          const SizedBox(height: 24),
          Text('Parties publiques', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildPublicRooms(),
        ],
      ),
    );
  }

  Widget _buildPublicRooms() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('isPublic', isEqualTo: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final rooms = snapshot.data!.docs
            .where((d) => (d.data()['status'] as String? ?? 'lobby') == 'lobby')
            .toList();
        if (rooms.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucun salon public ouvert pour le moment.', style: TextStyle(color: Colors.black54)),
          );
        }
        return Column(
          children: rooms.map((doc) {
            final data = doc.data();
            final players = List<Map<String, dynamic>>.from(
              (data['players'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
            );
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.public_rounded, color: Color(0xFF43A047)),
                title: Text(data['hostName'] as String? ?? 'Salon ${doc.id}'),
                subtitle: Text('${players.length} joueur${players.length > 1 ? 's' : ''} · code ${doc.id}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Regarder',
                      icon: const Icon(Icons.visibility_outlined),
                      onPressed: _busy ? null : () => _watchRoom(doc.id),
                    ),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
                onTap: _busy
                    ? null
                    : () {
                        _codeController.text = doc.id;
                        _joinRoom();
                      },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLobby() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _roomRef?.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final players = data == null
            ? <Map<String, dynamic>>[]
            : List<Map<String, dynamic>>.from(
                (data['players'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
              );
        final status = data?['status'] as String? ?? 'lobby';
        final themeId = data?['theme'] as String? ?? _theme.id;

        if (status == 'playing' && data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _goToGame(playersData: players, isHost: _role == _Role.host, themeId: themeId);
          });
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_role == _Role.host && _roomCode != null) ...[
                const Text('Code du salon à partager :', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _roomCode!));
                    showAppSnackBar(context, 'Code copié !', icon: Icons.copy_rounded);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF43A047), width: 2),
                    ),
                    child: Text(
                      _roomCode!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('Joueurs (${players.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...players.map(
                (p) => AnimatedListEntry(
                  key: ValueKey(p['id'] ?? p['name']),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(p['color'] as int),
                      child: Text(p['avatar'] as String? ?? playerAvatarEmojis.first),
                    ),
                    title: Text(p['name'] as String),
                  ),
                ),
              ),
              if (_role == _Role.client) ...[
                const SizedBox(height: 8),
                const Text('En attente que l\'hôte lance la partie…'),
              ],
              const SizedBox(height: 16),
              if (_chatController != null)
                SizedBox(
                  height: 220,
                  child: Card(child: ChatPanel(controller: _chatController!, myName: _myName)),
                ),
              if (_role == _Role.host) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: players.length >= 2 ? () => _startGame(players) : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    players.length >= 2
                        ? 'Démarrer la partie'
                        : 'En attente d\'au moins 1 autre joueur…',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
