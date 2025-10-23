import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'saved_draws_screen.dart';
import 'supabase_config.dart';
import 'login_screen.dart';
import 'generator_screen.dart';
import 'splash_screen.dart';
import 'screens/premium_realm_screen.dart'; // 👈 new import
import 'screens/forecast_screen.dart';

/// ✅ Google AdMob Ad Unit IDs
const String bannerTopId = 'ca-app-pub-5354629198133392/7753523660';
const String bannerBottomId = 'ca-app-pub-5354629198133392/6576173364';
const String interstitialGenerateId = 'ca-app-pub-5354629198133392/9358636415';
const String bannerAdUnitId = bannerBottomId;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    debugPrint("⚠️ Could not load .env file.");
  }

  // 2️⃣ Initialize Supabase
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint("⚠️ Supabase init failed: $e");
  }

  // 3️⃣ Initialize Google Ads
  await MobileAds.instance.initialize();

  // 4️⃣ Run the app
  runApp(const AstroLottoLuckApp());
}

/// 🌙 Main App Shell
class AstroLottoLuckApp extends StatelessWidget {
  const AstroLottoLuckApp({super.key});

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
      cardTheme: const CardThemeData(
        color: Color(0xFF10162C),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 13, height: 1.35, color: Colors.white),
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
        '/premium': (_) => const PremiumRealmScreen(), // 👈 NEW premium page route
        '/forecast': (_) => const ForecastScreen(),

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

/// 🔍 Version Check Screen
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
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    final supabase = Supabase.instance.client;
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    try {
      final response = await supabase
          .from('app_version')
          .select()
          .eq('platform', Platform.isAndroid ? 'android' : 'ios')
          .maybeSingle();

      if (response == null) {
        setState(() => _checking = false);
        return;
      }

      final latest = response['latest_version'] as String;
      final force = response['force_update'] as bool? ?? false;
      final notes = response['release_notes'] as String? ?? "";

      if (_isNewerVersion(latest, currentVersion) && force) {
        _showUpdateDialog(latest, notes);
      } else {
        setState(() => _checking = false);
      }
    } catch (e) {
      debugPrint("⚠️ Version check failed: $e");
      setState(() => _checking = false);
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
        title: const Text(
          "🚀 Update Required",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "A new version ($latest) of Astro Lotto Luck is available.\n\n$notes",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              const url =
                  "https://play.google.com/store/apps/details?id=com.ck.astrolotto";
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              }
            },
            child: const Text(
              "Update Now",
              style: TextStyle(color: Colors.amberAccent),
            ),
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

/// 🧱 Reusable Banner Widget
class BannerAdWidget extends StatefulWidget {
  final bool isTop;
  const BannerAdWidget({super.key, this.isTop = false});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _banner;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _banner = BannerAd(
      adUnitId: widget.isTop ? bannerTopId : bannerBottomId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          debugPrint('⚠️ Banner failed: $err');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      margin: widget.isTop
          ? const EdgeInsets.only(top: 6, bottom: 4)
          : const EdgeInsets.only(top: 10, bottom: 4),
      child: AdWidget(ad: _banner!),
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
    );
  }
}
