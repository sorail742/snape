import 'dart:io';

import 'package:flutter/material.dart';

import '../models/player.dart';

/// Renders a player's avatar: their custom photo when they picked one,
/// otherwise their chosen emoji, with a small robot badge for bots.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.player,
    this.radius = 18,
    this.ringColor,
  });

  final Player player;
  final double radius;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final imagePath = player.avatarImagePath;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: player.color,
      backgroundImage: imagePath != null ? FileImage(File(imagePath)) : null,
      child: imagePath == null
          ? Text(player.avatarEmoji, style: TextStyle(fontSize: radius * 0.95))
          : null,
    );

    final decorated = ringColor == null
        ? avatar
        : Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor!, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 2)),
              ],
            ),
            child: avatar,
          );

    if (!player.isBot) return decorated;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        decorated,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.smart_toy_rounded, size: radius * 0.7, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
