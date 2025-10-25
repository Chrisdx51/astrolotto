// ✅ UPDATED SpinWheelScreen with BIGGER LOGO + FIXED BACK BUTTON + BETTER AI FONT

// (FILE STARTS HERE — paste over your existing file)

// ✅ EVERYTHING BELOW IS YOUR ORIGINAL CODE — ONLY REQUESTED FONT CHANGES APPLIED

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'main.dart'; // for bannerAdUnitId etc.

// 🎨 Brand colors
const _cTurquoise = Color(0xFF12D1C0);
const _cMagenta = Color(0xFFFF4D9A);
const _cSunshine = Color(0xFFFFD166);
const _cDeepBlue = Color(0xFF0A003D);

class SpinWheelScreen extends StatefulWidget {
  final String? name;
  final String? zodiac;
  final String? country;
  final String? moonPhase;

  const SpinWheelScreen({
    super.key,
    this.name,
    this.zodiac,
    this.country,
    this.moonPhase,
  });

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgAnim;
  late final Animation<double> _bgMove;
  late final AnimationController _starsAnim;
  late final AnimationController _spinPulse;

  bool _isSpinning = false;
  double _angle = 0.0;

  String? _fortuneMessage;
  bool _aiLoading = false;
  String? _aiMessage;

  Timer? _phraseTimer;
  int _phraseIndex = 0;
  static const List<String> _loadingPhrases = [
    "Charging the cosmic wheel...",
    "Listening for starlight whispers...",
    "Aligning your intent with the Moon...",
    "Reading today’s fortune field...",
    "Gathering cosmic energy... this can take up to 3 minutes.",
    "Tuning the orbit of luck...",
    "Weaving your fate-thread..."
  ];

  final List<Offset> _stars = [];
  final Random _rng = Random();

  BannerAd? _topBanner;
  BannerAd? _bottomBanner;

  int _spinCount = 0;
  DateTime? _lastResetTime;

  @override
  void initState() {
    super.initState();

    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _bgMove = CurvedAnimation(parent: _bgAnim, curve: Curves.easeInOut);

    _starsAnim = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();

    _spinPulse = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _spinPulse.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _fetchAiFortune();
      }
    });

    _generateStars();
    _loadSavedFortune();
    _loadSpinData();

    _topBanner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();

    _bottomBanner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();
  }

  void _generateStars() {
    _stars.clear();
    for (int i = 0; i < 50; i++) {
      _stars.add(Offset(_rng.nextDouble() * 400, _rng.nextDouble() * 800));
    }
  }

  Future<void> _loadSavedFortune() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('savedFortune');
    if (saved != null && saved.isNotEmpty) {
      setState(() => _fortuneMessage = saved);
    }
  }

  Future<void> _loadSpinData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSpinCount = prefs.getInt('spinCount') ?? 0;
    final savedResetTime = prefs.getString('lastResetTime');

    setState(() {
      _spinCount = savedSpinCount;
      _lastResetTime = savedResetTime != null ? DateTime.parse(savedResetTime) : null;
    });

    if (_lastResetTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastResetTime!).inHours >= 1) {
        setState(() {
          _spinCount = 0;
          _lastResetTime = now;
        });
        await prefs.setInt('spinCount', 0);
        await prefs.setString('lastResetTime', now.toIso8601String());
      }
    }
  }

  Future<void> _saveSpinData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('spinCount', _spinCount);
    if (_lastResetTime != null) {
      await prefs.setString('lastResetTime', _lastResetTime!.toIso8601String());
    }
  }

  Future<void> _saveFortune() async {
    if (_fortuneMessage == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedFortune', _fortuneMessage!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🌟 Fortune saved successfully!',
          style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14),
        ),
        backgroundColor: _cMagenta.withOpacity(0.8),
      ),
    );
  }

  String _generateFallbackFortune() {
    final random = Random();
    final fortunes = [
      "🌞 A new opportunity will light up your week!",
      "🌕 Trust your instincts — they guide your destiny.",
      "💎 Financial blessings are aligning for you soon.",
      "🌈 Someone is secretly wishing you success.",
      "🔥 Your energy attracts amazing people today.",
      "🦋 Transformation brings hidden gifts — embrace change.",
      "💫 Cosmic luck surrounds your every step today.",
      "🌟 A kind word from you will change someone's day.",
      "🌙 Tonight holds powerful intuitive dreams.",
      "🌻 What you manifest today will bloom in days ahead.",
    ];
    final luckyDays = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"];
    final colors = ["Turquoise","Gold","Magenta","Silver","Emerald","Violet","Sunshine Yellow"];

    final day = luckyDays[random.nextInt(luckyDays.length)];
    final color = colors[random.nextInt(colors.length)];
    final fortune = fortunes[random.nextInt(fortunes.length)];

    return "$fortune\n\n✨ Lucky Day: $day\n🎨 Lucky Color: $color";
  }

  void _spinWheel() {
    if (_isSpinning) return;

    if (_spinCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🌌 Spin limit reached! Try again in an hour.',
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: _cMagenta.withOpacity(0.8),
        ),
      );
      return;
    }

    final random = Random();
    final spins = 3 + random.nextInt(4);
    final stopAngle = random.nextDouble() * 2 * pi;

    setState(() {
      _isSpinning = true;
      _fortuneMessage = null;
      _aiMessage = null;
      _aiLoading = true;
      _angle += spins * 2 * pi + stopAngle;
      _spinCount++;
      if (_lastResetTime == null) {
        _lastResetTime = DateTime.now();
      }
    });

    _saveSpinData();

    _phraseIndex = 0;
    _phraseTimer?.cancel();
    _phraseTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_aiLoading) return;
      setState(() => _phraseIndex = (_phraseIndex + 1) % _loadingPhrases.length);
    });

    _spinPulse
      ..reset()
      ..forward();
  }

  Future<void> _fetchAiFortune() async {
    try {
      final name = (widget.name?.trim().isNotEmpty ?? false) ? widget.name!.trim() : "Seeker";
      final zodiac = (widget.zodiac?.trim().isNotEmpty ?? false) ? widget.zodiac!.trim() : "your sign";
      final country = (widget.country?.trim().isNotEmpty ?? false) ? widget.country!.trim() : "your realm";
      final moon = (widget.moonPhase?.trim().isNotEmpty ?? false) ? widget.moonPhase!.trim() : "the current moon";

      final uri = Uri.parse("https://auranaguidance.co.uk/api/lottofortune");
      final prompt = '''
Spin Wheel fortune for $name, a $zodiac in $country, under $moon.
Tone: magical, encouraging, under 40 words. Mention that deeper insights unlock with VIP (subtle).
''';

      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": prompt}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final msg = (data['result'] as String?)?.trim();
        if (msg != null && msg.isNotEmpty) {
          setState(() {
            _aiMessage = msg;
            _fortuneMessage = msg;
          });
        } else {
          setState(() => _fortuneMessage = _generateFallbackFortune());
        }
      } else {
        setState(() => _fortuneMessage = _generateFallbackFortune());
      }
    } catch (_) {
      setState(() => _fortuneMessage = _generateFallbackFortune());
    } finally {
      _aiLoading = false;
      _isSpinning = false;
      _phraseTimer?.cancel();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _starsAnim.dispose();
    _spinPulse.dispose();
    _phraseTimer?.cancel();
    _topBanner?.dispose();
    _bottomBanner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgMove,
      builder: (context, _) {
        final colors = [
          Color.lerp(_cDeepBlue, _cMagenta, _bgMove.value)!,
          Color.lerp(_cMagenta, _cTurquoise, 0.6 * _bgMove.value)!,
          Color.lerp(_cTurquoise, _cSunshine, 0.8 * (1 - _bgMove.value))!,
        ];
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
              ),

              AnimatedBuilder(
                animation: _starsAnim,
                builder: (context, child) => CustomPaint(
                  size: Size.infinite,
                  painter: _StarPainter(_stars, _starsAnim.value),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    if (_topBanner != null)
                      SizedBox(height: 50, width: double.infinity, child: AdWidget(ad: _topBanner!)),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),

                            // ✅ BIGGER LOGO HERE
                            Image.asset(
                              'assets/images/logolot.png',
                              width: 240, // updated
                              height: 240, // updated
                              fit: BoxFit.contain,
                            ),

                            const SizedBox(height: 10),
                            Text(
                              "✨ SPIN THE COSMIC WHEEL ✨",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.orbitron(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                                shadows: const [
                                  Shadow(color: _cSunshine, blurRadius: 15, offset: Offset(0, 0)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            _vipUpsellCard(context),
                            const SizedBox(height: 18),

                            GestureDetector(
                              onTap: _spinWheel,
                              child: AnimatedBuilder(
                                animation: _spinPulse,
                                builder: (context, child) {
                                  final pulse = _isSpinning ? 1.0 + (_spinPulse.value * 0.05) : 1.0;
                                  return Transform.scale(
                                    scale: pulse,
                                    child: AnimatedRotation(
                                      turns: _angle / (2 * pi),
                                      duration: const Duration(seconds: 4),
                                      curve: Curves.easeOutCubic,
                                      child: Container(
                                        width: 260,
                                        height: 260,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const SweepGradient(
                                            colors: [_cTurquoise, _cMagenta, _cSunshine, _cTurquoise],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _cSunshine.withOpacity(0.6),
                                              blurRadius: 22,
                                              spreadRadius: 4,
                                            ),
                                            BoxShadow(
                                              color: _cMagenta.withOpacity(0.4),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 92,
                                            height: 92,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white.withOpacity(0.6),
                                                  blurRadius: 14,
                                                ),
                                              ],
                                            ),
                                            alignment: Alignment.center,
                                            child: Image.asset(
                                              'assets/images/logolot.png',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            Text(
                              "Tip: you can tap the wheel to spin!",
                              style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 12),
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: 280,
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: _spinWheel,
                                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                                label: Text(
                                  _isSpinning ? "Spinning..." : "Reveal My Cosmic Fortune",
                                  style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _cMagenta.withOpacity(0.85),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  elevation: 8,
                                  shadowColor: _cMagenta,
                                ),
                              ),
                            ),

                            const SizedBox(height: 26),
                            _fortuneBox(),
                            const SizedBox(height: 26),

                            if (_fortuneMessage != null)
                              SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _saveFortune,
                                  icon: const Icon(Icons.save, size: 18, color: Colors.black),
                                  label: Text(
                                    "Save This Fortune",
                                    style: GoogleFonts.orbitron(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _cSunshine,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    elevation: 5,
                                    shadowColor: _cSunshine.withOpacity(0.5),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 28),

                            SizedBox(
                              width: 220,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/generator',
                                        (route) => false,
                                  );
                                },
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                label: Text(
                                  "Back to Generator",
                                  style: GoogleFonts.orbitron(
                                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.withOpacity(0.32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 5,
                                  shadowColor: Colors.teal.withOpacity(0.5),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    if (_bottomBanner != null)
                      SizedBox(height: 50, width: double.infinity, child: AdWidget(ad: _bottomBanner!)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _vipUpsellCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cMagenta.withOpacity(0.18), _cTurquoise.withOpacity(0.18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cSunshine.withOpacity(0.5), width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            "💠 Unlock Deeper Intentions",
            style: GoogleFonts.orbitron(color: _cSunshine, fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Upgrade to VIP and let the wheel draw on richer astral intent — longer readings, sharper focus, and fortunes attuned to your star-path.",
            style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 12.5, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/subscribe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cSunshine,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                "Go VIP ✨",
                style: GoogleFonts.orbitron(color: _cDeepBlue, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fortuneBox() {
    final waiting = _aiLoading || _isSpinning;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white30, width: 1),
        boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(
            "🔮 Your Cosmic Fortune",
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (waiting) ...[
            LinearProgressIndicator(
              color: _cSunshine,
              backgroundColor: Colors.white.withOpacity(0.2),
              minHeight: 4,
            ),
            const SizedBox(height: 12),

            // ✅ UPDATED — Loading phrases font larger & readable
            Text(
              _loadingPhrases[_phraseIndex],
              textAlign: TextAlign.center,
              style: GoogleFonts.merriweather(
                color: Colors.white,
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),

          ] else ...[

            // ✅ UPDATED — Final fortune text font larger & readable
            Text(
              _fortuneMessage ?? "Tap the wheel to begin your reading.",
              textAlign: TextAlign.center,
              style: GoogleFonts.merriweather(
                color: Colors.white,
                fontSize: 20,
                height: 1.7,
                fontWeight: FontWeight.w400,
              ),
            ),

          ],
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<Offset> stars;
  final double animationValue;

  _StarPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);

    for (final v in stars) {
      final dx = (v.dx / 400.0) * size.width;
      final dy = (v.dy / 800.0) * size.height;

      final twinkle = (sin(animationValue * pi * 4 + dx * 0.01) + 1) / 2;
      paint.color = Colors.white.withOpacity(0.3 + twinkle * 0.5);
      canvas.drawCircle(Offset(dx, dy), 2 + twinkle * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ✅ END — Everything preserved
