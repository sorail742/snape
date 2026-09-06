import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../game/game_controller.dart';
import '../models/achievement.dart';
import '../models/board_data.dart';
import '../models/board_theme.dart';
import '../models/game_history_entry.dart';
import '../models/game_mode.dart';
import '../models/player.dart';
import '../network/chat_controller.dart';
import '../network/network_transport.dart';
import '../services/settings_service.dart';
import '../services/stats_service.dart';
import '../widgets/board_painter.dart';
import '../widgets/chat_panel.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/dice_widget.dart';
import '../widgets/event_row.dart';
import '../widgets/player_avatar.dart';
import 'settings_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    this.theme = BoardTheme.classic,
    this.mode = GameModeKind.local,
    this.myName,
    this.onCampaignResult,
    this.onMatchWinner,
    this.titleOverride,
  });

  final GameController controller;
  final BoardTheme theme;
  final GameModeKind mode;

  /// Name of the local player, used to label chat messages in networked modes.
  final String? myName;

  /// Overrides the AppBar title (used by campaign stages to show their name
  /// instead of the generic mode label).
  final String? titleOverride;

  /// Reports back whether the human player won, for campaign stages — null
  /// outside campaign mode.
  final void Function(bool humanWon)? onCampaignResult;

  /// Reports the winning [Player] back to a tournament bracket — null
  /// outside tournament mode. When set, the win dialog swaps its normal
  /// "Rejouer"/"Fermer" actions for a single "Continuer le tournoi" that
  /// pops back to the bracket screen.
  final void Function(Player winner)? onMatchWinner;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

const _quickEmotes = ['😂', '😮', '👏', '😡', '🔥', '😅'];

class _FloatingEmote {
  _FloatingEmote({required this.id, required this.emoji, required this.from});
  final int id;
  final String emoji;
  final String? from;
}

class _GameScreenState extends State<GameScreen> {
  bool _winDialogShown = false;
  final Stopwatch _stopwatch = Stopwatch()..start();
  ChatController? _chatController;
  TransportConnectionState _connectionState = TransportConnectionState.connected;
  StreamSubscription<TransportConnectionState>? _connectionSub;
  StreamSubscription<Map<String, dynamic>>? _emoteSub;
  final List<_FloatingEmote> _floatingEmotes = [];
  int _emoteSeq = 0;
  StreamSubscription<AccelerometerEvent>? _shakeSub;
  DateTime _lastShakeAt = DateTime.fromMillisecondsSinceEpoch(0);
  DiceSkin _diceSkin = DiceSkin.classic;

  GameController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    final transport = _controller.transport;
    if (transport != null) {
      _chatController = ChatController(transport: transport)
        ..addListener(() => setState(() {}));
      _connectionSub = transport.connectionState.listen((state) {
        if (mounted) setState(() => _connectionState = state);
      });
      _emoteSub = transport.incoming.listen((message) {
        if (message['type'] == 'emote') {
          _showFloatingEmote(message['emoji'] as String? ?? '❓', message['from'] as String?);
        }
      });
    }
    SettingsService.instance.loadShakeToRollEnabled().then((enabled) {
      if (enabled && mounted) _startShakeDetection();
    });
    SettingsService.instance.loadDiceSkin().then((skin) {
      if (mounted) setState(() => _diceSkin = DiceSkin.values[skin]);
    });
  }

  /// A sharp shake (acceleration spike well above gravity, on any axis)
  /// rolls the dice, so a player doesn't have to reach for the screen —
  /// debounced to one roll per second so a single shake can't fire twice.
  void _startShakeDetection() {
    _shakeSub = accelerometerEventStream().listen((event) {
      final magnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final delta = (magnitude - 9.8).abs();
      if (delta < 18) return;
      final now = DateTime.now();
      if (now.difference(_lastShakeAt) < const Duration(seconds: 1)) return;
      _lastShakeAt = now;
      if (_controller.canLocalPlayerRoll && !_controller.isRolling && !_controller.isMoving) {
        _controller.rollDice();
      }
    });
  }

  void _sendEmote(String emoji) {
    final transport = _controller.transport;
    if (transport == null) return;
    try {
      transport.send({'type': 'emote', 'emoji': emoji, 'from': widget.myName ?? 'Moi'});
    } catch (e) {
      debugPrint('GameScreen: failed to send emote: $e');
    }
    _showFloatingEmote(emoji, null);
  }

  void _showFloatingEmote(String emoji, String? from) {
    final id = _emoteSeq++;
    setState(() => _floatingEmotes.add(_FloatingEmote(id: id, emoji: emoji, from: from)));
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _floatingEmotes.removeWhere((e) => e.id == id));
    });
  }

  @override
  void dispose() {
    _shakeSub?.cancel();
    _emoteSub?.cancel();
    _connectionSub?.cancel();
    _chatController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _confirmLeave() async {
    if (_controller.isGameOver) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la partie ?'),
        content: const Text('La partie en cours sera perdue si tu quittes maintenant.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Rester'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmLeave()) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: widget.theme.background,
        appBar: AppBar(
          title: Text(widget.titleOverride ?? widget.mode.label),
          backgroundColor: Colors.white,
          foregroundColor: widget.theme.accentDark,
          actions: [
            IconButton(
              tooltip: 'Journal de partie',
              icon: const Icon(Icons.history_rounded),
              onPressed: _openEventLog,
            ),
            if (_chatController != null)
              IconButton(
                tooltip: 'Chat',
                icon: Badge(
                  isLabelVisible: _chatController!.unreadCount > 0,
                  label: Text('${_chatController!.unreadCount}'),
                  child: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                onPressed: _openChat,
              ),
            IconButton(
              tooltip: 'Pause',
              icon: const Icon(Icons.pause_rounded),
              onPressed: _openPauseMenu,
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isGameOver && !_winDialogShown) {
              _winDialogShown = true;
              unawaited(_handleGameOver());
            }
            final content = SafeArea(
              child: Column(
                children: [
                  if (_connectionState != TransportConnectionState.connected)
                    _buildConnectionBanner(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(child: _buildBoard()),
                                ),
                              ),
                              Expanded(flex: 2, child: _buildSidePanel()),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                                child: Center(child: _buildBoard()),
                              ),
                            ),
                            _buildBottomControls(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
            return Stack(
              children: [
                content,
                ..._floatingEmotes.map(_buildFloatingEmote),
                if (_controller.isGameOver)
                  Positioned.fill(
                    child: ConfettiOverlay(
                      colors: _controller.players.map((p) => p.color).toList(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleGameOver() async {
    final newAchievements = await _recordHistory();
    if (!mounted) return;
    final winner = _controller.winner;
    if (widget.onCampaignResult != null && winner != null) {
      widget.onCampaignResult!(!winner.isBot);
    }
    if (widget.onMatchWinner != null && winner != null) {
      widget.onMatchWinner!(winner);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWinDialog(newAchievements));
  }

  /// Saves the finished match to history and returns any achievements that
  /// just got unlocked by it, so the win dialog can celebrate them.
  Future<List<Achievement>> _recordHistory() async {
    final winner = _controller.winner;
    if (winner == null) return const [];
    final before = Achievement.compute(await StatsService.instance.loadHistory());
    await StatsService.instance.addEntry(
      GameHistoryEntry(
        dateTimeIso: DateTime.now().toIso8601String(),
        mode: widget.mode,
        playerNames: _controller.players.map((p) => p.name).toList(),
        winnerName: winner.name,
        durationSeconds: _stopwatch.elapsed.inSeconds,
        events: List.of(_controller.events),
      ),
    );
    final after = Achievement.compute(await StatsService.instance.loadHistory());
    final wasUnlocked = before.where((a) => a.isUnlocked).map((a) => a.title).toSet();
    return after.where((a) => a.isUnlocked && !wasUnlocked.contains(a.title)).toList();
  }

  void _openChat() {
    final chatController = _chatController;
    if (chatController == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        final screenHeight = MediaQuery.of(context).size.height;
        // Keep the panel height + keyboard within the screen so opening the
        // keyboard to type a message can never push it past the bottom edge.
        final panelHeight = math.min(420.0, (screenHeight - viewInsets) * 0.85);
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: SizedBox(
            height: panelHeight,
            child: ChatPanel(controller: chatController, myName: widget.myName ?? 'Moi'),
          ),
        );
      },
    ).then((_) => setState(() {}));
  }

  void _openPauseMenu() {
    final canRestart = !_controller.isNetworked || _controller.isHost;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Pause', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: const Text('Reprendre'),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
            if (canRestart)
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Recommencer'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _winDialogShown = false);
                  _controller.restart();
                },
              ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Réglages'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SettingsScreen(onThemeChanged: (_) {})),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
              title: const Text('Quitter la partie', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final navigator = Navigator.of(context);
                if (await _confirmLeave()) navigator.pop();
              },
            ),
          ],
          ),
        ),
      ),
    );
  }

  void _openEventLog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: widget.theme.accentDark),
                  const SizedBox(width: 8),
                  Text(
                    'Journal de partie',
                    style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.accentDark),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _controller.events.isEmpty
                  ? const Center(child: Text('Lancez le dé pour commencer !'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _controller.events.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 52),
                      itemBuilder: (context, index) => EventRow(event: _controller.events[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingEmote(_FloatingEmote emote) {
    final dx = ((emote.id * 37) % 100 - 50) / 100; // deterministic scatter, no extra state
    return TweenAnimationBuilder<double>(
      key: ValueKey(emote.id),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Positioned(
          bottom: 140 + t * 220,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: (1 - t).clamp(0, 1),
            child: Transform.translate(
              offset: Offset(dx * 40, 0),
              child: Column(
                children: [
                  Text(emote.emoji, style: const TextStyle(fontSize: 40)),
                  if (emote.from != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        emote.from!,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmoteBar() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _quickEmotes
            .map((e) => GestureDetector(
                  onTap: () => _sendEmote(e),
                  child: Container(
                    width: 38,
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildConnectionBanner() {
    final isReconnecting = _connectionState == TransportConnectionState.reconnecting;
    return Container(
      width: double.infinity,
      color: isReconnecting ? const Color(0xFFFFA000) : const Color(0xFFD32F2F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isReconnecting)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else
            const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isReconnecting
                  ? 'Connexion perdue — reconnexion en cours…'
                  : 'Impossible de se reconnecter. Vérifie la connexion et reviens au menu.',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cells must stay square — sized to fit as much of the available
        // rectangle as possible without stretching.
        var cellSize = constraints.maxWidth.clamp(1, 900.0) / boardCols;
        if (constraints.maxHeight.isFinite) {
          final byHeight = constraints.maxHeight / boardRows;
          if (byHeight < cellSize) cellSize = byHeight;
        }
        final width = cellSize * boardCols;
        final height = cellSize * boardRows;
        return InteractiveViewer(
          maxScale: 2.5,
          minScale: 1,
          boundaryMargin: const EdgeInsets.all(40),
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(color: Colors.black38, blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(width, height),
                      painter: BoardPainter(theme: widget.theme, layout: _controller.layout),
                    ),
                    ..._buildTokens(width, height),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTokens(double boardWidth, double boardHeight) {
    final cellSize = math.min(boardWidth / boardCols, boardHeight / boardRows);
    final playersByCell = <int, List<Player>>{};
    for (final player in _controller.players) {
      if (player.position == 0) continue;
      playersByCell.putIfAbsent(player.position, () => []).add(player);
    }

    final tokens = <Widget>[];
    final tokenRadius = cellSize * 0.32;
    playersByCell.forEach((cell, playersHere) {
      final centre = cellCenter(cell, boardWidth, boardHeight);
      for (var i = 0; i < playersHere.length; i++) {
        final player = playersHere[i];
        final offset = _tokenOffset(i, playersHere.length, cellSize);
        tokens.add(
          AnimatedPositioned(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeInOut,
            left: centre.dx + offset.dx - tokenRadius,
            top: centre.dy + offset.dy - tokenRadius,
            child: PlayerAvatar(player: player, radius: tokenRadius, ringColor: Colors.white),
          ),
        );
      }
    });
    return tokens;
  }

  Offset _tokenOffset(int index, int count, double cellSize) {
    if (count == 1) return Offset.zero;
    final spread = cellSize * 0.3;
    final angle = (2 * math.pi / count) * index;
    return Offset(spread * math.cos(angle), spread * math.sin(angle));
  }

  /// Minimal bottom strip for phone/portrait layouts: just the turn card
  /// (name, avatar and dice) so the board can take up almost the whole
  /// screen, as requested.
  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_controller.turnLimit != null && !_controller.isGameOver)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 15, color: Colors.black45),
                  const SizedBox(width: 4),
                  Text(
                    'Tour ${_controller.roundNumber} / ${_controller.turnLimit}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          _buildTurnCard(),
          if (!_controller.isGameOver && _controller.players.length > 2) ...[
            const SizedBox(height: 6),
            _buildUpNext(),
          ],
          const SizedBox(height: 8),
          _buildPlayersList(),
          if (_controller.isNetworked) ...[
            const SizedBox(height: 6),
            _buildEmoteBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTurnCard(),
          if (!_controller.isGameOver && _controller.players.length > 2) ...[
            const SizedBox(height: 10),
            _buildUpNext(),
          ],
          const SizedBox(height: 16),
          _buildPlayersList(),
        ],
      ),
    );
  }

  Widget _buildUpNext() {
    final players = _controller.players;
    final current = _controller.currentPlayerIndex;
    final upNext = List.generate(
      players.length - 1,
      (i) => players[(current + 1 + i) % players.length],
    );
    return Row(
      children: [
        Text(
          'Ensuite',
          style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
        ),
        const SizedBox(width: 8),
        ...upNext.expand((p) => [
              PlayerAvatar(player: p, radius: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right_rounded, size: 14, color: Colors.black38),
              ),
            ]),
      ]..removeLast(),
    );
  }

  Widget _buildTurnCard() {
    final player = _controller.currentPlayer;
    final canRoll = !_controller.isGameOver && _controller.canLocalPlayerRoll;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [player.color.withValues(alpha: 0.16), player.color.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: player.color, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: _PulsingAvatar(
              key: ValueKey('${player.name}-${_controller.currentPlayerIndex}'),
              player: player,
              pulse: canRoll && !_controller.isGameOver,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _controller.isGameOver
                    ? '${player.name} a gagné !'
                    : canRoll
                        ? 'Au tour de ${player.name}'
                        : player.isBot
                            ? '${player.name} (IA) réfléchit…'
                            : 'En attente de ${player.name}…',
                key: ValueKey('${player.name}-${_controller.isGameOver}-$canRoll'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Opacity(
            opacity: canRoll ? 1 : 0.4,
            // A few extra pixels of invisible hit area around the visible
            // die, plus `opaque` so the gaps between its rounded corners
            // and shadow still count as a tap — a small thumb should never
            // miss it.
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: canRoll ? _controller.rollDice : null,
                child: DiceWidget(
                  value: _controller.diceValue,
                  color: player.color,
                  isRolling: _controller.isRolling,
                  skin: _diceSkin,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _controller.players.map((player) {
        final isActive = player == _controller.currentPlayer && !_controller.isGameOver;
        return Chip(
          avatar: PlayerAvatar(player: player, radius: 14),
          label: Text('${player.name} · Score : ${player.position}'),
          backgroundColor: isActive ? player.color.withValues(alpha: 0.2) : null,
          shape: isActive
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: player.color, width: 1.5),
                )
              : null,
        );
      }).toList(),
    );
  }

  void _shareResult(Player winner) {
    final others = _controller.players.where((p) => p != winner).map((p) => p.name).join(', ');
    unawaited(SharePlus.instance.share(ShareParams(
      text: '${winner.name} vient de remporter Serpents & Échelles Party '
          'face à $others ! Le défi le plus drôle de tous les temps !',
    )));
  }

  void _showWinDialog(List<Achievement> newAchievements) {
    final winner = _controller.winner;
    if (winner == null) return;
    final isCampaignDefeat = widget.onCampaignResult != null && winner.isBot;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCampaignDefeat ? Icons.hourglass_bottom_rounded : Icons.emoji_events_rounded,
              color: isCampaignDefeat ? Colors.redAccent : winner.color,
            ),
            const SizedBox(width: 8),
            Text(isCampaignDefeat ? 'Défaite' : 'Victoire !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCampaignDefeat && _controller.isDefeat
                  ? 'Temps écoulé ! ${winner.name} l\'emporte par défaut.'
                  : '${winner.name} a remporté le défi !',
            ),
            if (newAchievements.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Nouveau succès débloqué !', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...newAchievements.map(
                (a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(a.icon, color: const Color(0xFFFB8C00), size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a.title)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: widget.onMatchWinner != null
            ? [
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Continuer le tournoi'),
                ),
              ]
            : [
                TextButton.icon(
                  onPressed: () => _shareResult(winner),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Partager'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
                if (!_controller.isNetworked || _controller.isHost)
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() => _winDialogShown = false);
                      _controller.restart();
                    },
                    child: const Text('Rejouer'),
                  ),
              ],
      ),
    );
  }
}

class _PulsingAvatar extends StatefulWidget {
  const _PulsingAvatar({super.key, required this.player, required this.pulse});

  final Player player;
  final bool pulse;

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final ringScale = widget.pulse ? 1.0 + _controller.value * 0.25 : 1.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.pulse)
              Transform.scale(
                scale: ringScale,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.player.color.withValues(alpha: 1 - _controller.value),
                      width: 2,
                    ),
                  ),
                ),
              ),
            child!,
          ],
        );
      },
      child: PlayerAvatar(player: widget.player, radius: 19),
    );
  }
}

