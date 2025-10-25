import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VipService {
  static const vipKey = 'is_vip';

  /// ✅ Load from local cache
  static Future<bool> loadLocalVip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(vipKey) ?? false;
  }

  /// ✅ Save to local cache
  static Future<void> saveLocalVip(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(vipKey, status);
  }

  /// ✅ Check Supabase — slow (server)
  static Future<bool> fetchSupabaseVip() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return false;

    final data = await supabase
        .from('profiles')
        .select('is_vip')
        .eq('id', user.id)
        .maybeSingle();

    final isVip = data?['is_vip'] == true;

    await saveLocalVip(isVip);
    return isVip;
  }

  /// ✅ Main function to get the truth
  static Future<bool> getVipStatus() async {
    final local = await loadLocalVip();
    if (local) return true;
    return await fetchSupabaseVip();
  }
}
