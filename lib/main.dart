import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/age_gate_screen.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  await SubscriptionService.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apex Aura',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko'), Locale('en')],
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      ),
      home: const _EntryGate(),
    );
  }
}

/// 진입 라우팅: 연령 확인(1회) → 온보딩(1회) → 홈.
/// AgeGate 통과 후 _decide()를 다시 돌려 다음 단계로 넘어간다.
class _EntryGate extends StatefulWidget {
  const _EntryGate();

  @override
  State<_EntryGate> createState() => _EntryGateState();
}

class _EntryGateState extends State<_EntryGate> {
  String? _route; // 'age' | 'onboarding' | 'home'

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final prefs = await SharedPreferences.getInstance();
    final agePassed = prefs.getBool('age_passed') ?? false;
    final seenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    if (!mounted) return;
    setState(() {
      _route = !agePassed
          ? 'age'
          : (!seenOnboarding ? 'onboarding' : 'home');
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_route) {
      case 'age':
        return AgeGateScreen(onPassed: () => _decide());
      case 'onboarding':
        return const OnboardingScreen();
      case 'home':
        return const HomeScreen();
      default:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
    }
  }
}
