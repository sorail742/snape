import 'dart:async';

import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../models/board_theme.dart';
import '../models/game_mode.dart';
import '../models/player.dart';
import '../models/stage.dart';
import '../services/campaign_service.dart';
import '../services/settings_service.dart';
import 'game_screen.dart';

/// Solo campaign: 4 worlds of 30 numbered levels each (120 total). Every
/// level within a world shares that world's board, but the turn limit
/// tightens and the AI gets a little sharper level by level, so beating a
/// whole world is a real climb — and each world's cup is more prestigious
/// than the last.
class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController(text: 'Toi');
  int _unlockedLevel = 1;
  BoardTheme _theme = BoardTheme.classic;
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  /// Same cascade-reveal used on the home screen, applied per world card so
  /// the campaign feels as premium as the rest of the app.
  Widget _staggered(int index, int count, Widget child) {
    final start = index / (count + 1);
    final end = (index + 2) / (count + 1);
    final curved = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start.clamp(0, 1), end.clamp(0, 1), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) => Opacity(
        opacity: curved.value,
        child: Transform.translate(offset: Offset(0, (1 - curved.value) * 20), child: child),
      ),
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    CampaignService.instance.loadUnlockedLevel().then((level) {
      if (mounted) setState(() => _unlockedLevel = level);
    });
    SettingsService.instance.loadDefaultThemeId().then((id) {
      if (mounted) setState(() => _theme = BoardTheme.byId(id));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _entrance.dispose();
    super.dispose();
  }

  String get _myName => _nameController.text.trim().isEmpty ? 'Toi' : _nameController.text.trim();

  Future<void> _unlockNext(int globalIndex) async {
    await CampaignService.instance.unlockLevel(globalIndex);
    final level = await CampaignService.instance.loadUnlockedLevel();
    if (mounted) setState(() => _unlockedLevel = level);
  }

  void _playLevel(SubStage level) {
    final human = Player(name: _myName, color: const Color(0xFF1E88E5), avatarEmoji: '🙂');
    final bot = Player(name: 'IA', color: const Color(0xFFE53935), avatarEmoji: '🤖', isBot: true);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          controller: GameController(
            players: [human, bot],
            layout: level.stage.layout,
            turnLimit: level.turnLimit,
            aiHandicap: level.aiHandicap,
          ),
          theme: _theme,
          mode: GameModeKind.local,
          titleOverride: level.name,
          onCampaignResult: (humanWon) {
            if (!humanWon) return;
            unawaited(_unlockNext(level.globalIndex + 1));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campagne'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ton nom',
                    prefixIcon: Icon(Icons.person_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Niveau ${_unlockedLevel.clamp(1, subLevelsPerStage * Stage.all.length)} / '
                  '${subLevelsPerStage * Stage.all.length} débloqué',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text(
                  '30 niveaux par monde : bats l\'IA pour débloquer le suivant. Le plateau se '
                  'corse à chaque monde, et à l\'intérieur d\'un monde les tours se resserrent et '
                  'l\'IA joue de plus en plus serré à mesure que tu avances.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < Stage.all.length; i++)
                  _staggered(i, Stage.all.length, _buildWorldSection(Stage.all[i])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorldSection(Stage stage) {
    final levels = SubStage.all.where((l) => l.stage.index == stage.index).toList();
    final worldCleared = levels.every((l) => l.globalIndex < _unlockedLevel);
    final worldStarted = levels.first.globalIndex <= _unlockedLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: worldStarted ? stage.cupColor : const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    worldStarted ? stage.cupColor.withValues(alpha: 0.12) : const Color(0xFFF0F0F0),
                child: Icon(
                  worldCleared
                      ? Icons.workspace_premium_rounded
                      : (worldStarted ? stage.cupIcon : Icons.lock_rounded),
                  color: worldStarted ? stage.cupColor : Colors.black38,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stage.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: worldStarted ? Colors.black87 : Colors.black38,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: levels.map((level) {
              final isUnlocked = level.globalIndex <= _unlockedLevel;
              final isCleared = level.globalIndex < _unlockedLevel;
              return GestureDetector(
                onTap: isUnlocked ? () => _playLevel(level) : null,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCleared
                        ? stage.cupColor
                        : (isUnlocked ? stage.cupColor.withValues(alpha: 0.18) : const Color(0xFFF0F0F0)),
                    border: Border.all(
                      color: isUnlocked ? stage.cupColor : const Color(0xFFE0E0E0),
                      width: isUnlocked && !isCleared ? 2 : 1,
                    ),
                  ),
                  child: isCleared
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : isUnlocked
                          ? Text(
                              '${level.levelInStage}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: stage.cupColor),
                            )
                          : const Icon(Icons.lock_rounded, size: 14, color: Colors.black26),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
