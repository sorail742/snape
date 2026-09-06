import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/board_data.dart';
import '../models/board_layout.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import '../network/game_snapshot.dart';
import '../network/network_transport.dart';
import '../services/haptics_service.dart';
import '../services/sound_service.dart';

/// Drives a snakes & ladders match.
///
/// In local (hotseat) play, [transport] is null and every player is rolled
/// on this device. In networked play, exactly one device is the host
/// ([isHost] = true): it runs the real simulation below and broadcasts a
/// [GameSnapshot] to every peer after each change (see the [notifyListeners]
/// override). Non-host devices run the very same class but in a "dumb
/// terminal" mode: [rollDice] just asks the host to roll on their behalf,
/// and incoming `state` messages overwrite the local fields wholesale.
class GameController extends ChangeNotifier {
  GameController({
    required this.players,
    this.transport,
    this.isHost = true,
    this.localPlayerIndex = -1,
    this.layout = BoardLayout.classic,
    this.turnLimit,
    this.aiHandicap = 0,
    this.isSpectator = false,
  }) {
    _logEvent(GameEventType.start, '${players.first.name} commence la partie !');
    _incomingSub = transport?.incoming.listen(_handleIncoming);
    _maybeTriggerBotTurn();
  }

  final List<Player> players;
  final NetworkTransport? transport;
  final bool isHost;
  final BoardLayout layout;

  /// Campaign-stage difficulty knobs — unused (null / 0) outside campaign
  /// mode. [turnLimit] is the number of full rounds the human has to reach
  /// the finish before the stage is lost; [aiHandicap] (0-1) is the chance
  /// the bot rerolls a bad dice result and keeps the better one.
  final int? turnLimit;
  final double aiHandicap;

  /// Index of the player controlled from this device. -1 means every
  /// player is local (hotseat mode) so anyone can roll on any turn.
  final int localPlayerIndex;

  /// A spectator watches a networked match's state but can never roll,
  /// regardless of [localPlayerIndex].
  final bool isSpectator;

  final Random _random = Random();
  StreamSubscription<Map<String, dynamic>>? _incomingSub;

  int currentPlayerIndex = 0;
  int diceValue = 1;
  bool isRolling = false;
  bool isMoving = false;
  int _consecutiveSixes = 0;
  int _roundNumber = 1;
  Player? winner;
  bool isDefeat = false;
  final List<GameEvent> events = [];

  Player get currentPlayer => players[currentPlayerIndex];

  int get roundNumber => _roundNumber;

  bool get isGameOver => winner != null;

  bool get isNetworked => transport != null;

  /// Whether the person holding this device is allowed to tap the dice
  /// right now (always true in hotseat mode).
  bool get canLocalPlayerRoll =>
      !isSpectator && !currentPlayer.isBot && (!isNetworked || localPlayerIndex == currentPlayerIndex);

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (isHost && transport != null) {
      // A flaky Bluetooth/WiFi send must never take down the game loop: if
      // it throws (the underlying Nearby Connections plugin can misbehave
      // on some devices when payloads are sent back-to-back), swallow it
      // here rather than let it unwind into rollDice()/_applyRoll() and
      // leave isRolling/isMoving stuck true forever (dice greyed out for
      // everyone, with no way to recover except restarting the match).
      try {
        final snapshot = GameSnapshot.capture(
          players,
          currentPlayerIndex: currentPlayerIndex,
          diceValue: diceValue,
          isRolling: isRolling,
          isMoving: isMoving,
          events: events,
        );
        transport!.send({'type': 'state', 'snapshot': snapshot.toJson()});
      } catch (e, st) {
        debugPrint('GameController: failed to broadcast state: $e\n$st');
      }
    }
  }

  void _handleIncoming(Map<String, dynamic> message) {
    final type = message['type'];
    if (type == 'state' && !isHost) {
      _applySnapshot(GameSnapshot.fromJson(
        Map<String, dynamic>.from(message['snapshot'] as Map),
      ));
    } else if (type == 'roll_request' && isHost) {
      final idx = message['playerIndex'] as int?;
      if (idx == currentPlayerIndex && !isRolling && !isMoving && !isGameOver) {
        rollDice();
      }
    }
  }

  void _applySnapshot(GameSnapshot snapshot) {
    for (var i = 0; i < players.length && i < snapshot.playerPositions.length; i++) {
      players[i].position = snapshot.playerPositions[i];
    }
    currentPlayerIndex = snapshot.currentPlayerIndex;
    diceValue = snapshot.diceValue;
    isRolling = snapshot.isRolling;
    isMoving = snapshot.isMoving;
    events
      ..clear()
      ..addAll(snapshot.events);
    if (snapshot.winnerIndex != null) {
      for (var i = 0; i < players.length; i++) {
        players[i].hasWon = i == snapshot.winnerIndex;
      }
      winner = players[snapshot.winnerIndex!];
    } else {
      winner = null;
    }
    super.notifyListeners();
  }

  Future<void> rollDice() async {
    if (isSpectator || isRolling || isMoving || isGameOver) return;

    if (isNetworked && !isHost) {
      try {
        transport!.send({'type': 'roll_request', 'playerIndex': currentPlayerIndex});
      } catch (e, st) {
        debugPrint('GameController: failed to send roll_request: $e\n$st');
      }
      return;
    }

    isRolling = true;
    try {
      notifyListeners();

      const rollDuration = Duration(milliseconds: 600);
      const frameDuration = Duration(milliseconds: 70);
      final frames = rollDuration.inMilliseconds ~/ frameDuration.inMilliseconds;
      for (var i = 0; i < frames; i++) {
        diceValue = _random.nextInt(6) + 1;
        unawaited(SoundService.instance.play(GameSound.diceTick));
        HapticsService.instance.selectionClick();
        notifyListeners();
        await Future<void>.delayed(frameDuration);
      }
      if (currentPlayer.isBot && aiHandicap > 0 && _random.nextDouble() < aiHandicap) {
        final reroll = _random.nextInt(6) + 1;
        if (reroll > diceValue) diceValue = reroll;
      }
    } finally {
      // No matter what happened above (including a broadcast hiccup that
      // somehow still threw), the dice must never stay stuck as "rolling".
      isRolling = false;
      notifyListeners();
    }

    await _applyRoll(diceValue);
  }

  Future<void> _applyRoll(int roll) async {
    final player = currentPlayer;

    if (roll == 6) {
      _consecutiveSixes++;
    } else {
      _consecutiveSixes = 0;
    }

    if (_consecutiveSixes == 3) {
      _logEvent(GameEventType.tripleSix, '${player.name} fait trois 6 d\'affilée : tour perdu !');
      _consecutiveSixes = 0;
      _nextTurn();
      return;
    }

    final target = player.position + roll;
    if (target > totalCells) {
      _logEvent(
        GameEventType.skip,
        '${player.name} fait un $roll mais dépasse la case $totalCells : tour passé.',
      );
      _nextTurn();
      return;
    }

    isMoving = true;
    notifyListeners();

    var extraTurnGranted = false;
    try {
      _logEvent(GameEventType.roll, '${player.name} fait un $roll et avance en case $target.');
      await _animateMoveTo(player, target);
      var landedOn = target;

      final bonus = layout.bonusCells[landedOn];
      if (bonus != null) {
        final bonusTarget = (landedOn + bonus).clamp(1, totalCells);
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (bonus > 0) {
          _logEvent(GameEventType.bonus, '${player.name} tombe sur un bonus +$bonus !');
          unawaited(SoundService.instance.play(GameSound.ladder));
          HapticsService.instance.mediumImpact();
        } else {
          _logEvent(GameEventType.malus, '${player.name} tombe sur un malus $bonus !');
          unawaited(SoundService.instance.play(GameSound.snake));
          HapticsService.instance.heavyImpact();
        }
        await _animateMoveTo(player, bonusTarget);
        landedOn = bonusTarget;
      }

      if (layout.snakesAndLadders.containsKey(landedOn)) {
        final destination = layout.snakesAndLadders[landedOn]!;
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (destination > landedOn) {
          _logEvent(
            GameEventType.ladder,
            '${player.name} grimpe une échelle jusqu\'à la case $destination !',
          );
          unawaited(SoundService.instance.play(GameSound.ladder));
          HapticsService.instance.mediumImpact();
        } else {
          _logEvent(
            GameEventType.snake,
            '${player.name} glisse sur un serpent jusqu\'à la case $destination !',
          );
          unawaited(SoundService.instance.play(GameSound.snake));
          HapticsService.instance.heavyImpact();
        }
        await _slideMoveTo(player, destination);
      }

      if (player.position == totalCells) {
        player.hasWon = true;
        winner = player;
        _logEvent(GameEventType.win, '${player.name} remporte la partie !');
        unawaited(SoundService.instance.play(GameSound.win));
        HapticsService.instance.heavyImpact();
      } else if (roll == 6) {
        _logEvent(GameEventType.extraTurn, '${player.name} rejoue grâce au 6 !');
        extraTurnGranted = true;
      }
    } catch (e, st) {
      // Whatever went wrong (a flaky broadcast, a plugin hiccup...), the
      // turn must not get stuck forever with the dice greyed out on every
      // device — log it and fall through to advancing the turn normally.
      debugPrint('GameController: error while resolving a move: $e\n$st');
    } finally {
      isMoving = false;
    }

    if (isGameOver) {
      notifyListeners();
      return;
    }

    if (extraTurnGranted) {
      notifyListeners();
      _maybeTriggerBotTurn();
      return;
    }

    _nextTurn();
  }

  /// Bots only make sense in local (non-networked) play, where a lone human
  /// can still have a match. When it becomes a bot's turn, roll for it
  /// automatically after a short, readable pause.
  void _maybeTriggerBotTurn() {
    if (isNetworked || isGameOver) return;
    final player = currentPlayer;
    if (!player.isBot) return;
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!isGameOver && currentPlayer == player && !isRolling && !isMoving) {
        rollDice();
      }
    });
  }

  /// Slides a player directly to [target] in one smooth move — used for
  /// snakes and ladders, which are shortcuts, not something to count square
  /// by square like a dice move.
  Future<void> _slideMoveTo(Player player, int target) async {
    player.position = target;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  Future<void> _animateMoveTo(Player player, int target) async {
    const stepDelay = Duration(milliseconds: 140);
    final step = target > player.position ? 1 : -1;
    while (player.position != target) {
      player.position += step;
      unawaited(SoundService.instance.play(GameSound.step));
      HapticsService.instance.lightImpact();
      notifyListeners();
      await Future<void>.delayed(stepDelay);
    }
  }

  void _nextTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    if (currentPlayerIndex == 0) {
      _roundNumber++;
      if (turnLimit != null && _roundNumber > turnLimit! && !isGameOver) {
        isDefeat = true;
        winner = players.firstWhere((p) => p.isBot, orElse: () => players.last);
        _logEvent(GameEventType.win, 'Temps écoulé : ${winner!.name} l\'emporte par défaut !');
      }
    }
    notifyListeners();
    _maybeTriggerBotTurn();
  }

  void _logEvent(GameEventType type, String text) {
    events.insert(0, GameEvent(type: type, text: text));
    if (events.length > 50) {
      events.removeLast();
    }
  }

  void restart() {
    if (isNetworked && !isHost) return;
    for (final player in players) {
      player.reset();
    }
    currentPlayerIndex = 0;
    diceValue = 1;
    isRolling = false;
    isMoving = false;
    _consecutiveSixes = 0;
    _roundNumber = 1;
    winner = null;
    isDefeat = false;
    events.clear();
    _logEvent(GameEventType.start, '${players.first.name} commence la partie !');
    notifyListeners();
    _maybeTriggerBotTurn();
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    super.dispose();
  }
}
