import 'package:flutter/material.dart';

/// Shows a consistently-styled, floating, rounded SnackBar across the app
/// instead of the plain default one.
void showAppSnackBar(
  BuildContext context,
  String text, {
  IconData icon = Icons.check_circle_rounded,
  Color? color,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color ?? const Color(0xFF323232),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}
