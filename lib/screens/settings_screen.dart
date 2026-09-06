import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../main.dart';
import '../models/board_theme.dart';
import '../services/haptics_service.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../widgets/dice_widget.dart';
import 'onboarding_screen.dart';
import 'stats_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onThemeChanged});

  /// Called when the user picks a new default theme, so the caller (home
  /// screen) can refresh immediately without waiting for a rebuild.
  final ValueChanged<BoardTheme> onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  double _volume = 1.0;
  HapticIntensity _hapticIntensity = HapticIntensity.full;
  String _themeId = 'classic';
  bool _materialYou = false;
  bool _shakeToRoll = true;
  DiceSkin _diceSkin = DiceSkin.classic;
  double _textScale = 1.0;
  bool _loaded = false;
  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sound = await SettingsService.instance.loadSoundEnabled();
    final volume = await SettingsService.instance.loadVolume();
    final hapticIntensity = await SettingsService.instance.loadHapticIntensity();
    final themeId = await SettingsService.instance.loadDefaultThemeId();
    final materialYou = await SettingsService.instance.loadMaterialYouEnabled();
    final shakeToRoll = await SettingsService.instance.loadShakeToRollEnabled();
    final diceSkin = await SettingsService.instance.loadDiceSkin();
    final scale = await SettingsService.instance.loadTextScale();
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _soundEnabled = sound;
      _volume = volume;
      _hapticIntensity = HapticIntensity.values[hapticIntensity];
      _themeId = themeId;
      _materialYou = materialYou;
      _shakeToRoll = shakeToRoll;
      _diceSkin = DiceSkin.values[diceSkin];
      _textScale = scale;
      _versionLabel = 'Version ${info.version} (build ${info.buildNumber})';
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  secondary: Icon(_soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded),
                  title: const Text('Sons'),
                  subtitle: const Text('Dé, échelles, serpents, victoire'),
                  value: _soundEnabled,
                  onChanged: (value) async {
                    setState(() => _soundEnabled = value);
                    SoundService.instance.enabled = value;
                    await SettingsService.instance.setSoundEnabled(value);
                  },
                ),
                if (_soundEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.volume_down_rounded, size: 20, color: Colors.black45),
                        Expanded(
                          child: Slider(
                            value: _volume,
                            onChanged: (value) => setState(() => _volume = value),
                            onChangeEnd: (value) async {
                              SoundService.instance.volume = value;
                              await SettingsService.instance.setVolume(value);
                            },
                          ),
                        ),
                        const Icon(Icons.volume_up_rounded, size: 20, color: Colors.black45),
                      ],
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.vibration_rounded),
                  title: const Text('Vibrations'),
                  subtitle: const Text('Intensité du retour haptique pendant la partie'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<HapticIntensity>(
                    segments: const [
                      ButtonSegment(value: HapticIntensity.off, label: Text('Désactivé')),
                      ButtonSegment(value: HapticIntensity.light, label: Text('Léger')),
                      ButtonSegment(value: HapticIntensity.full, label: Text('Fort')),
                    ],
                    selected: {_hapticIntensity},
                    onSelectionChanged: (selection) async {
                      final value = selection.first;
                      setState(() => _hapticIntensity = value);
                      HapticsService.instance.intensity = value;
                      await SettingsService.instance.setHapticIntensity(value.index);
                    },
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration),
                  title: const Text('Secouer pour lancer le dé'),
                  subtitle: const Text('Secoue le téléphone au lieu d\'appuyer sur le dé'),
                  value: _shakeToRoll,
                  onChanged: (value) async {
                    setState(() => _shakeToRoll = value);
                    await SettingsService.instance.setShakeToRollEnabled(value);
                  },
                ),
                const Divider(height: 32),
                SwitchListTile(
                  secondary: const Icon(Icons.palette_rounded),
                  title: const Text('Couleurs dynamiques (Material You)'),
                  subtitle: const Text('Adopte les couleurs de fond d\'écran de ton téléphone (Android 12+)'),
                  value: _materialYou,
                  onChanged: (value) async {
                    setState(() => _materialYou = value);
                    materialYouEnabled.value = value;
                    await SettingsService.instance.setMaterialYouEnabled(value);
                  },
                ),
                const Divider(height: 32),
                Text('Style du dé', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    (DiceSkin.classic, 'Classique'),
                    (DiceSkin.digits, 'Chiffres'),
                    (DiceSkin.neon, 'Néon'),
                    (DiceSkin.wood, 'Bois'),
                  ].map((entry) {
                    final (skin, label) = entry;
                    return ChoiceChip(
                      label: Text(label),
                      selected: skin == _diceSkin,
                      onSelected: (_) async {
                        setState(() => _diceSkin = skin);
                        await SettingsService.instance.setDiceSkin(skin.index);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Taille du texte', style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    const Text('A', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Slider(
                        value: _textScale,
                        min: 0.85,
                        max: 1.3,
                        divisions: 9,
                        label: '${(_textScale * 100).round()}%',
                        onChanged: (value) => setState(() => _textScale = value),
                        onChangeEnd: (value) async {
                          textScale.value = value;
                          await SettingsService.instance.setTextScale(value);
                        },
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 24)),
                  ],
                ),
                const Divider(height: 32),
                Text('Thème par défaut', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: _themeId,
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() => _themeId = value);
                    await SettingsService.instance.setDefaultThemeId(value);
                    widget.onThemeChanged(BoardTheme.byId(value));
                  },
                  child: Column(
                    children: BoardTheme.all
                        .map(
                          (t) => RadioListTile<String>(
                            value: t.id,
                            secondary: Icon(t.icon, color: t.accent),
                            title: Text(t.label),
                            activeColor: t.accent,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('Comment jouer'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen(isReplay: true)),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart_rounded),
                  title: const Text('Statistiques'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  ),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Serpents & Échelles Party'),
                  subtitle: Text(
                    'Le défi le plus drôle de tous les temps !'
                    '${_versionLabel != null ? '\n$_versionLabel' : ''}',
                  ),
                  isThreeLine: _versionLabel != null,
                ),
              ],
            ),
    );
  }
}
