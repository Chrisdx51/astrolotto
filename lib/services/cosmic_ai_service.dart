import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class CosmicAIService {
  static const String _baseUrl = 'https://auranaguidance.co.uk/api';

  // simple in-memory cache so results persist if user navigates away
  static final Map<String, String> _cache = {};

  static Future<String> _callAI(
      String endpoint,
      Map<String, dynamic> payload, {
        BuildContext? context,
        String room = 'default',
      }) async {
    final cacheKey = '$endpoint-${payload.toString()}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      if (context != null) _showCosmicOverlay(context, room);

      final uri = Uri.parse('$_baseUrl/$endpoint');
      debugPrint('🔭 POST $uri');
      debugPrint('🧠 Payload: $payload');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (context != null) _hideCosmicOverlay();

      debugPrint('🌌 Response: ${response.statusCode} | ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final msg = decoded['message'] ?? '✨ The cosmos whispers guidance for you.';
        _cache[cacheKey] = msg; // store it so it persists
        return msg;
      } else {
        return '🌌 The stars are quiet... (error ${response.statusCode})';
      }
    } catch (err) {
      debugPrint('❌ Error: $err');
      if (context != null) _hideCosmicOverlay();
      return '🔮 Connection lost in the starlight.';
    }
  }

  // 🔮 Individual AI features
  static Future<String> getForecast({
    required String name,
    required String zodiac,
    required String moonPhase,
    BuildContext? context,
  }) async {
    return await _callAI(
      'forecast',
      {'prompt': 'Forecast for $name, zodiac $zodiac, moon phase $moonPhase'},
      context: context,
      room: 'forecast',
    );
  }

  static Future<String> getCrystalInsight(
      String zodiac, String crystal, {BuildContext? context}) async {
    return await _callAI(
      'crystal',
      {'prompt': 'Crystal insight for $zodiac using $crystal'},
      context: context,
      room: 'crystal',
    );
  }

  static Future<String> getDreamNumbers(String dream,
      {BuildContext? context}) async {
    return await _callAI(
      'dreamnumbers',
      {'prompt': dream},
      context: context,
      room: 'dream',
    );
  }

  static Future<String> getManifestationInsight(String intention,
      {BuildContext? context}) async {
    return await _callAI(
      'manifest',
      {'prompt': intention},
      context: context,
      room: 'manifest',
    );
  }

  static Future<String> getMeditationGuidance(String zodiac,
      {BuildContext? context}) async {
    return await _callAI(
      'meditate',
      {'prompt': 'Meditation guidance for $zodiac'},
      context: context,
      room: 'meditate',
    );
  }

  static Future<String> getLuckReport(String zodiac, DateTime date,
      {BuildContext? context}) async {
    return await _callAI(
      'lucktracker',
      {'prompt': 'Luck report for $zodiac on ${date.toIso8601String()}'},
      context: context,
      room: 'luck',
    );
  }

  static Future<List<int>> getVIPNumbers(String name, String zodiac,
      {BuildContext? context}) async {
    final result = await _callAI(
      'vip-generator',
      {'prompt': '$name $zodiac VIP cosmic numbers'},
      context: context,
      room: 'vip',
    );

    final nums = RegExp(r'\d+')
        .allMatches(result)
        .map((m) => int.parse(m.group(0)!))
        .toList();

    return nums.isNotEmpty ? nums : _generateFallbackNumbers();
  }

  static Future<String> getAffirmation(String zodiac,
      {BuildContext? context}) async {
    return await _callAI(
      'adfreemode',
      {'prompt': 'Affirmation for $zodiac'},
      context: context,
      room: 'affirm',
    );
  }

  static Future<String> getLottoFortune(String prompt,
      {BuildContext? context}) async {
    return await _callAI(
      'lottofortune',
      {'prompt': prompt},
      context: context,
      room: 'lotto',
    );
  }

  // Fallback numbers
  static List<int> _generateFallbackNumbers() {
    final random = Random();
    final numbers = <int>{};
    while (numbers.length < 6) {
      numbers.add(random.nextInt(49) + 1);
    }
    return numbers.toList()..sort();
  }

  // 🌙 Slow + realistic loader animation
  static OverlayEntry? _overlayEntry;
  static double _progress = 0;
  static Timer? _timer;

  static void _showCosmicOverlay(BuildContext context, String room) {
    if (_overlayEntry != null) return;
    _progress = 0;
    _overlayEntry = OverlayEntry(builder: (_) => _CosmicOverlay(room: room));
    Overlay.of(context).insert(_overlayEntry!);

    // Slower, smoother progress over ~90 seconds
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_progress < 70) {
        _progress += 0.25;
      } else if (_progress < 90) {
        _progress += 0.15;
      } else if (_progress < 97) {
        _progress += 0.08;
      } else if (_progress < 99) {
        _progress += 0.02;
      }
      _overlayEntry?.markNeedsBuild();
    });
  }

  static void _hideCosmicOverlay() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      _timer?.cancel();
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }
}

// 🌌 Overlay UI Widget
class _CosmicOverlay extends StatefulWidget {
  final String room;
  const _CosmicOverlay({required this.room});

  @override
  State<_CosmicOverlay> createState() => _CosmicOverlayState();
}

class _CosmicOverlayState extends State<_CosmicOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String get _phaseText {
    final msgs = _messagesForRoom(widget.room);
    final index =
    (CosmicAIService._progress ~/ (100 / msgs.length)).clamp(0, msgs.length - 1);
    return msgs[index];
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.93),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: CosmicAIService._progress / 100,
                        strokeWidth: 5,
                        color: const Color(0xFF12D1C0),
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    Text(
                      '${CosmicAIService._progress.toInt()}%',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _phaseText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '⏳ This may take up to 5 minutes depending on your request.',
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _messagesForRoom(String room) {
    switch (room.toLowerCase()) {
      case 'dream':
        return [
          'Opening the dream realm...',
          'Reading subconscious symbols...',
          'Aligning numeric energies...',
          'Decoding astral messages...',
          'Finalizing your dream insight...',
        ];
      case 'manifest':
        return [
          'Charging intention field...',
          'Collecting vibrational intent...',
          'Harmonizing quantum resonance...',
          'Amplifying manifestation energy...',
          'Finalizing your wish matrix...',
        ];
      case 'forecast':
        return [
          'Charting planetary patterns...',
          'Reading solar alignments...',
          'Decoding celestial tides...',
          'Syncing your cosmic timeline...',
          'Preparing your forecast...',
        ];
      case 'meditate':
        return [
          'Centering cosmic breath...',
          'Quieting mind frequencies...',
          'Tuning to starlight stillness...',
          'Opening inner space...',
          'Delivering your meditation focus...',
        ];
      case 'vip':
        return [
          'Summoning elite astral codes...',
          'Aligning high-frequency orbits...',
          'Scanning rare constellations...',
          'Condensing lucky patterns...',
          'Preparing your VIP numbers...',
        ];
      default:
        return [
          'Connecting to Cosmic AI...',
          'Aligning planetary coordinates...',
          'Reading soul vibration...',
          'Preparing your message...',
          'Finalizing universal connection...',
        ];
    }
  }
}
