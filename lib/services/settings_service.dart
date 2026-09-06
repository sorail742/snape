import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const _soundKey = 'sound_enabled';
  static const _volumeKey = 'sound_volume';
  static const _hapticIntensityKey = 'haptics_intensity';
  static const _themeKey = 'default_theme_id';
  static const _onboardingKey = 'onboarding_seen';
  static const _lastPlayersKey = 'last_local_players';
  static const _profilesKey = 'saved_profiles_v1';
  static const _materialYouKey = 'material_you_enabled';
  static const _shakeToRollKey = 'shake_to_roll_enabled';
  static const _diceSkinKey = 'dice_skin';
  static const _textScaleKey = 'text_scale';
  static const _lastSeenVersionKey = 'last_seen_version';

  Future<bool> loadSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundKey) ?? true;
  }

  Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
  }

  /// 0 = off, 1 = léger, 2 = fort (kept as a plain int here so this service
  /// doesn't need to import the haptics service just for its enum).
  Future<int> loadHapticIntensity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_hapticIntensityKey) ?? 2;
  }

  Future<void> setHapticIntensity(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hapticIntensityKey, value);
  }

  Future<double> loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_volumeKey) ?? 1.0;
  }

  Future<void> setVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, value);
  }

  Future<String> loadDefaultThemeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'classic';
  }

  Future<void> setDefaultThemeId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, id);
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Remembers local players' names/colors/avatars/bot flags across
  /// sessions, so a returning group doesn't have to retype everything.
  Future<List<Map<String, dynamic>>> loadLastPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastPlayersKey);
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLastPlayers(List<Map<String, dynamic>> players) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlayersKey, jsonEncode(players));
  }

  /// A growing roster of real players who've played before (name, avatar,
  /// colour), separate from [loadLastPlayers] which only remembers the most
  /// recent lineup. Lets a returning player be picked by name instead of
  /// retyping/re-picking their avatar every time.
  Future<List<Map<String, dynamic>>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profilesKey);
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {
      return [];
    }
  }

  /// Adds a profile, or refreshes it in place if a profile with the same
  /// name already exists (so re-picking an avatar/photo updates the roster
  /// instead of creating a duplicate).
  Future<void> upsertProfile(Map<String, dynamic> profile) async {
    final profiles = await loadProfiles();
    final idx = profiles.indexWhere((p) => p['name'] == profile['name']);
    if (idx >= 0) {
      profiles[idx] = profile;
    } else {
      profiles.add(profile);
      if (profiles.length > 20) profiles.removeAt(0);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilesKey, jsonEncode(profiles));
  }

  Future<bool> loadMaterialYouEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_materialYouKey) ?? false;
  }

  Future<void> setMaterialYouEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_materialYouKey, value);
  }

  Future<bool> loadShakeToRollEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_shakeToRollKey) ?? true;
  }

  Future<void> setShakeToRollEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shakeToRollKey, value);
  }

  /// Index into `DiceSkin.values` (0=classic, 1=digits, 2=neon, 3=wood).
  Future<int> loadDiceSkin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_diceSkinKey) ?? 0;
  }

  Future<void> setDiceSkin(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_diceSkinKey, value);
  }

  /// A text scale multiplier applied app-wide for accessibility (1.0 =
  /// normal, up to 1.3 for larger text).
  Future<double> loadTextScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_textScaleKey) ?? 1.0;
  }

  Future<void> setTextScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, value);
  }

  /// Null the very first time the app ever runs (no changelog to show yet).
  Future<String?> loadLastSeenVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSeenVersionKey);
  }

  Future<void> setLastSeenVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenVersionKey, version);
  }
}
