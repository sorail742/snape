import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_event.dart';
import '../models/game_history_entry.dart';
import '../widgets/event_row.dart';

/// Replays a finished match's activity log turn by turn — the events were
/// recorded chronologically-reversed (newest first) during play, so this
/// screen reverses them back and reveals them one at a time on tap "Lecture".
class ReplayScreen extends StatefulWidget {
  const ReplayScreen({super.key, required this.entry});
  final GameHistoryEntry entry;

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  late final List<GameEvent> _chronological = widget.entry.events.reversed.toList();
  int _shown = 0;
  Timer? _timer;
  bool _playing = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    if (_shown >= _chronological.length) {
      setState(() => _shown = 0);
    }
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (_shown >= _chronological.length) {
        timer.cancel();
        setState(() => _playing = false);
        return;
      }
      setState(() => _shown++);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Scaffold(
      appBar: AppBar(title: const Text('Replay de la partie')),
      body: entry.events.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Cette partie a été jouée avant l\'ajout du replay — aucun journal enregistré.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.playerNames.join(' vs '),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.winnerName} a gagné · ${entry.durationSeconds}s',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _shown,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 52),
                    itemBuilder: (context, index) => EventRow(event: _chronological[index]),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _chronological.isEmpty ? 0 : _shown / _chronological.length,
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _playing ? _pause : _play,
                        icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        label: Text(_playing ? 'Pause' : (_shown == 0 ? 'Lecture' : 'Reprendre')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
