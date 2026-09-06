import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../models/game_history_entry.dart';
import '../services/stats_service.dart';
import 'replay_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} jours';
  return 'il y a ${(diff.inDays / 7).floor()} sem.';
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<List<GameHistoryEntry>> _future = StatsService.instance.loadHistory();

  Future<void> _clear() async {
    await StatsService.instance.clearHistory();
    setState(() => _future = StatsService.instance.loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            tooltip: 'Effacer l\'historique',
            icon: const Icon(Icons.delete_outline),
            onPressed: _clear,
          ),
        ],
      ),
      body: FutureBuilder<List<GameHistoryEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!;
          final achievements = Achievement.compute(entries);
          if (entries.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Aucune partie enregistrée pour le moment.'),
                  ),
                ),
                Text('Succès', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _AchievementGrid(achievements: achievements),
              ],
            );
          }

          final winCounts = <String, int>{};
          final playedCounts = <String, int>{};
          for (final e in entries) {
            winCounts[e.winnerName] = (winCounts[e.winnerName] ?? 0) + 1;
            for (final name in e.playerNames) {
              playedCounts[name] = (playedCounts[name] ?? 0) + 1;
            }
          }
          final ranking = playedCounts.keys.toList()
            ..sort((a, b) => (winCounts[b] ?? 0).compareTo(winCounts[a] ?? 0));
          const medalColors = [Color(0xFFFFD54F), Color(0xFFB0BEC5), Color(0xFFBF8A5A)];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Succès', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _AchievementGrid(achievements: achievements),
              const Divider(height: 32),
              Text('Classement', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...ranking.asMap().entries.map((entry) {
                final rank = entry.key;
                final name = entry.value;
                final wins = winCounts[name] ?? 0;
                final played = playedCounts[name] ?? 0;
                final winRate = played == 0 ? 0 : (wins / played * 100).round();
                final isPodium = rank < 3;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFECECEC)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPodium
                          ? medalColors[rank]
                          : const Color(0xFFF0F0F0),
                      child: isPodium
                          ? const Icon(Icons.emoji_events_rounded, color: Colors.white)
                          : Text('${rank + 1}', style: const TextStyle(color: Colors.black54)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$played partie${played > 1 ? 's' : ''} · $winRate% de victoires'),
                    trailing: Text(
                      '$wins',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
              }),
              const Divider(height: 32),
              Text('Historique des parties', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...entries.map((e) {
                final date = DateTime.tryParse(e.dateTimeIso);
                final dateLabel = date == null ? '' : _relativeTime(date);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFECECEC)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFB8C00)),
                    title: Text('${e.winnerName} a gagné (${e.mode.label})'),
                    subtitle: Text(
                      '${e.playerNames.join(', ')}\n$dateLabel · ${e.durationSeconds}s',
                    ),
                    isThreeLine: true,
                    trailing: e.events.isEmpty ? null : const Icon(Icons.chevron_right_rounded),
                    onTap: e.events.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ReplayScreen(entry: e)),
                            ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  const _AchievementGrid({required this.achievements});
  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: achievements.map((a) {
        // Keying on the unlocked flag means the badge only remounts (and
        // pops) the moment it flips from locked to unlocked — rebuilds
        // afterward reuse the same key and never re-animate.
        return TweenAnimationBuilder<double>(
          key: ValueKey('${a.title}_${a.isUnlocked}'),
          tween: Tween(begin: a.isUnlocked ? 0.6 : 1.0, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
          width: 104,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: a.isUnlocked ? const Color(0xFFFFF3E0) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: a.isUnlocked ? const Color(0xFFFB8C00) : const Color(0xFFE0E0E0),
            ),
          ),
          child: Column(
            children: [
              Icon(
                a.icon,
                size: 28,
                color: a.isUnlocked ? const Color(0xFFFB8C00) : Colors.black26,
              ),
              const SizedBox(height: 6),
              Text(
                a.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: a.isUnlocked ? Colors.black87 : Colors.black38,
                  fontWeight: a.isUnlocked ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          ),
        );
      }).toList(),
    );
  }
}
