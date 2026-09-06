import 'package:audioplayers/audioplayers.dart';

enum GameSound { diceTick, step, ladder, snake, win }

class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  bool enabled = true;
  double volume = 1.0;

  static const _assetPaths = {
    GameSound.diceTick: 'sounds/dice_tick.mp3',
    GameSound.step: 'sounds/step.mp3',
    GameSound.ladder: 'sounds/ladder.mp3',
    GameSound.snake: 'sounds/snake.mp3',
    GameSound.win: 'sounds/win.mp3',
  };

  final Map<GameSound, AudioPlayer> _players = {};

  AudioPlayer _playerFor(GameSound sound) {
    return _players.putIfAbsent(sound, () => AudioPlayer(playerId: sound.name));
  }

  Future<void> play(GameSound sound) async {
    if (!enabled) return;
    final player = _playerFor(sound);
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource(_assetPaths[sound]!));
    } catch (_) {
      // Best-effort: playback issues (e.g. no audio device) shouldn't crash the game.
    }
  }

  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}
