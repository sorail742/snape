import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/settings_service.dart';

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}

const _steps = [
  _OnboardingStep(
    icon: Icons.casino_rounded,
    title: 'Étape 1 · Lance le dé',
    description:
        'À chaque tour, appuie sur le dé pour le lancer et avancer ton pion '
        'sur le plateau. Un 6 te fait rejouer !',
    color: Color(0xFFFB8C00),
  ),
  _OnboardingStep(
    icon: Icons.stairs_rounded,
    title: 'Étape 2 · Échelles, serpents & bonus',
    description:
        'Grimpe les échelles pour avancer plus vite, évite les serpents '
        'qui te font reculer, et profite des cases bonus/malus (+3, +2, -2) !',
    color: Color(0xFF43A047),
  ),
  _OnboardingStep(
    icon: Icons.public_rounded,
    title: 'Étape 3 · Joue comme tu veux',
    description:
        'En local sur le même téléphone, entre amis en Bluetooth sans '
        'internet, ou en ligne avec un simple code de salon.',
    color: Color(0xFF1E88E5),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.isReplay = false, this.onFinished});

  /// When true, this is opened from Settings ("Comment jouer") rather than
  /// the first-launch flow: no "skip", and the last button just closes it.
  final bool isReplay;

  /// Called instead of `Navigator.pop` when this screen is shown as the
  /// app's root widget (first launch) rather than pushed onto a Navigator
  /// stack — there is nothing to pop in that case.
  final VoidCallback? onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _page = 0;
  int? _previousPage;
  late final AnimationController _ripple;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ripple.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _goTo(int target) {
    if (target < 0 || target >= _steps.length || target == _page || _ripple.isAnimating) return;
    HapticFeedback.selectionClick();
    setState(() {
      _previousPage = _page;
      _page = target;
    });
    _ripple
      ..reset()
      ..forward().whenComplete(() {
        if (mounted) setState(() => _previousPage = null);
      });
  }

  Future<void> _finish() async {
    if (!widget.isReplay) {
      await SettingsService.instance.setOnboardingSeen();
    }
    if (!mounted) return;
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildStep(_OnboardingStep s, int index) {
    return Container(
      color: s.color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ÉTAPE ${index + 1}/${_steps.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0.1)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 3),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(s.icon, size: 76, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              s.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                height: 1.2,
                shadows: [Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                s.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_page];
    return Scaffold(
      backgroundColor: step.color,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.isReplay)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Passer', style: TextStyle(color: Colors.white)),
                ),
              ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v < -200) {
                    _goTo(_page + 1);
                  } else if (v > 200) {
                    _goTo(_page - 1);
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildStep(step, _page),
                    if (_previousPage != null)
                      AnimatedBuilder(
                        animation: _ripple,
                        builder: (context, child) {
                          final t = Curves.easeInOutCubic.transform(_ripple.value);
                          return ClipPath(
                            clipper: _RippleHoleClipper(progress: t),
                            child: child,
                          );
                        },
                        child: _buildStep(_steps[_previousPage!], _previousPage!),
                      ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: i == _page ? 1 : 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final isLast = _page == _steps.length - 1;
                  final scale = isLast ? 1.0 + _pulse.value * 0.03 : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: step.color,
                      elevation: 4,
                      shadowColor: Colors.black45,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (_page == _steps.length - 1) {
                        _finish();
                      } else {
                        _goTo(_page + 1);
                      }
                    },
                    child: Text(
                      _page == _steps.length - 1
                          ? (widget.isReplay ? 'Fermer' : 'Commencer à jouer')
                          : 'Suivant',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

/// Clips away a wavy, rippling hole that grows from the centre of the
/// screen outward — like a stone dropped in water — revealing the next
/// step underneath as the previous one "dissolves" into the ripple and
/// disappears, per the requested ripple/wave transition.
class _RippleHoleClipper extends CustomClipper<Path> {
  _RippleHoleClipper({required this.progress});

  final double progress;

  @override
  Path getClip(Size size) {
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    if (progress <= 0) return full;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide * 0.85;
    final radius = maxRadius * progress;
    // The ripple wobble fades out as the hole grows, so it settles into a
    // clean circle right before fully covering the previous step.
    final wobble = 14.0 * (1 - progress);
    const waves = 10;

    final hole = Path();
    for (var i = 0; i <= 360; i += 4) {
      final angle = i * math.pi / 180;
      final r = radius + math.sin(angle * waves + progress * 18) * wobble;
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        hole.moveTo(point.dx, point.dy);
      } else {
        hole.lineTo(point.dx, point.dy);
      }
    }
    hole.close();

    if (progress >= 1) return Path();
    return Path.combine(ui.PathOperation.difference, full, hole);
  }

  @override
  bool shouldReclip(covariant _RippleHoleClipper oldClipper) =>
      oldClipper.progress != progress;
}
