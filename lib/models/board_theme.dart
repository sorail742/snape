import 'package:flutter/material.dart';

class BoardTheme {
  const BoardTheme({
    required this.id,
    required this.label,
    required this.icon,
    required this.lightCell,
    required this.darkCell,
    required this.gridLine,
    required this.background,
    required this.paperColor,
    required this.woodTone,
    required this.finishCell,
    required this.bonusText,
    required this.malusText,
    required this.ladderRail,
    required this.ladderRung,
    required this.snakeBody,
    required this.snakeOutline,
    required this.snakeHead,
    required this.accent,
    required this.accentDark,
  });

  final String id;
  final String label;

  /// A representative icon for this theme, used in menus/badges.
  final IconData icon;

  final Color lightCell;
  final Color darkCell;

  /// Pencil/ink colour used for the hand-drawn grid and snake outlines.
  final Color gridLine;

  final Color background;

  /// Fill colour of the paper sheet the board is "drawn" on.
  final Color paperColor;

  /// Surface behind the paper sheet (the "table" it's sitting on).
  final Color woodTone;

  final Color finishCell;
  final Color bonusText;
  final Color malusText;
  final Color ladderRail;
  final Color ladderRung;
  final Color snakeBody;
  final Color snakeOutline;
  final Color snakeHead;
  final Color accent;
  final Color accentDark;

  static const classic = BoardTheme(
    id: 'classic',
    label: 'Classique',
    icon: Icons.casino_rounded,
    lightCell: Color(0xFFFFFDF7),
    darkCell: Color(0xFFFFFDF7),
    gridLine: Color(0xFF3E3E3E),
    background: Color(0xFFFFF3E0),
    paperColor: Color(0xFFFFFDF7),
    woodTone: Color(0xFFC68A4E),
    finishCell: Color(0xFFFFD54F),
    bonusText: Color(0xFF2E7D32),
    malusText: Color(0xFFC62828),
    ladderRail: Color(0xFF6D4C41),
    ladderRung: Color(0xFF4E342E),
    snakeBody: Color(0xFF66BB6A),
    snakeOutline: Color(0xFF2E7D32),
    snakeHead: Color(0xFF388E3C),
    accent: Color(0xFFFB8C00),
    accentDark: Color(0xFFE65100),
  );

  static const neon = BoardTheme(
    id: 'neon',
    label: 'Néon',
    icon: Icons.bolt_rounded,
    lightCell: Color(0xFF1A1A2E),
    darkCell: Color(0xFF16213E),
    gridLine: Color(0xFF3FA7FF),
    background: Color(0xFF0F0F1A),
    paperColor: Color(0xFF161B2E),
    woodTone: Color(0xFF05070F),
    finishCell: Color(0xFFFFEE58),
    bonusText: Color(0xFF00E676),
    malusText: Color(0xFFFF1744),
    ladderRail: Color(0xFF00E5FF),
    ladderRung: Color(0xFF18FFFF),
    snakeBody: Color(0xFFFF2E93),
    snakeOutline: Color(0xFFB6006B),
    snakeHead: Color(0xFFFF6EC7),
    accent: Color(0xFF00E5FF),
    accentDark: Color(0xFF0091EA),
  );

  static const nature = BoardTheme(
    id: 'nature',
    label: 'Nature',
    icon: Icons.eco_rounded,
    lightCell: Color(0xFFF3F8ED),
    darkCell: Color(0xFFF3F8ED),
    gridLine: Color(0xFF33691E),
    background: Color(0xFFE8F5E9),
    paperColor: Color(0xFFF3F8ED),
    woodTone: Color(0xFF5D4037),
    finishCell: Color(0xFFFFF176),
    bonusText: Color(0xFF2E7D32),
    malusText: Color(0xFFD84315),
    ladderRail: Color(0xFF795548),
    ladderRung: Color(0xFF5D4037),
    snakeBody: Color(0xFF8D6E63),
    snakeOutline: Color(0xFF4E342E),
    snakeHead: Color(0xFF6D4C41),
    accent: Color(0xFF43A047),
    accentDark: Color(0xFF2E7D32),
  );

  /// Uses the Okabe-Ito colorblind-safe palette — blue for bonuses and a
  /// distinct vermillion/orange for maluses instead of green/red, which are
  /// the pair most commonly confused by colorblind players.
  static const colorblind = BoardTheme(
    id: 'colorblind',
    label: 'Daltonien',
    icon: Icons.visibility_rounded,
    lightCell: Color(0xFFFFFDF7),
    darkCell: Color(0xFFFFFDF7),
    gridLine: Color(0xFF2B2B2B),
    background: Color(0xFFF5F0E6),
    paperColor: Color(0xFFFFFDF7),
    woodTone: Color(0xFF5B4636),
    finishCell: Color(0xFFF0E442),
    bonusText: Color(0xFF0072B2),
    malusText: Color(0xFFD55E00),
    ladderRail: Color(0xFF5B4636),
    ladderRung: Color(0xFF3A2E24),
    snakeBody: Color(0xFF0072B2),
    snakeOutline: Color(0xFF003A5C),
    snakeHead: Color(0xFF0072B2),
    accent: Color(0xFFE69F00),
    accentDark: Color(0xFF8F5F00),
  );

  /// Inspired by Gyan Chaupar, the centuries-old Indian ancestor of
  /// Snakes & Ladders (see `designs.md` §1): saffron, peacock blue and
  /// gold-leaf on an ivory parchment background.
  static const royal = BoardTheme(
    id: 'royal',
    label: 'Royal Indien',
    icon: Icons.stars_rounded,
    lightCell: Color(0xFFFDF6E3),
    darkCell: Color(0xFFFDF6E3),
    gridLine: Color(0xFF4A2C1A),
    background: Color(0xFFFBF0DA),
    paperColor: Color(0xFFF6E3B4),
    woodTone: Color(0xFF5A2E1D),
    finishCell: Color(0xFFE6B325),
    bonusText: Color(0xFF0B6E4F),
    malusText: Color(0xFFA6192E),
    ladderRail: Color(0xFFC9942B),
    ladderRung: Color(0xFF8C5E15),
    snakeBody: Color(0xFF0F7173),
    snakeOutline: Color(0xFF0A3D3F),
    snakeHead: Color(0xFF17A398),
    accent: Color(0xFFF2913D),
    accentDark: Color(0xFFB85C1E),
  );

  static const all = [classic, neon, nature, colorblind, royal];

  static BoardTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => classic);
}
