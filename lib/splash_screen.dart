import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'login_screen.dart';
import 'generator_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAppFlow();
  }

  Future<void> _initializeAppFlow() async {
    try {
      // keep splash visible for 2 s
      await Future.delayed(const Duration(seconds: 2));

      // run consent check
      await _handleConsentFlow();

      // then check Supabase login
      final session = Supabase.instance.client.auth.currentSession;
      if (!mounted) return;

      if (session == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GeneratorScreen()),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Init flow error: $e");
    }
  }

  /// ✅ GDPR consent flow compatible with google_mobile_ads 5.3.x
  Future<void> _handleConsentFlow() async {
    final consentInfo = ConsentInformation.instance;
    final params = ConsentRequestParameters(tagForUnderAgeOfConsent: false);

    consentInfo.requestConsentInfoUpdate(
      params,
          () {
        // success
        ConsentForm.loadAndShowConsentFormIfRequired(
              (FormError? formError) {
            if (formError != null) {
              debugPrint("⚠️ Form error: ${formError.message}");
            }

            // check if ads can be requested (bool getter)
            if (consentInfo.canRequestAds == false) {
              _showConsentRequiredDialog();
            }
          },
        );
      },
          (FormError formError) {
        debugPrint("⚠️ Consent info update failed: ${formError.message}");
      },
    );
  }

  void _showConsentRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1430),
        title: const Text(
          'Consent Required',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You must accept consent to use Astro Lotto Luck. The app will now close.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Future.delayed(const Duration(milliseconds: 300), () {
                Future.delayed(const Duration(seconds: 1), () {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                });
              });
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Color(0xFFFFD166)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/images/astro_lotto_luck_logo.png',
          width: MediaQuery.of(context).size.width * 0.9,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
