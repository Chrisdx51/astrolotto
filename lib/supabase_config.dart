import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ✅ Safe accessors for environment values
/// These read after .env has been loaded in main.dart or main_ios.dart.

String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

/// 🍏 iOS Subscription Settings
/// Used by in_app_purchase to verify iOS receipts
String get appStoreSharedSecret => dotenv.env['APPSTORE_SHARED_SECRET'] ?? '';

/// 🪐 Product IDs (must match App Store & Play Store)
const String iosWeeklyId = 'vip_weekly_v2';
const String iosMonthlyId = 'vip_monthly_v2';
const String iosYearlyId = 'vip_yearly_v2';
