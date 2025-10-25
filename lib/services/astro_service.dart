import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Data model for astronomy data (moon & sun).
class AstroData {
  final String moonPhaseName;
  final double moonIllumination;
  final String moonPhaseIcon;
  final String sunRise;
  final String sunSet;

  const AstroData({
    required this.moonPhaseName,
    required this.moonIllumination,
    required this.moonPhaseIcon,
    required this.sunRise,
    required this.sunSet,
  });
}

/// Handles fetching moon/sun data and zodiac calculations.
class AstroService {
  final String baseUrl = "https://api.astronomyapi.com/api/v2";

  /// Fetches moon and sun data for a given location and date.
  Future<AstroData?> fetchAstroData({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) async {
    final appId = dotenv.env['ASTRO_API_APP_ID'];
    final appSecret = dotenv.env['ASTRO_API_SECRET'];

    // ✅ Validate .env setup
    if (appId == null || appSecret == null || appId.isEmpty || appSecret.isEmpty) {
      print("❌ Missing ASTRO_API_APP_ID or ASTRO_API_SECRET in .env file.");
      return null;
    }

    // ✅ Build authorization header
    final credentials = base64Encode(utf8.encode("$appId:$appSecret"));
    final headers = {
      "Authorization": "Basic $credentials",
      "Content-Type": "application/json",
    };

    final dateStr = date.toIso8601String().split('T')[0];
    final url = Uri.parse(
      "$baseUrl/bodies/positions"
          "?latitude=${Uri.encodeQueryComponent(latitude.toString())}"
          "&longitude=${Uri.encodeQueryComponent(longitude.toString())}"
          "&elevation=0"
          "&from_date=$dateStr"
          "&to_date=$dateStr"
          "&time=00:00:00",
    );

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode != 200) {
        print("❌ AstronomyAPI Error [${response.statusCode}]: ${response.body}");
        return null;
      }

      final body = jsonDecode(response.body);
      final rows = (body['data']?['table']?['rows'] as List?) ?? [];

      // Helper to locate specific celestial body data.
      Map<String, dynamic>? findBody(String name) {
        for (final r in rows) {
          final entry = r['entry'];
          if (entry is Map && entry['name'] == name) {
            final cells = r['cells'] as List?;
            if (cells != null && cells.isNotEmpty) {
              return cells.first['position'] as Map<String, dynamic>?;
            }
          }
        }
        return null;
      }

      final moonPos = findBody('Moon');
      final sunPos = findBody('Sun');

      // ✅ Extract moon phase and illumination safely
      final phase = (moonPos?['phase'] as Map?) ?? {};
      final phaseName = (phase['name'] as String?)?.trim().isNotEmpty == true
          ? phase['name'] as String
          : "Unknown";
      final illumRaw = phase['illumination'];
      final moonIllum = illumRaw is num ? illumRaw.toDouble() : 0.0;
      final moonIcon = _getMoonIcon(phaseName);

      // ✅ Placeholder sunrise/sunset (this endpoint rarely returns them)
      final sunRise = (sunPos?['rise'] ?? sunPos?['hdate'])?.toString() ?? "—";
      final sunSet = (sunPos?['set'] ?? sunPos?['hdate'])?.toString() ?? "—";

      return AstroData(
        moonPhaseName: phaseName,
        moonIllumination: moonIllum,
        moonPhaseIcon: moonIcon,
        sunRise: sunRise,
        sunSet: sunSet,
      );
    } catch (e) {
      print("❌ Exception fetching astro data: $e");
      return null;
    }
  }

  /// 🔮 Converts a phase name into a moon emoji for display.
  String _getMoonIcon(String phaseName) {
    final p = phaseName.toLowerCase();
    if (p.contains("new")) return "🌑";
    if (p.contains("waxing crescent")) return "🌒";
    if (p.contains("first quarter")) return "🌓";
    if (p.contains("waxing gibbous")) return "🌔";
    if (p.contains("full")) return "🌕";
    if (p.contains("waning gibbous")) return "🌖";
    if (p.contains("last quarter")) return "🌗";
    if (p.contains("waning crescent")) return "🌘";
    return "🌙";
  }

  /// ♈ Gets the zodiac sign for a given Date of Birth or date.
  static String getZodiacSign(DateTime dob) {
    final m = dob.month, d = dob.day;
    if ((m == 3 && d >= 21) || (m == 4 && d <= 19)) return 'Aries';
    if ((m == 4 && d >= 20) || (m == 5 && d <= 20)) return 'Taurus';
    if ((m == 5 && d >= 21) || (m == 6 && d <= 20)) return 'Gemini';
    if ((m == 6 && d >= 21) || (m == 7 && d <= 22)) return 'Cancer';
    if ((m == 7 && d >= 23) || (m == 8 && d <= 22)) return 'Leo';
    if ((m == 8 && d >= 23) || (m == 9 && d <= 22)) return 'Virgo';
    if ((m == 9 && d >= 23) || (m == 10 && d <= 22)) return 'Libra';
    if ((m == 10 && d >= 23) || (m == 11 && d <= 21)) return 'Scorpio';
    if ((m == 11 && d >= 22) || (m == 12 && d <= 21)) return 'Sagittarius';
    if ((m == 12 && d >= 22) || (m == 1 && d <= 19)) return 'Capricorn';
    if ((m == 1 && d >= 20) || (m == 2 && d <= 18)) return 'Aquarius';
    return 'Pisces';
  }
}
