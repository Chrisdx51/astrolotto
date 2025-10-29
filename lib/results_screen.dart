import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart';
//import 'package:audioplayers/audioplayers.dart';
import 'main.dart';

const _cTurquoise = Color(0xFF12D1C0);
const _cMagenta = Color(0xFFFF4D9A);
const _cSunshine = Color(0xFFFFD166);
const _cDeepBlue = Color(0xFF0A003D);

class ResultScreen extends StatefulWidget {
  final String lottery;
  final List<int> mainNumbers;
  final List<int> bonusNumbers;
  final String name;
  final String country;
  final String zodiac;
  final String moonPhase;

  const ResultScreen({
    super.key,
    required this.lottery,
    required this.mainNumbers,
    required this.bonusNumbers,
    required this.name,
    required this.country,
    required this.zodiac,
    required this.moonPhase,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  // ── original animation + state ──────────────────────────────────────────────
  late final AnimationController _anim;
  late final Animation<double> _pulse;
  late final AnimationController _bgAnim;
  late final Animation<double> _bgMove;
  late final List<AnimationController> _ballAnims;
  late final AnimationController _starsAnim;
  late final AnimationController _infoCardAnim;
  late final Animation<double> _infoCardScale;
  final List<Offset> _stars = [];
  final Random _rng = Random();

  late final ConfettiController _confettiController;
  //final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isSaving = false;
  String? _quote;
  String? _horoscope;
  final Set<int> _usedQuotes = {};

  late final AnimationController _fadeQuote;
  late final AnimationController _fadeHoroscope;


  // Breathing moon
  late final AnimationController _moonGlow; // 0..1 repeating
  late final Animation<double> _moonValue;
  String _liveMoonPhase = ""; // computed locally


  @override
  void initState() {
    super.initState();
    _fetchHoroscope();
    _pickRandomQuote();

    // Live moon phase name (local calc)
    _liveMoonPhase = _computeMoonPhaseName(DateTime.now());



    // Original animations
    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _bgMove = CurvedAnimation(parent: _bgAnim, curve: Curves.easeInOut);

    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOutSine));

    _fadeQuote = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeHoroscope = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _starsAnim = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _infoCardAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _infoCardScale = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _infoCardAnim, curve: Curves.easeOut));

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _generateStars();

    // Breathing moon (soft glow)
    _moonGlow = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _moonValue = CurvedAnimation(parent: _moonGlow, curve: Curves.easeInOut);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _confettiController.play();
      _playCelebrateSound();
      _infoCardAnim.forward();
    });

    final totalBalls = widget.mainNumbers.length + widget.bonusNumbers.length;
    _ballAnims = List.generate(totalBalls, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 500)));

    for (int i = 0; i < totalBalls; i++) {
      Future.delayed(Duration(milliseconds: 250 * i), () {
        if (mounted) _ballAnims[i].forward();
      });
    }

    Future.delayed(const Duration(seconds: 1), () => _fadeQuote.forward());
    Future.delayed(const Duration(seconds: 2), () => _fadeHoroscope.forward());

  }

  @override
  void dispose() {
    _anim.dispose();
    _bgAnim.dispose();
    _fadeQuote.dispose();
    _fadeHoroscope.dispose();
    _starsAnim.dispose();
    _infoCardAnim.dispose();
    _confettiController.dispose();
    //_audioPlayer.stop();
    //_audioPlayer.dispose();
    _moonGlow.dispose();
    for (var c in _ballAnims) {
      c.dispose();
    }
    super.dispose();
  }

  // ── original helpers ────────────────────────────────────────────────────────
  void _generateStars() {
    _stars.clear();
    for (int i = 0; i < 50; i++) {
      _stars.add(Offset(_rng.nextDouble() * 400, _rng.nextDouble() * 800));
    }
  }

  Future<void> _playCelebrateSound() async {
    try {
      //await _audioPlayer.play(AssetSource('sounds/celebrate.mp3'));
    } catch (e) {
      debugPrint('⚠️ Sound error: $e');
    }
  }

  Future<void> _fetchHoroscope() async {
    try {
      final sign = widget.zodiac.toLowerCase().trim();
      final url = Uri.parse("https://ohmanda.com/api/horoscope/$sign");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _horoscope = data['horoscope']);
      } else {
        setState(() => _horoscope = "✨ The stars are whispering softly today — stay open to signs.");
      }
    } catch (_) {
      setState(() => _horoscope = "🌙 The cosmic winds are quiet... check again later for your message.");
    }
  }

  final List<String> _quotes = [
    "The stars are smiling at you, NAME — fortune dances in your favor 🌟",
    "Luck flows where your faith glows, NAME ✨",
    "Fortune follows your fearless heart, NAME 💖",
    "NAME, your destiny expands as you do 🌌",
    "Luck doesn’t chase you — it orbits you, NAME 🪐",
    "Your courage is your superpower, NAME 💪",
    "NAME, your kindness calls blessings 🌸",
    "The moon favors your heart’s wishes, NAME 🌕",
    "NAME, fortune’s flame burns bright within you 🔥",
    "The cosmos celebrates your courage, NAME 🌟"
  ];

  void _pickRandomQuote() {
    if (_usedQuotes.length == _quotes.length) _usedQuotes.clear();
    int i;
    do {
      i = Random().nextInt(_quotes.length);
    } while (_usedQuotes.contains(i));
    _usedQuotes.add(i);
    _quote = _quotes[i].replaceAll("NAME", widget.name);
  }

  Future<void> _saveNumbers() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();

    final entry = {
      'lottery': widget.lottery,
      'mainNumbers': widget.mainNumbers,
      'bonusNumbers': widget.bonusNumbers,
      'name': widget.name,
      'country': widget.country,
      'zodiac': widget.zodiac,
      'moonPhase': widget.moonPhase,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final existing = prefs.getStringList('saved_draws') ?? [];
    existing.add(jsonEncode(entry));
    await prefs.setStringList('saved_draws', existing);
    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "✨ Numbers saved successfully!",
          style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14),
        ),
        backgroundColor: _cMagenta.withOpacity(0.8),
      ),
    );
  }

  void _shareNumbers() {
    final nums = widget.mainNumbers.join(', ');
    final bonus = widget.bonusNumbers.isNotEmpty ? " Bonus: ${widget.bonusNumbers.join(', ')}" : "";
    final text = '''
🔮 ${widget.name}'s ${widget.lottery} Lucky Numbers 🔮

Main: $nums$bonus

Zodiac: ${widget.zodiac}
Moon: ${_liveMoonPhase.isNotEmpty ? _liveMoonPhase : widget.moonPhase}
Country: ${widget.country}

✨ Generated by Astro Lotto Luck ✨
''';
    Share.share(text, subject: 'My Astro Lucky Numbers 🌠');
  }



  // ── NEW: fetch AI with caching + rotating phrases + progress bar


  // ── NEW: local moon phase calculation (simple + fast)
  String _computeMoonPhaseName(DateTime date) {
    const synodic = 29.53058867; // days
    final ref = DateTime.utc(2000, 1, 6, 18, 14);
    final days = date.toUtc().difference(ref).inSeconds / 86400.0;
    final phase = (days % synodic) / synodic; // 0..1
    if (phase < 0.03 || phase > 0.97) return "New Moon";
    if (phase < 0.22) return "Waxing Crescent";
    if (phase < 0.28) return "First Quarter";
    if (phase < 0.47) return "Waxing Gibbous";
    if (phase < 0.53) return "Full Moon";
    if (phase < 0.72) return "Waning Gibbous";
    if (phase < 0.78) return "Last Quarter";
    return "Waning Crescent";
  }

  @override
  Widget build(BuildContext context) {
    final allNumbers = [
      ...widget.mainNumbers.map((n) => {'n': n, 'bonus': false}),
      ...widget.bonusNumbers.map((n) => {'n': n, 'bonus': true}),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated gradient background
            AnimatedBuilder(
              animation: _bgAnim,
              builder: (context, _) {
                final colors = [
                  Color.lerp(_cDeepBlue, _cMagenta, _bgMove.value)!,
                  Color.lerp(_cMagenta, _cTurquoise, 0.6 * _bgMove.value)!,
                  Color.lerp(_cTurquoise, _cSunshine, 0.8 * (1 - _bgMove.value))!,
                ];
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),

            // Stars
            AnimatedBuilder(
              animation: _starsAnim,
              builder: (context, _) => CustomPaint(
                size: Size.infinite,
                painter: StarPainter(_stars, _starsAnim.value),
              ),
            ),

            // Confetti
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 25,
              colors: const [_cTurquoise, _cMagenta, _cSunshine, Colors.white],
            ),

            // Main content
            Column(
              children: [
                const BannerAdWidget(isTop: true),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/logolot.png', width: 220),
                        const SizedBox(height: 10),

                        // 🌕 NEW: Moon "breathing" animation box
                        _moonBox(),
                        const SizedBox(height: 10),

                        ScaleTransition(
                          scale: _pulse,
                          child: Text(
                            "${widget.lottery} Results",
                            style: GoogleFonts.orbitron(
                              color: _cSunshine,
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(color: _cSunshine.withOpacity(0.6), blurRadius: 10),
                                Shadow(color: _cMagenta.withOpacity(0.4), blurRadius: 5),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ScaleTransition(scale: _infoCardScale, child: _infoCard()),
                        const SizedBox(height: 25),
                        Text(
                          "✨ Your Astro Lucky Numbers ✨",
                          style: GoogleFonts.orbitron(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            shadows: [Shadow(color: _cSunshine.withOpacity(0.5), blurRadius: 8)],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Balls
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 14,
                          children: List.generate(allNumbers.length, (i) {
                            final item = allNumbers[i];
                            return FadeTransition(
                              opacity: CurvedAnimation(parent: _ballAnims[i], curve: Curves.easeIn),
                              child: ScaleTransition(
                                scale: _pulse,
                                child: _buildBall(item['n'] as int, isBonus: item['bonus'] as bool),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 28),

                        // 🔮 AI box (progress → message)
                        FadeTransition(opacity: _fadeQuote, child: _magicBox()),

                        const SizedBox(height: 20),
                        FadeTransition(opacity: _fadeHoroscope, child: _horoscopeBox()),
                        const SizedBox(height: 30),
                        _buttons(),
                        const SizedBox(height: 40),

                        // Disclaimer
                        Opacity(
                          opacity: 0.8,
                          child: Text(
                            "🔞 18+ • Entertainment Only • This app does not offer or promote gambling.\nNumbers generated are for fun, inspiration & spiritual entertainment.\nThere is no guarantee of winnings — please enjoy responsibly 💫",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.orbitron(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.5,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const BannerAdWidget(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🌕 Breathing moon box (simple glow)
  Widget _moonBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cSunshine.withOpacity(0.5), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _moonValue,
            builder: (context, _) {
              final glow = 0.35 + 0.45 * _moonValue.value; // 0.35..0.8
              return Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(glow),
                      Colors.white.withOpacity(glow * 0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _cSunshine.withOpacity(glow * 0.8),
                      blurRadius: 18 + 10 * _moonValue.value,
                      spreadRadius: 2 + 2 * _moonValue.value,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              "Live Moon Phase: ${_liveMoonPhase.isEmpty ? widget.moonPhase : _liveMoonPhase}",
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [_cTurquoise.withOpacity(0.3), _cMagenta.withOpacity(0.3)]),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _cSunshine.withOpacity(0.5), width: 1.2),
      boxShadow: [
        BoxShadow(color: _cSunshine.withOpacity(0.3), blurRadius: 10, spreadRadius: 2),
        BoxShadow(color: _cMagenta.withOpacity(0.2), blurRadius: 5, spreadRadius: 1),
      ],
    ),
    child: Text(
      "🔮 ${widget.name}, your lucky numbers were crafted from the cosmic alignment of your ${widget.zodiac} zodiac, ${widget.moonPhase} moon phase, and celestial plane in ${widget.country}. 🌕",
      textAlign: TextAlign.center,
      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
    ),
  );

  Widget _buildBall(int num, {bool isBonus = false}) {
    final colors = isBonus ? [_cMagenta, Colors.purpleAccent] : [_cSunshine, _cTurquoise];
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(color: colors.first.withOpacity(0.6), blurRadius: 12, spreadRadius: 3),
          BoxShadow(color: colors.last.withOpacity(0.4), blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: Text(
        num.toString(),
        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _magicBox() => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _cSunshine.withOpacity(0.5), width: 1.2),
    ),
    child: Column(
      children: [
        Text(
          _quote ?? "✨ The stars are aligning for you...",
          textAlign: TextAlign.center,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _pickRandomQuote()),
            icon: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            label: Text(
              "New Affirmation",
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cMagenta.withOpacity(0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    ),
  );


  Widget _horoscopeBox() => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.05)]),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _cSunshine.withOpacity(0.5), width: 1.2),
    ),
    child: Text(
      _horoscope ?? "🌙 Fetching your star reading...",
      textAlign: TextAlign.center,
      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
    ),
  );

  Widget _buttons() => Column(
    children: [
      // 👇 Wrap prevents horizontal overflow on small screens
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveNumbers,
            icon: _isSaving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : const Icon(Icons.bookmark, color: Colors.white),
            label: Text(
              _isSaving ? "Saving..." : "Save Numbers",
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cTurquoise.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _shareNumbers,
            icon: const Icon(Icons.share, color: Colors.white),
            label: Text(
              "Share Numbers",
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cMagenta.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        label: Text(
          "Back to Generator",
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purpleAccent.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    ],
  );
}

// Painters
class StarPainter extends CustomPainter {
  final List<Offset> stars;
  final double value;
  StarPainter(this.stars, this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var s in stars) {
      final twinkle = (sin(value * pi * 4 + s.dx) + 1) / 2;
      paint.color = Colors.white.withOpacity(0.3 + twinkle * 0.5);
      canvas.drawCircle(s, 2 + twinkle * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
