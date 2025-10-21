import 'dart:convert';
import 'package:http/http.dart' as http;

class LottoAIService {
  static const String baseUrl = "http://YOUR_SERVER_IP:8600"; // 👈 change this!

  // ⚡ Replace with your VPS IP, for example: "http://123.45.67.89:8600"
  // If you have a domain (like lottoai.auranaapp.co.uk), use that instead.

  static Future<String> fetchFortune(String prompt) async {
    final url = Uri.parse("$baseUrl/lottofortune");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? "✨ The stars are quiet for now...";
      } else {
        return "⚠️ Could not reach the stars right now. Try again soon!";
      }
    } catch (e) {
      return "❌ Connection error: $e";
    }
  }
}
