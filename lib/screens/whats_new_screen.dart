import 'package:flutter/material.dart';

/// Changelog highlights per version, newest first — shown once to a
/// returning player right after an update, so new features aren't missed.
const Map<String, List<String>> _changelog = {
  '1.1.0': [
    'Mode Campagne : 4 étapes de plus en plus difficiles jusqu\'à la Grande Coupe',
    'Mode Tournoi : 4 ou 8 joueurs en élimination directe',
    'Défi du jour : le même plateau pour tout le monde, avec série de victoires 🔥',
    'Éditeur de plateau personnalisé et thème Daltonien',
    'Salons publics et mode spectateur en ligne',
    'Replay des parties terminées, styles de dé, secouer pour lancer',
  ],
};

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key, required this.version, required this.onDismiss});

  final String version;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final notes = _changelog[version] ?? const [];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFB8C00), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Nouveautés de la version $version',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...notes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF43A047)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(note)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onDismiss,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Super, on y va !'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
