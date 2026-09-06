import 'package:shared_preferences/shared_preferences.dart';

/// Tracks progress through the solo campaign: the highest level (1-120,
/// across all 4 worlds of 30 levels each) the player has unlocked so far.
class CampaignService {
  CampaignService._();

  static final CampaignService instance = CampaignService._();

  static const _unlockedKey = 'campaign_unlocked_level';

  Future<int> loadUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unlockedKey) ?? 1;
  }

  Future<void> unlockLevel(int globalIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_unlockedKey) ?? 1;
    if (globalIndex > current) {
      await prefs.setInt(_unlockedKey, globalIndex);
    }
  }
}
