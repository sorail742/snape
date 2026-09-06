import 'dart:async';

import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../models/board_theme.dart';
import '../models/game_mode.dart';
import '../models/player.dart';
import '../services/daily_challenge_service.dart';
import '../services/settings_service.dart';
import 'bluetooth_lobby_screen.dart';
import 'online_lobby_screen.dart';
import 'onboarding_screen.dart';
import 'game_screen.dart';
import 'setup_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeModeScreen extends StatefulWidget {
  const HomeModeScreen({super.key});

  @override
  State<HomeModeScreen> createState() => _HomeModeScreenState();
}

class _HomeModeScreenState extends State<HomeModeScreen> with SingleTickerProviderStateMixin {
  BoardTheme _theme = BoardTheme.classic;
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  /// Builds a fade + gentle upward slide for the given slot in the
  /// staggered entrance sequence, so the logo, title and mode cards cascade
  /// in one after another on startup instead of popping in all at once.
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
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 24),
          child: child,
        ),
      ),
      child: child,
    );
  }

  Map<String, dynamic>? _dailyResult;
  int _dailyStreak = 0;

  @override
  void initState() {
    super.initState();
    SettingsService.instance.loadDefaultThemeId().then((id) {
      if (mounted) setState(() => _theme = BoardTheme.byId(id));
    });
    _loadDailyResult();
  }

  Future<void> _loadDailyResult() async {
    final result = await DailyChallengeService.instance.loadTodayResult();
    final streak = await DailyChallengeService.instance.loadStreak();
    if (mounted) {
      setState(() {
        _dailyResult = result;
        _dailyStreak = streak;
      });
    }
  }

  void _playDailyChallenge() {
    final human = Player(name: 'Toi', color: const Color(0xFF1E88E5), avatarEmoji: '🙂');
    final bot = Player(name: 'IA', color: const Color(0xFFE53935), avatarEmoji: '🤖', isBot: true);
    final stopwatch = Stopwatch()..start();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          controller: GameController(
            players: [human, bot],
            layout: DailyChallengeService.instance.todayLayout,
          ),
          theme: _theme,
          mode: GameModeKind.local,
          titleOverride: 'Défi du jour',
          onCampaignResult: (humanWon) {
            unawaited(DailyChallengeService.instance
                .saveTodayResult(won: humanWon, durationSeconds: stopwatch.elapsed.inSeconds)
                .then((_) => _loadDailyResult()));
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded),
                    tooltip: 'Comment jouer',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(isReplay: true),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    tooltip: 'Réglages',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          onThemeChanged: (t) => setState(() => _theme = t),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 44, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _staggered(
                        0,
                        7,
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: _theme.accent.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(_theme.icon, size: 40, color: _theme.accentDark),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _staggered(
                        1,
                        7,
                        Text(
                          'Serpents & Échelles Party',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: _theme.accentDark,
                              ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _staggered(
                        2,
                        7,
                        const Text(
                          'Le défi le plus drôle de tous les temps !',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _staggered(
                        3,
                        7,
                        _ModeCard(
                          icon: Icons.home_rounded,
                          label: 'Jouer en local',
                          subtitle: 'À plusieurs sur le même appareil',
                          accent: const Color(0xFFE65100),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SetupScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _staggered(
                        4,
                        7,
                        _ModeCard(
                          icon: Icons.bluetooth_rounded,
                          label: 'Bluetooth à proximité',
                          subtitle: 'Entre amis, sans connexion internet',
                          accent: const Color(0xFF1565C0),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BluetoothLobbyScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _staggered(
                        5,
                        7,
                        _ModeCard(
                          icon: Icons.public_rounded,
                          label: 'En ligne',
                          subtitle: 'Partout dans le monde, avec un code',
                          accent: const Color(0xFF2E7D32),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const OnlineLobbyScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _staggered(
                        6,
                        7,
                        _ModeCard(
                          icon: Icons.today_rounded,
                          label: 'Défi du jour',
                          subtitle: _dailyResult == null
                              ? 'Un nouveau plateau chaque jour, le même pour tout le monde'
                              : (_dailyResult!['won'] as bool? ?? false)
                                  ? 'Relevé aujourd\'hui en ${_dailyResult!['durationSeconds']}s — rejoue pour améliorer ton temps'
                                  : 'Pas encore réussi aujourd\'hui — retente ta chance !',
                          accent: const Color(0xFF6A1B9A),
                          onTap: _playDailyChallenge,
                          trailingBadge: _dailyStreak > 1
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🔥', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$_dailyStreak',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE65100),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StatsScreen()),
                        ),
                        icon: const Icon(Icons.bar_chart_rounded),
                        label: const Text('Statistiques'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single, restrained row style used everywhere the home screen needs to
/// list several actions: white card, one accent colour confined to the icon
/// badge, dark text — instead of a different bold gradient per row.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.trailingBadge,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  /// An optional small badge shown before the chevron (e.g. a streak flame).
  final Widget? trailingBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECECEC)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 24, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF212121),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF757575), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null) ...[trailingBadge!, const SizedBox(width: 6)],
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
            ],
          ),
        ),
      ),
    );
  }
}
