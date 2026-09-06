import 'package:flutter/material.dart';

const List<String> playerAvatarEmojis = ['😀', '🐱', '🦁', '🐸', '🦄', '🐼', '🐵', '🦊'];

class Player {
  Player({
    required this.name,
    required this.color,
    this.avatarEmoji = '😀',
    this.avatarImagePath,
    this.isBot = false,
  });

  final String name;
  final Color color;
  final String avatarEmoji;

  /// Path to a local image file the player picked as their avatar. When
  /// set, it takes priority over [avatarEmoji] in the UI. Only meaningful
  /// on the device that owns the file (not transmitted over the network).
  final String? avatarImagePath;

  /// True for a computer-controlled player (see [GameController]'s bot
  /// auto-roll logic), so a single person can play without other humans.
  final bool isBot;

  int position = 0;
  bool hasWon = false;

  void reset() {
    position = 0;
    hasWon = false;
  }
}
