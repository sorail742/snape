import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/app_entry_screen.dart';
import 'services/haptics_service.dart';
import 'services/settings_service.dart';
import 'services/sound_service.dart';

/// Whether the app should tint itself with the phone's Material You colours
/// (Android 12+) instead of its own orange branding. A [ValueNotifier] so
/// Settings can flip it and see the whole app retint immediately.
final materialYouEnabled = ValueNotifier<bool>(false);

/// App-wide text scale multiplier for accessibility, settable from Settings.
final textScale = ValueNotifier<double>(1.0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SoundService.instance.enabled = await SettingsService.instance.loadSoundEnabled();
  SoundService.instance.volume = await SettingsService.instance.loadVolume();
  HapticsService.instance.intensity =
      HapticIntensity.values[await SettingsService.instance.loadHapticIntensity()];
  materialYouEnabled.value = await SettingsService.instance.loadMaterialYouEnabled();
  textScale.value = await SettingsService.instance.loadTextScale();
  runApp(const SerpentsPartyApp());
}

class SerpentsPartyApp extends StatelessWidget {
  const SerpentsPartyApp({super.key});

  ThemeData _buildTheme(ColorScheme? dynamicScheme) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: dynamicScheme,
      colorSchemeSeed: dynamicScheme == null ? const Color(0xFFFB8C00) : null,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF212121),
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF212121),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return baseTheme.copyWith(textTheme: GoogleFonts.baloo2TextTheme(baseTheme.textTheme));
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return ValueListenableBuilder<bool>(
          valueListenable: materialYouEnabled,
          builder: (context, useMaterialYou, _) {
            final dynamicScheme = useMaterialYou ? lightDynamic : null;
            return ValueListenableBuilder<double>(
              valueListenable: textScale,
              builder: (context, scale, _) {
                return MaterialApp(
                  title: 'Serpents & Échelles Party',
                  debugShowCheckedModeBanner: false,
                  theme: _buildTheme(dynamicScheme),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: const AppEntryScreen(),
                );
              },
            );
          },
        );
      },
    );
  }
}
