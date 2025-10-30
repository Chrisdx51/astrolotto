// 🪐 Astro Lotto Luck — Full iOS Build Entry File (Stable + Safe)

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🪐 Core Screens
import 'saved_draws_screen.dart';
import 'supabase_config.dart';
import 'login_screen.dart';
import 'generator_screen.dart';
import 'splash_screen.dart';
import 'about_screen.dart';

// 🌠 Premium Realm Screens
import 'screens/premium_realm_screen.dart';
import 'screens/forecast_screen.dart';
import 'screens/lucky_crystal_screen.dart';
import 'screens/vip_generator_screen.dart';
import 'screens/manifestation_journal_screen.dart';
import 'screens/meditation_mode_screen.dart';
import 'screens/ad_free_mode_screen.dart';
import 'screens/vip_paywall_screen.dart';
import 'screens/subscribe_screen.dart';

// 💫 Cosmic AI Service
import 'services/cosmic_ai_service.dart';

/// ✅ Google AdMob IDs
const String bannerTopId = 'ca-app-pub-5354629198133392/7753523660';
const String bannerBottomId = 'ca-app-pub-5354629198133392/6576173364';
const String interstitialGenerateId = 'ca-app-pub-5354629198133392/9358636415';
const String bannerAdUnitId = bannerBottomId;

/// ✅ Local notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint("📩 Background Notification: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase first
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // ✅ Local notification initialization
  const DarwinInitializationSettings iosSettings =
  DarwinInitializationSettings(
    requestSoundPermission: true,
    requestAlertPermission: true,
    requestBadgePermission: true,
  );

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(iOS: iosSettings),
  );

  // ✅ Request permission for iOS notifications
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, sound: true, badge: true);

  // ✅ Load environment
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("⚠️ Could not load .env file: $e");
  }

  // ✅ Initialize Supabase
  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  } catch (e) {
    debugPrint("⚠️ Supabase init failed: $e");
  }

  // ✅ Initialize Ads (iOS-safe)
  await MobileAds.instance.initialize();

  final prefs = await SharedPreferences.getInstance();
  final savedVip = prefs.getBool('is_vip') ?? false;

  runApp(AstroLottoLuckApp(initialVip: savedVip));
}

/// 🌙 Main App Shell
class AstroLottoLuckApp extends StatelessWidget {
  final bool initialVip;
  const AstroLottoLuckApp({super.key, required this.initialVip});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0F1A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFFD166),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F1430),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: TextStyle(fontSize: 13, color: Colors.white54),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF10162C),
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),





      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          bodyMedium: TextStyle(fontSize: 13, height: 1.35, color: Colors.white),
          headlineSmall: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ),
    );

    return MaterialApp(
      title: 'Astro Lotto Luck',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const VersionChecker(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/generator': (_) => const GeneratorScreen(),
        '/saved': (_) => const SavedDrawsScreen(),
        '/subscribe': (_) => const SubscribeScreen(),
        '/about': (_) => const AboutScreen(),
        '/premium': (_) => const PremiumRealmScreen(),
        '/forecast': (_) => const ForecastScreen(),
        '/crystal': (_) => const LuckyCrystalScreen(isPremium: true),
        '/vip': (_) => const VipGeneratorScreen(),
        '/journal': (_) => const ManifestationJournalScreen(),
        '/meditation': (_) => const MeditationModeScreen(),
        '/adfree': (_) => const AdFreeModeScreen(),
      },
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final clamped = media.textScaleFactor.clamp(0.85, 1.0);
        return MediaQuery(
          data: media.copyWith(textScaleFactor: clamped),
          child: SafeArea(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

/// 🔍 Version Checker (shared with Android)
class VersionChecker extends StatefulWidget {
  const VersionChecker({super.key});

  @override
  State<VersionChecker> createState() => _VersionCheckerState();
}

class _VersionCheckerState extends State<VersionChecker> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkVersion();
      if (mounted) setState(() => _checking = false);
    });
  }

  Future<void> _checkVersion() async {
    final supabase = Supabase.instance.client;
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    try {
      final response = await supabase
          .from('app_version')
          .select()
          .eq('platform', Platform.isIOS ? 'ios' : 'android')
          .maybeSingle();

      if (response == null) return;
      final latest = response['latest_version'] as String;
      final force = response['force_update'] as bool? ?? false;
      final notes = response['release_notes'] as String? ?? "";

      if (_isNewerVersion(latest, currentVersion) && force) {
        _showUpdateDialog(latest, notes);
      }
    } catch (e) {
      debugPrint("⚠️ Version check failed: $e");
    }
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  void _showUpdateDialog(String latest, String notes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF10162C),
        title: const Text("🚀 Update Required",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "A new version ($latest) of Astro Lotto Luck is available.\n\n$notes",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              const url =
                  "https://apps.apple.com/app/id6754510977"; // Your App Store link
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              }
            },
            child: const Text("Update Now",
                style: TextStyle(color: Colors.amberAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0F1A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.amberAccent),
        ),
      );
    }
    return const SplashScreen();
  }
}
