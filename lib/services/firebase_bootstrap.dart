import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Lazily initialises Firebase the first time online mode is needed, so the
/// rest of the app (local + Bluetooth play) works even before a Firebase
/// project has been configured.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;

  /// Returns null on success, or a human-readable error message on failure.
  static Future<String?> ensureInitialized() async {
    if (_initialized) return null;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _initialized = true;
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
