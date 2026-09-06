import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:serpents_party/screens/home_mode_screen.dart';
import 'package:serpents_party/screens/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding shows the first step', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.textContaining('Étape 1'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });

  testWidgets('Home screen shows title and mode choices', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: HomeModeScreen()));
    await tester.pump();

    expect(find.text('Jouer en local'), findsOneWidget);
    expect(find.text('Bluetooth à proximité'), findsOneWidget);
    expect(find.text('En ligne'), findsOneWidget);
  });
}
