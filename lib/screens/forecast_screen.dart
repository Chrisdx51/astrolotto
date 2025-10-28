import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _aiResult = '';
  String _moonPhase = '';
  String _zodiacSign = '';
  List<String> _luckyDays = [];
  DateTime? _birthDate;

  late AnimationController _rotationController;
  late Timer _messageTimer;
  String _statusText = "🌙 Aligning your energy with the cosmos...";

  final List<String> _spiritualMessages = [
    "🌌 The stars are whispering your fortune...",
    "💫 Aligning your aura with cosmic frequencies...",
    "🌙 Drawing wisdom from moonlight and mystery...",
    "✨ Gathering celestial energy for your forecast...",
    "🔮 The universe is tuning your spiritual path..."
  ];

  @override
  void initState() {
    super.initState();
    _rotationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _startMessageRotation();
    _generateForecast();
  }

  void _startMessageRotation() {
    int index = 0;
    _messageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _statusText = _spiritualMessages[index % _spiritualMessages.length];
        index++;
      });
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _messageTimer.cancel();
    super.dispose();
  }

  Future<void> _generateForecast() async {
    setState(() => _loading = true);

    final now = DateTime.now();
    final moonPhases = [
      'New Moon',
      'Waxing Crescent',
      'First Quarter',
      'Waxing Gibbous',
      'Full Moon',
      'Waning Gibbous',
      'Last Quarter',
      'Waning Crescent'
    ];
    _moonPhase = moonPhases[now.day % moonPhases.length];

    final month = _birthDate?.month ?? now.month;
    final day = _birthDate?.day ?? now.day;
    _zodiacSign = _getZodiac(month, day);

    // 🌠 Step 3: Generate 3 random lucky days within the next 7 days
    final random = Random();
    final Set<int> chosenOffsets = {}; // ensures no duplicate days
    while (chosenOffsets.length < 3) {
      chosenOffsets.add(random.nextInt(7) + 1); // random day 1–7 ahead
    }

    _luckyDays = chosenOffsets.map((offset) {
      final date = now.add(Duration(days: offset));
      return DateFormat('EEEE, MMM d').format(date);
    }).toList()
      ..sort((a, b) => DateFormat('EEEE, MMM d').parse(a)
          .compareTo(DateFormat('EEEE, MMM d').parse(b)));


    final uri = Uri.parse('https://auranaguidance.co.uk/api/forecast');
    final promptText =
        "Create a detailed but calming daily cosmic forecast for zodiac $_zodiacSign under the $_moonPhase moon. "
        "Focus on emotional balance, luck, and spiritual alignment in 2 short paragraphs. End with a guiding affirmation.";

    print('🔭 [CosmosAI] Sending request to: $uri');
    print('🧠 [CosmosAI] Prompt: $promptText');

    try {
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({"prompt": promptText});

      print('🔭 [CosmosAI] STREAMING → $uri');

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode != 200) {
        throw Exception("HTTP ${streamedResponse.statusCode}");
      }

      final buffer = <int>[];

      streamedResponse.stream.listen((chunk) {
        buffer.addAll(chunk);
        final text = utf8.decode(buffer, allowMalformed: true);

        if (!mounted) return;
        setState(() {
          _aiResult = text.trim();
        });

      }, onDone: () {
        if (!mounted) return;
        setState(() => _loading = false);
        print('✅ [CosmosAI] Streaming response finished.');
      }, onError: (e) {
        _fallbackForecast();
      });
    } catch (_) {
      _fallbackForecast();
    }
  }

  void _fallbackForecast() {
    if (!mounted) return;
    setState(() {
      _aiResult =
      "💫 The Cosmos AI connection seems to be momentarily lost.\n\nYet the $_moonPhase moon still guides your intuition — trust what you feel.";
      _loading = false;
    });
  }


  String _getZodiac(int month, int day) {
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Aries ♈';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Taurus ♉';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Gemini ♊';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Cancer ♋';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leo ♌';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Virgo ♍';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Libra ♎';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Scorpio ♏';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Sagittarius ♐';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'Capricorn ♑';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Aquarius ♒';
    return 'Pisces ♓';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentZodiac = _getZodiac(now.month, now.day);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1430),
        title: Text(
          "🌙 Cosmic Forecast",
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? _buildSpiritualLoader()
          : _buildForecastContent(currentZodiac),
    );
  }

  Widget _buildSpiritualLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _rotationController,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    Colors.tealAccent,
                    Colors.blueAccent,
                    Colors.purpleAccent,
                    Colors.tealAccent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.tealAccent.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 3,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _statusText,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastContent(String currentZodiac) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Image.asset(
            'assets/images/logolot.png',
            height: 90,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151A2D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            "Welcome to your Cosmic Forecast 🌌\n\n"
                "Here, the Cosmos AI reads the stars to reveal your energy flow for today. "
                "Your moon phase and zodiac alignment guide your message — helping you stay aligned with universal rhythm.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 25),
        Center(
          child: Column(
            children: [
              Text(
                "Zodiac Cycle",
                style: GoogleFonts.orbitron(
                  color: Colors.amberAccent,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _birthDate != null ? _zodiacSign : "$currentZodiac (This Month)",
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: Column(
            children: [
              Text(
                "Current Moon Phase",
                style: GoogleFonts.orbitron(
                  color: Colors.amberAccent,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _moonPhase,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Text(
          "✨ Lucky Cosmic Days ✨",
          textAlign: TextAlign.center,
          style: GoogleFonts.orbitron(
            fontSize: 18,
            color: Colors.amberAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 15),
        ..._luckyDays.map(
              (day) => Card(
            color: const Color(0xFF10162C),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(
                day,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                "High alignment energy detected ✨",
                style: TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF151A2D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            _aiResult,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
