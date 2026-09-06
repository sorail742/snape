import 'dart:async';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../models/board_layout.dart';
import '../models/board_theme.dart';
import '../models/game_mode.dart';
import '../models/player.dart';
import '../services/custom_board_service.dart';
import '../services/settings_service.dart';
import '../services/stats_service.dart';
import '../widgets/player_avatar.dart';
import 'board_editor_screen.dart';
import 'campaign_screen.dart';
import 'game_screen.dart';
import 'tournament_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const _availableColors = <Color>[
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
  ];

  int _playerCount = 2;
  BoardTheme _theme = BoardTheme.classic;
  BoardLayout _boardLayout = BoardLayout.classic;
  String _boardLayoutLabel = 'Classique';
  List<CustomBoard> _customBoards = [];
  late final List<TextEditingController> _controllers = List.generate(
    4,
    (i) => TextEditingController(text: 'Joueur ${i + 1}'),
  );
  late final List<String> _avatars =
      List.generate(4, (i) => playerAvatarEmojis[i % playerAvatarEmojis.length]);
  final List<String?> _avatarImagePaths = List.generate(4, (_) => null);
  final List<bool> _isBot = List.generate(4, (_) => false);
  List<Map<String, dynamic>> _savedProfiles = [];

  @override
  void initState() {
    super.initState();
    SettingsService.instance.loadDefaultThemeId().then((id) {
      if (mounted) setState(() => _theme = BoardTheme.byId(id));
    });
    SettingsService.instance.loadProfiles().then((profiles) {
      if (mounted) setState(() => _savedProfiles = profiles);
    });
    _reloadCustomBoards();
    SettingsService.instance.loadLastPlayers().then((saved) {
      if (!mounted || saved.isEmpty) return;
      setState(() {
        _playerCount = saved.length.clamp(2, 4);
        for (var i = 0; i < saved.length && i < 4; i++) {
          final p = saved[i];
          _controllers[i].text = p['name'] as String? ?? 'Joueur ${i + 1}';
          _avatars[i] = p['avatar'] as String? ?? _avatars[i];
          _avatarImagePaths[i] = p['imagePath'] as String?;
          _isBot[i] = p['isBot'] as bool? ?? false;
        }
      });
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _reloadCustomBoards() async {
    final boards = await CustomBoardService.instance.loadAll();
    if (!mounted) return;
    setState(() {
      _customBoards = boards;
      // If the previously chosen custom board was deleted/renamed while the
      // editor was open, fall back to the classic board rather than keep
      // pointing at a layout that's no longer listed.
      if (_boardLayoutLabel != 'Classique' && boards.every((b) => b.name != _boardLayoutLabel)) {
        _boardLayout = BoardLayout.classic;
        _boardLayoutLabel = 'Classique';
      }
    });
  }

  Future<void> _openBoardEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BoardEditorListScreen()),
    );
    await _reloadCustomBoards();
  }

  Player _previewPlayer(int index) => Player(
        name: _controllers[index].text,
        color: _availableColors[index],
        avatarEmoji: _avatars[index],
        avatarImagePath: _avatarImagePaths[index],
        isBot: _isBot[index],
      );

  Future<void> _pickAvatar(int index) async {
    final selected = await showModalBottomSheet<Object>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_savedProfiles.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Profils enregistrés', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _savedProfiles.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final p = _savedProfiles[i];
                    final imagePath = p['imagePath'] as String?;
                    return GestureDetector(
                      onTap: () => Navigator.of(context).pop(p),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(p['color'] as int? ?? Colors.grey.toARGB32()),
                            backgroundImage: imagePath != null ? FileImage(File(imagePath)) : null,
                            child: imagePath == null
                                ? Text(p['avatar'] as String? ?? '🙂', style: const TextStyle(fontSize: 20))
                                : null,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            child: Text(
                              p['name'] as String? ?? '',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 20),
            ],
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choisir une photo'),
              onTap: () => Navigator.of(context).pop('__photo__'),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
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
          ],
        ),
      ),
    );
    if (selected is Map) {
      final profile = Map<String, dynamic>.from(selected);
      setState(() {
        _controllers[index].text = profile['name'] as String? ?? _controllers[index].text;
        _avatars[index] = profile['avatar'] as String? ?? _avatars[index];
        _avatarImagePaths[index] = profile['imagePath'] as String?;
      });
    } else if (selected == '__photo__') {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512);
      if (picked != null) {
        setState(() => _avatarImagePaths[index] = picked.path);
      }
    } else if (selected is String) {
      setState(() {
        _avatars[index] = selected;
        _avatarImagePaths[index] = null;
      });
    }
  }

  /// The AI gets a bit sharper if the human has been winning a lot lately,
  /// and stays fair (no handicap) if they've been struggling or there isn't
  /// enough recent history yet to tell.
  Future<double> _computeAdaptiveHandicap(String humanName) async {
    final history = await StatsService.instance.loadHistory();
    final recent = history.take(10).toList();
    if (recent.length < 3) return 0.0;
    final wins = recent.where((e) => e.winnerName == humanName).length;
    final winRate = wins / recent.length;
    if (winRate > 0.7) return 0.4;
    if (winRate > 0.55) return 0.25;
    if (winRate < 0.3) return 0.0;
    return 0.1;
  }

  Future<void> _startGame() async {
    final players = List.generate(_playerCount, (i) {
      final name = _controllers[i].text.trim();
      return Player(
        name: name.isEmpty ? 'Joueur ${i + 1}' : name,
        color: _availableColors[i],
        avatarEmoji: _avatars[i],
        avatarImagePath: _avatarImagePaths[i],
        isBot: _isBot[i],
      );
    });

    unawaited(SettingsService.instance.saveLastPlayers(
      players
          .map((p) => {
                'name': p.name,
                'avatar': p.avatarEmoji,
                'imagePath': p.avatarImagePath,
                'isBot': p.isBot,
              })
          .toList(),
    ));

    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      if (p.isBot) continue;
      unawaited(SettingsService.instance.upsertProfile({
        'name': p.name,
        'avatar': p.avatarEmoji,
        'imagePath': p.avatarImagePath,
        'color': _availableColors[i].toARGB32(),
      }));
    }

    var aiHandicap = 0.0;
    final hasBot = players.any((p) => p.isBot);
    final firstHuman = players.firstWhere((p) => !p.isBot, orElse: () => players.first);
    if (hasBot) {
      aiHandicap = await _computeAdaptiveHandicap(firstHuman.name);
    }
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          controller: GameController(players: players, layout: _boardLayout, aiHandicap: aiHandicap),
          theme: _theme,
          mode: GameModeKind.local,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partie locale'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CampaignScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFECECEC)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0277BD).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.workspace_premium_rounded,
                                  color: Color(0xFF0277BD), size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mode Campagne',
                                    style: TextStyle(
                                      color: Color(0xFF212121),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Enchaîne les étapes contre l\'IA jusqu\'à la Grande Coupe',
                                    style: TextStyle(color: Color(0xFF757575), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TournamentScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFECECEC)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFE53935), size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mode Tournoi',
                                    style: TextStyle(
                                      color: Color(0xFF212121),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '4 ou 8 joueurs, élimination directe, un seul champion',
                                    style: TextStyle(color: Color(0xFF757575), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.people_alt_rounded, color: Color(0xFFFB8C00)),
                          const SizedBox(width: 10),
                          const Text('Nombre de joueurs', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          DropdownButton<int>(
                            value: _playerCount,
                            underline: const SizedBox(),
                            items: const [2, 3, 4]
                                .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _playerCount = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.smart_toy_outlined, size: 16, color: Colors.black45),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Personne d\'autre ? Active l\'IA sur un ou plusieurs joueurs.',
                            style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < _playerCount; i++)
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: _availableColors[i].withValues(alpha: 0.4)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _pickAvatar(i),
                              child: Stack(
                                children: [
                                  PlayerAvatar(player: _previewPlayer(i), radius: 24),
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit_rounded, size: 12, color: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _controllers[i],
                                enabled: !_isBot[i],
                                decoration: InputDecoration(
                                  labelText: 'Joueur ${i + 1}',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: _isBot[i] ? 'Contrôlé par l\'IA' : 'Joueur humain',
                              icon: Icon(
                                Icons.smart_toy_rounded,
                                color: _isBot[i] ? const Color(0xFF1E88E5) : Colors.black26,
                              ),
                              onPressed: () => setState(() => _isBot[i] = !_isBot[i]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Thème du plateau', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: BoardTheme.all.map((theme) {
                      final selected = theme.id == _theme.id;
                      return ChoiceChip(
                        avatar: Icon(theme.icon, size: 18),
                        label: Text(theme.label),
                        selected: selected,
                        selectedColor: theme.accent.withValues(alpha: 0.25),
                        onSelected: (_) => setState(() => _theme = theme),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Plateau', style: Theme.of(context).textTheme.bodyMedium),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _openBoardEditor,
                        icon: const Icon(Icons.edit_road_rounded, size: 18),
                        label: const Text('Mes plateaux'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Classique'),
                        selected: _boardLayoutLabel == 'Classique',
                        onSelected: (_) => setState(() {
                          _boardLayout = BoardLayout.classic;
                          _boardLayoutLabel = 'Classique';
                        }),
                      ),
                      ..._customBoards.map(
                        (b) => ChoiceChip(
                          label: Text(b.name),
                          selected: _boardLayoutLabel == b.name,
                          onSelected: (_) => setState(() {
                            _boardLayout = b.layout;
                            _boardLayoutLabel = b.name;
                          }),
                        ),
                      ),
                    ],
                  ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Fixed at the bottom instead of the end of the scrolling list,
            // so it's never lost off-screen while configuring players/theme.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _startGame,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Commencer la partie', style: TextStyle(fontSize: 16)),
                      ),
                    ),
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
