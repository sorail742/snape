import 'package:flutter/material.dart';

/// Fades and slides a list item in the first time it's built — give each
/// instance a stable, unique [key] (e.g. a player's id/name) so Flutter
/// treats a genuinely new entry as new but leaves existing ones alone on
/// unrelated rebuilds. Used for lobby rosters so a player joining feels
/// alive instead of a flat instant re-render.
class AnimatedListEntry extends StatelessWidget {
  const AnimatedListEntry({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
      ),
      child: child,
    );
  }
}
