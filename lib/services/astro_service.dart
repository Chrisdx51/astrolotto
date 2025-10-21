import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AstroData {
  final String moonPhaseName;
  final double moonIllumination;
  final String moonPhaseIcon;
  final String sunRise;
  final String sunSet;

  AstroData({
    required this.moonPhaseName,
    required this.moonIllumination,
    required this.moonPhaseIcon,
    required this.sunRise,
    required this.sunSet,
  });
}

class AstroService {
  final String baseUrl = "https://api.astronomyapi.com/api/v2";

  Future<AstroData?> fetchAstroData({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) async {
    final appId = dotenv.env['ASTRO_API_APP_ID'];
    final appSecret = dotenv.env['ASTRO_API_SECRET'];

    if (appId == null || appSecret == null || appId.isEmpty || appSecret.isEmpty) {
      print("❌ Missing ASTRO_API_APP_ID or ASTRO_API_SECRET in .env");
      return null;
    }

    final credentials = base64Encode(utf8.encode("$appId:$appSecret"));
    final headers = {
      "Authorization": "Basic $credentials",
      "Content-Type": "application/json",
    };

    final dateStr = date.toIso8601String().split('T')[0];

    // NOTE: /bodies/positions may not include phase/sunrise/sunset consistently.
    // We keep this call as-is (since you’re already using it), then extract safely.
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

      // Defensive extracts
      final rows = (body['data']?['table']?['rows'] as List?) ?? const [];
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
      final sunPos  = findBody('Sun');

      // Moon phase (may be missing on this endpoint)
      final phase = (moonPos?['phase'] as Map?) ?? {};
      final phaseName = (phase['name'] as String?)?.trim().isNotEmpty == true
          ? phase['name'] as String
          : "Unknown";
      final illumRaw = phase['illumination'];
      final moonIllum = illumRaw is num ? illumRaw.toDouble() : 0.0;
      final moonIcon = _getMoonIcon(phaseName);

      // Sunrise/sunset are typically not in this response; keep placeholders
      // unless you later switch to the dedicated sunrise/sunset endpoint.
      final sunRise = (sunPos?['rise'] ?? sunPos?['hdate'])?.toString() ?? "—";
      final sunSet  = (sunPos?['set']  ?? sunPos?['hdate'])?.toString() ?? "—";

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
}
