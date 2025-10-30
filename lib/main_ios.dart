// 🪐 Astro Lotto Luck — iOS Safe Main Entry
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'main.dart'; // keep access to your app classes, routes, etc.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() async {
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    await MobileAds.instance.initialize();

    if (Platform.isIOS) {
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint("⚠️ Firebase init failed on iOS: $e");
      }
    }

    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await flutterLocalNotificationsPlugin.initialize(settings);
    } catch (e) {
      debugPrint("⚠️ Notifications init failed: $e");
    }

    runApp(const AstroLottoLuckApp(initialVip: false));
  }, (error, stack) {
    debugPrint("🔥 Startup zone error: $error\n$stack");
  });
}
