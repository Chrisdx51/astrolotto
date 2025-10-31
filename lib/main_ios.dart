// 🪐 Astro Lotto Luck — Simplified iOS Entry File (safe for Codemagic)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'main.dart'; // reuse all screens + widgets
import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("🟢 iOS entrypoint started — Flutter running!");

  // ✅ Initialize Firebase
  await Firebase.initializeApp();

  // ✅ Load .env (safe if missing)
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  // ✅ Initialize Supabase
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    print("⚠️ Supabase init failed: $e");
  }

  // ✅ Initialize AdMob (after Firebase)
  await MobileAds.instance.initialize();

  // ✅ Restore VIP flag
  final prefs = await SharedPreferences.getInstance();
  final savedVip = prefs.getBool('is_vip') ?? false;

  // ✅ Run the same main app
  runApp(AstroLottoLuckApp(initialVip: savedVip));
}
