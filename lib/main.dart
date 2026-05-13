import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'subscription_service.dart';
import 'screens/age_gate_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  await SubscriptionService.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final userAge = prefs.getInt('user_age');
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(MyApp(
    needsAgeGate: userAge == null,
    showOnboarding: !hasSeenOnboarding && userAge != null,
  ));
}

class MyApp extends StatelessWidget {
  final bool needsAgeGate;
  final bool showOnboarding;

  const MyApp({
    super.key,
    this.needsAgeGate = false,
    this.showOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apex Aura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      ),
      home: needsAgeGate
          ? _AgeGateEntry(showOnboarding: showOnboarding)
          : showOnboarding
              ? const OnboardingScreen()
              : const HomeScreen(),
    );
  }
}

// AgeGate 통과 후 다음 화면으로 이동
class _AgeGateEntry extends StatelessWidget {
  final bool showOnboarding;
  const _AgeGateEntry({required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return AgeGateScreen(
      onPassed: () async {
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getBool('has_seen_onboarding') ?? false;
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => seen ? const HomeScreen() : const OnboardingScreen(),
          ),
        );
      },
    );
  }
}
