import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/settings_service.dart';
import 'home_mode_screen.dart';
import 'onboarding_screen.dart';
import 'whats_new_screen.dart';

/// Decides whether to show the first-launch onboarding, a "what's new"
/// changelog after an update, or go straight to the home screen, based on
/// persisted state.
///
/// This widget itself is the app's root, so it is never pushed onto a
/// Navigator — switching between these has to happen via a rebuild
/// (setState), not `Navigator.pop`, which would empty the stack.
class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({super.key});

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

enum _EntryStage { loading, onboarding, whatsNew, home }

class _AppEntryScreenState extends State<AppEntryScreen> {
  _EntryStage _stage = _EntryStage.loading;
  String _currentVersion = '';

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final seenOnboarding = await SettingsService.instance.hasSeenOnboarding();
    if (!seenOnboarding) {
      if (mounted) setState(() => _stage = _EntryStage.onboarding);
      return;
    }
    final info = await PackageInfo.fromPlatform();
    final lastSeen = await SettingsService.instance.loadLastSeenVersion();
    _currentVersion = info.version;
    if (lastSeen != null && lastSeen != info.version) {
      if (mounted) setState(() => _stage = _EntryStage.whatsNew);
    } else {
      await SettingsService.instance.setLastSeenVersion(info.version);
      if (mounted) setState(() => _stage = _EntryStage.home);
    }
  }

  Future<void> _finishOnboarding() async {
    final info = await PackageInfo.fromPlatform();
    await SettingsService.instance.setLastSeenVersion(info.version);
    if (mounted) setState(() => _stage = _EntryStage.home);
  }

  Future<void> _dismissWhatsNew() async {
    await SettingsService.instance.setLastSeenVersion(_currentVersion);
    if (mounted) setState(() => _stage = _EntryStage.home);
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _EntryStage.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _EntryStage.onboarding:
        return OnboardingScreen(onFinished: _finishOnboarding);
      case _EntryStage.whatsNew:
        return WhatsNewScreen(version: _currentVersion, onDismiss: _dismissWhatsNew);
      case _EntryStage.home:
        return const HomeModeScreen();
    }
  }
}
