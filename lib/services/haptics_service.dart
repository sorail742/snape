import 'package:flutter/services.dart';

enum HapticIntensity { off, light, full }

class HapticsService {
  HapticsService._();

  static final HapticsService instance = HapticsService._();

  HapticIntensity intensity = HapticIntensity.full;

  bool get enabled => intensity != HapticIntensity.off;

  void selectionClick() {
    if (intensity == HapticIntensity.off) return;
    HapticFeedback.selectionClick();
  }

  void lightImpact() {
    if (intensity == HapticIntensity.off) return;
    HapticFeedback.lightImpact();
  }

  void mediumImpact() {
    if (intensity == HapticIntensity.off) return;
    // "Léger" caps every haptic at the lightest feedback level instead of
    // scaling with how important the event is.
    intensity == HapticIntensity.light ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact();
  }

  void heavyImpact() {
    if (intensity == HapticIntensity.off) return;
    intensity == HapticIntensity.light ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
  }
}
