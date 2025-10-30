import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
// 🍏 iOS Subscription Settings
// Used by in_app_purchase to verify iOS receipts
const String appStoreSharedSecret = '54e2bacbf1f54db1b0e190e4aecccf67';

// These must exactly match your App Store product IDs:
const String iosWeeklyId = 'vip_weekly_v2';
const String iosMonthlyId = 'vip_monthly_v2';
const String iosYearlyId = 'vip_yearly_v2';
