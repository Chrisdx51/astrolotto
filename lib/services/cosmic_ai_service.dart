import 'dart:convert';
import 'package:http/http.dart' as http;

class CosmicAIService {
  static const String _baseUrl = 'https://auranaapp.co.uk/api/forecast'; // 👈 change later if needed

  /// Ask your AI server for a forecast.
  /// If the server isn’t ready yet, this will quietly fall back to local data.
  static Future<Map<String, dynamic>> getForecast({
    required String name,
    required String zodiac,
    required String moonPhase,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'zodiac': zodiac,
          'moonPhase': moonPhase,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'ai_available': false,
          'message':
          'Cosmic channels are quiet today 🌌 (server returned ${response.statusCode}).',
        };
      }
    } catch (_) {
      // fallback – server offline
      return {
        'ai_available': false,
        'message':
        'Your local cosmic intuition suggests rest and reflection today ✨',
      };
    }
  }
}
