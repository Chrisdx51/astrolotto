import 'dart:convert';
import 'package:http/http.dart' as http;

/// 🌙 LottoLuck AI Service
/// Connects your Flutter app to your FastAPI backend running at
/// https://auranaguidance.co.uk/lottofortune
///
/// This sends user data (name, zodiac, moon phase) to your AI
/// and returns a fortune message full of luck & positivity ✨
class FortuneAIService {
  static const String baseUrl = "https://auranaguidance.co.uk";

  /// Sends user details to your FastAPI `/lottofortune` endpoint
  static Future<String?> getFortune({
    required String name,
    required String zodiac,
    required String moonPhase,
  }) async {
    final url = Uri.parse("$baseUrl/lottofortune");

    // ✉️ Build the JSON body sent to your FastAPI server
    final body = jsonEncode({
      "prompt":
      "User: $name, Zodiac: $zodiac, Moon Phase: $moonPhase. Write a short, inspiring message that connects luck, destiny, and positivity."
    });

    try {
      // 🌐 Send POST request to your AI endpoint
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      // ✅ Success (HTTP 200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result']?.toString();
        if (result == null || result.isEmpty) {
          print("⚠️ AI responded but no 'result' field found.");
          return "✨ The stars are quiet right now... try again shortly.";
        }
        return result.trim();
      }

      // ❌ Server replied but with an error code
      print("❌ AI fortune error: ${response.statusCode}");
      print("Response body: ${response.body}");
      return "⚠️ Connection established, but the AI didn't respond properly.";

    } catch (e) {
      // 💥 Network or connection failure
      print("❌ AI fortune exception: $e");
      return "🚫 Unable to reach the LottoLuck AI right now. Please check your connection.";
    }
  }
}
