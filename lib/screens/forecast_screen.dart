import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/astro_service.dart'; // optional for real moon data
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../main.dart'; // for BannerAdWidget
import '../services/cosmic_ai_service.dart'; // 👈 AI bridge

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  String _moonPhase = '';
  String _zodiacSign = '';
  List<String> _luckyDays = [];
  String _aiMessage = '';
  DateTime? _birthDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the birth date passed from GeneratorScreen (if any)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is DateTime) {
      _birthDate = args;
    }
    _generateForecast();
  }

  void _generateForecast() {
    final now = DateTime.now();

    // 🌓 Step 1: Get moon phase (simple local mock)
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

    // ♒ Step 2: Determine zodiac from either DOB or today
    final month = _birthDate?.month ?? now.month;
    final day = _birthDate?.day ?? now.day;
    _zodiacSign = _getZodiac(month, day);

    // 🌞 Step 3: Generate 3 “best energy days”
    final days = List.generate(3, (i) {
      final date = now.add(Duration(days: (i + 1) * 2));
      return DateFormat('EEEE, MMM d').format(date);
    });
    _luckyDays = days;

    // 🔮 Step 4: Ask AI for deeper insights
    CosmicAIService.getForecast(
      name: 'User',
      zodiac: _zodiacSign,
      moonPhase: _moonPhase,
    ).then((ai) {
      setState(() {
        _aiMessage = ai['forecast'] ??
            ai['message'] ??
            'The cosmic flow feels calm — trust your intuition today.';
      });
    });

    setState(() {});
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
        centerTitle: true,
        title: const Text("🌙 Cosmic Forecast"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const BannerAdWidget(isTop: true),
          const SizedBox(height: 20),

          // 🪐 Zodiac
          Center(
            child: Column(
              children: [
                Text(
                  _birthDate != null
                      ? "Your Zodiac Sign"
                      : "Current Zodiac Cycle",
                  style: GoogleFonts.orbitron(
                    color: Colors.amberAccent,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _birthDate != null
                      ? _zodiacSign
                      : "$currentZodiac (Current Month)",
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

          // 🌕 Moon Phase
          Center(
            child: Column(
              children: [
                Text(
                  "Current Moon Phase",
                  style: GoogleFonts.orbitron(
                    color: Colors.amberAccent,
                    fontSize: 14,
                    letterSpacing: 1,
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

          // ✨ Lucky Days
          Text(
            "✨ Your Lucky Cosmic Days ✨",
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
                trailing:
                const Icon(Icons.auto_awesome, color: Colors.amberAccent),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 🧠 AI Message
          if (_aiMessage.isNotEmpty)
            Card(
              color: const Color(0xFF151A2D),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _aiMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 40),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
