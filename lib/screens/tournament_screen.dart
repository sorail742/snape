import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../models/board_theme.dart';
import '../models/game_mode.dart';
import '../models/player.dart';
import 'game_screen.dart';

/// A local single-elimination bracket: 4 or 8 players on the same phone,
/// paired up at random, winners advancing round by round until one
/// champion remains.
class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  static const _availableColors = <Color>[
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
    Color(0xFF8E24AA),
    Color(0xFFFB8C00),
    Color(0xFF00897B),
    Color(0xFF6D4C41),
  ];

  int _participantCount = 4;
  late List<TextEditingController> _controllers =
      List.generate(_participantCount, (i) => TextEditingController(text: 'Joueur ${i + 1}'));
  final BoardTheme _theme = BoardTheme.classic;

  // Bracket state — null while still in the setup phase.
  List<Player>? _roundPlayers;
  final List<Player> _winnersThisRound = [];
  int _matchIndexInRound = 0;
  int _roundNumber = 1;
  Player? _champion;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _setParticipantCount(int count) {
    setState(() {
      _participantCount = count;
      final old = _controllers;
      _controllers = List.generate(
        count,
        (i) => i < old.length ? old[i] : TextEditingController(text: 'Joueur ${i + 1}'),
      );
      for (var i = count; i < old.length; i++) {
        old[i].dispose();
      }
    });
  }

  void _startTournament() {
    final players = List.generate(_participantCount, (i) {
      final name = _controllers[i].text.trim();
      return Player(
        name: name.isEmpty ? 'Joueur ${i + 1}' : name,
        color: _availableColors[i % _availableColors.length],
        avatarEmoji: playerAvatarEmojis[i % playerAvatarEmojis.length],
      );
    })
      ..shuffle();
    setState(() {
      _roundPlayers = players;
      _winnersThisRound.clear();
      _matchIndexInRound = 0;
      _roundNumber = 1;
      _champion = null;
    });
  }

  void _playNextMatch() {
    final round = _roundPlayers!;
    final a = round[_matchIndexInRound * 2];
    final b = round[_matchIndexInRound * 2 + 1];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          controller: GameController(players: [a, b]),
          theme: _theme,
          mode: GameModeKind.local,
          titleOverride: 'Tournoi · Tour $_roundNumber',
          onMatchWinner: (winner) {
            setState(() {
              _winnersThisRound.add(winner);
              _matchIndexInRound++;
              if (_matchIndexInRound * 2 >= round.length) {
                if (_winnersThisRound.length == 1) {
                  _champion = _winnersThisRound.first;
                } else {
                  _roundPlayers = List.of(_winnersThisRound);
                  _winnersThisRound.clear();
                  _matchIndexInRound = 0;
                  _roundNumber++;
                }
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tournoi')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _roundPlayers == null ? _buildSetup() : _buildBracket(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetup() {
    return ListView(
      children: [
        const Text(
          'Choisis le nombre de participants : ils s\'affrontent en 1 contre 1, tirés au sort, '
          'jusqu\'au grand champion.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 4, label: Text('4 joueurs')),
            ButtonSegment(value: 8, label: Text('8 joueurs')),
          ],
          selected: {_participantCount},
          onSelectionChanged: (s) => _setParticipantCount(s.first),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < _participantCount; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _controllers[i],
              decoration: InputDecoration(
                labelText: 'Joueur ${i + 1}',
                prefixIcon: Text(
                  playerAvatarEmojis[i % playerAvatarEmojis.length],
                  style: const TextStyle(fontSize: 18),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _startTournament,
          icon: const Icon(Icons.emoji_events_rounded),
          label: const Text('Lancer le tournoi'),
        ),
      ],
    );
  }

  Widget _buildBracket() {
    if (_champion != null) {
      final champion = _champion!;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, color: champion.color, size: 72),
            const SizedBox(height: 16),
            Text(
              '${champion.name} remporte le tournoi !',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => setState(() => _roundPlayers = null),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Nouveau tournoi'),
            ),
          ],
        ),
      );
    }

    final round = _roundPlayers!;
    return ListView(
      children: [
        Text('Tour $_roundNumber', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (var i = 0; i * 2 < round.length; i++)
          _MatchTile(
            playerA: round[i * 2],
            playerB: round[i * 2 + 1],
            winner: i < _winnersThisRound.length ? _winnersThisRound[i] : null,
            isNext: i == _matchIndexInRound,
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _playNextMatch,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
            'Jouer : ${round[_matchIndexInRound * 2].name} vs ${round[_matchIndexInRound * 2 + 1].name}',
          ),
        ),
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.playerA,
    required this.playerB,
    required this.winner,
    required this.isNext,
  });

  final Player playerA;
  final Player playerB;
  final Player? winner;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNext ? const BorderSide(color: Color(0xFFFB8C00), width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(playerA.name, style: _nameStyle(playerA))),
            const Text('vs', style: TextStyle(color: Colors.black38)),
            Expanded(
              child: Text(playerB.name, textAlign: TextAlign.right, style: _nameStyle(playerB)),
            ),
            const SizedBox(width: 10),
            if (winner != null)
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18)
            else if (isNext)
              const Icon(Icons.play_circle_outline_rounded, color: Color(0xFFFB8C00), size: 18),
          ],
        ),
      ),
    );
  }

  TextStyle _nameStyle(Player p) => TextStyle(
        fontWeight: winner == p ? FontWeight.bold : FontWeight.normal,
        color: winner == null ? Colors.black87 : (winner == p ? Colors.black87 : Colors.black38),
      );
}
