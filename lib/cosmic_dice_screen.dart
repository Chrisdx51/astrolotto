// cosmic_dice_screen.dart
// ✅ Cosmic Dice — Magical, professional, cosmic design with animated particles, glowing effects, pulsing logo, and enhanced 3D dice
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'main.dart'; // for bannerAdUnitId

const _cTurquoise = Color(0xFF12D1C0);
const _cMagenta = Color(0xFFFF4D9A);
const _cSunshine = Color(0xFFFFD166);
const _cDeepBlue = Color(0xFF0A003D);

class Particle {
  double x;
  double y;
  double dx;
  double dy;
  double size;
  double opacity;
  double phase;

  Particle(this.x, this.y, this.dx, this.dy, this.size, this.opacity, this.phase);
}

class CosmicDiceScreen extends StatefulWidget {
  final String? name;
  final String? zodiac;
  final String? country;
  final String? moonPhase;

  const CosmicDiceScreen({
    super.key,
    this.name,
    this.zodiac,
    this.country,
    this.moonPhase,
  });

  @override
  State<CosmicDiceScreen> createState() => _CosmicDiceScreenState();
}

class _CosmicDiceScreenState extends State<CosmicDiceScreen> with TickerProviderStateMixin {
  final Random _rng = Random();
  // Dice values 1..6
  int _d1 = 1, _d2 = 1, _d3 = 1;
  // Roll animation
  late final AnimationController _rollCtrl;
  Timer? _shuffleTimer;
  bool _rolling = false;
  // Individual dice animation controllers
  late final AnimationController _dice1Ctrl;
  late final AnimationController _dice2Ctrl;
  late final AnimationController _dice3Ctrl;
  // Animations for 3D spinning and translation
  late final Animation<double> _spinX1, _spinY1, _spinZ1, _transX1, _transY1;
  late final Animation<double> _spinX2, _spinY2, _spinZ2, _transX2, _transY2;
  late final Animation<double> _spinX3, _spinY3, _spinZ3, _transX3, _transY3;
  // Hourly limit
  int _rollsThisHour = 0;
  DateTime? _windowStart;
  // Ads + VIP
  bool _isVip = false;
  BannerAd? _topBanner;
  BannerAd? _bottomBanner;
  // AI
  bool _aiLoading = false;
  String? _affirmation;
  // Background ambience
  late final AnimationController _bgAnim;
  late final Animation<double> _bgMove;
  // Logo pulse
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleGlow;
  // Cosmic particles
  final List<Particle> _particles = [];
  double _particleTime = 0.0;
  late Timer _particleTimer;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _bgMove = CurvedAnimation(parent: _bgAnim, curve: Curves.easeInOut);
    _rollCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    // Initialize individual dice controllers
    _dice1Ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _dice2Ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _dice3Ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    // Define 3D spinning and translation animations
    _spinX1 = Tween<double>(begin: 0, end: 8 * pi).animate(CurvedAnimation(parent: _dice1Ctrl, curve: Curves.easeOut));
    _spinY1 = Tween<double>(begin: 0, end: 6 * pi).animate(CurvedAnimation(parent: _dice1Ctrl, curve: Curves.easeOut));
    _spinZ1 = Tween<double>(begin: 0, end: 4 * pi).animate(CurvedAnimation(parent: _dice1Ctrl, curve: Curves.easeOut));
    _transX1 = Tween<double>(begin: -120, end: 0).animate(CurvedAnimation(parent: _dice1Ctrl, curve: Curves.easeOut));
    _transY1 = Tween<double>(begin: 60, end: 0).animate(CurvedAnimation(parent: _dice1Ctrl, curve: Curves.easeOut));
    _spinX2 = Tween<double>(begin: 0, end: 7 * pi).animate(CurvedAnimation(parent: _dice2Ctrl, curve: Curves.easeOut));
    _spinY2 = Tween<double>(begin: 0, end: 5 * pi).animate(CurvedAnimation(parent: _dice2Ctrl, curve: Curves.easeOut));
    _spinZ2 = Tween<double>(begin: 0, end: 5 * pi).animate(CurvedAnimation(parent: _dice2Ctrl, curve: Curves.easeOut));
    _transX2 = Tween<double>(begin: 0, end: 0).animate(CurvedAnimation(parent: _dice2Ctrl, curve: Curves.easeOut));
    _transY2 = Tween<double>(begin: -60, end: 0).animate(CurvedAnimation(parent: _dice2Ctrl, curve: Curves.easeOut));
    _spinX3 = Tween<double>(begin: 0, end: 6 * pi).animate(CurvedAnimation(parent: _dice3Ctrl, curve: Curves.easeOut));
    _spinY3 = Tween<double>(begin: 0, end: 7 * pi).animate(CurvedAnimation(parent: _dice3Ctrl, curve: Curves.easeOut));
    _spinZ3 = Tween<double>(begin: 0, end: 6 * pi).animate(CurvedAnimation(parent: _dice3Ctrl, curve: Curves.easeOut));
    _transX3 = Tween<double>(begin: 120, end: 0).animate(CurvedAnimation(parent: _dice3Ctrl, curve: Curves.easeOut));
    _transY3 = Tween<double>(begin: 60, end: 0).animate(CurvedAnimation(parent: _dice3Ctrl, curve: Curves.easeOut));
    // Logo and title animation
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _logoScale = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut));
    _titleGlow = Tween<double>(begin: 8.0, end: 15.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut));
    // Cosmic particles
    for (int i = 0; i < 100; i++) {
      final double speed = _rng.nextDouble() * 0.5 + 0.5;
      final double direction = _rng.nextDouble() * 2 * pi;
      _particles.add(Particle(
        _rng.nextDouble() * 400,
        _rng.nextDouble() * 800,
        speed * cos(direction),
        speed * sin(direction),
        _rng.nextDouble() * 2 + 1,
        1.0,
        _rng.nextDouble() * 2 * pi,
      ));
    }
    _particleTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      _particleTime += 0.03;
      for (var p in _particles) {
        p.x += p.dx;
        p.y += p.dy;
        p.opacity = 0.5 + 0.5 * sin(_particleTime + p.phase);
        p.x = (p.x % 400 + 400) % 400;
        p.y = (p.y % 800 + 800) % 800;
      }
      setState(() {});
    });
    _loadVip();
    _loadLimit();
    _prepareBanners();
  }

  Future<void> _loadVip() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isVip = prefs.getBool('is_vip') ?? false;
    });
  }

  Future<void> _loadLimit() async {
    final prefs = await SharedPreferences.getInstance();
    _rollsThisHour = prefs.getInt('dice_rolls') ?? 0;
    final ts = prefs.getString('dice_window_start');
    _windowStart = ts != null ? DateTime.tryParse(ts) : null;
    _maybeResetWindow();
  }

  void _maybeResetWindow() async {
    final now = DateTime.now();
    if (_windowStart == null || now.difference(_windowStart!).inHours >= 1) {
      _windowStart = now;
      _rollsThisHour = 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dice_window_start', _windowStart!.toIso8601String());
      await prefs.setInt('dice_rolls', _rollsThisHour);
    }
  }

  Future<void> _incRollCount() async {
    _rollsThisHour++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dice_rolls', _rollsThisHour);
    if (_windowStart == null) {
      _windowStart = DateTime.now();
      await prefs.setString('dice_window_start', _windowStart!.toIso8601String());
    }
  }

  void _prepareBanners() {
    if (_isVip) return;
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

  @override
  void dispose() {
    _bgAnim.dispose();
    _rollCtrl.dispose();
    _dice1Ctrl.dispose();
    _dice2Ctrl.dispose();
    _dice3Ctrl.dispose();
    _logoCtrl.dispose();
    _shuffleTimer?.cancel();
    _particleTimer.cancel();
    _topBanner?.dispose();
    _bottomBanner?.dispose();
    super.dispose();
  }

  // ───────────────────────── Roll flow ─────────────────────────
  Future<void> _rollDice() async {
    if (_rolling) return;
    _maybeResetWindow();
    if (_rollsThisHour >= 3) {
      _snack("You’ve reached 3 rolls. Try again in an hour ✨");
      return;
    }
    setState(() {
      _rolling = true;
      _affirmation = null;
      _aiLoading = true;
    });
    // Start 3D animations
    _dice1Ctrl.forward(from: 0);
    _dice2Ctrl.forward(from: 0);
    _dice3Ctrl.forward(from: 0);
    _rollCtrl.forward(from: 0);
    int tick = 0;
    _shuffleTimer?.cancel();
    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      tick++;
      setState(() {
        _d1 = 1 + _rng.nextInt(6);
        _d2 = 1 + _rng.nextInt(6);
        _d3 = 1 + _rng.nextInt(6);
      });
      if (tick >= 12) {
        t.cancel();
        _finishRoll();
      }
    });
  }

  Future<void> _finishRoll() async {
    await _incRollCount();
    final total = _d1 + _d2 + _d3;
    await _fetchAffirmation(total);
    if (!mounted) return;
    setState(() {
      _rolling = false;
      _aiLoading = false;
    });
  }

  Future<void> _fetchAffirmation(int total) async {
    try {
      final name = (widget.name?.trim().isNotEmpty ?? false) ? widget.name!.trim() : "Seeker";
      final zodiac = (widget.zodiac?.trim().isNotEmpty ?? false) ? widget.zodiac!.trim() : "your sign";
      final country = (widget.country?.trim().isNotEmpty ?? false) ? widget.country!.trim() : "your realm";
      final moon = (widget.moonPhase?.trim().isNotEmpty ?? false) ? widget.moonPhase!.trim() : "the current moon";
      final uri = Uri.parse("https://auranaguidance.co.uk/api/lottofortune");
      final style = _isVip ? "Give a mystical but grounded, premium-quality affirmation in 40–70 words with a specific focus point." : "Short, uplifting affirmation, MAX 20 words.";
      final prompt = """
COSMIC DICE AFFIRMATION
User: $name, Zodiac: $zodiac, Country: $country, Moon: $moon
Rolled total: $total
Task: $style
Avoid emojis. 1–2 short sentences. No disclaimers. Return text only.
""";
      final request = http.Request('POST', uri)
        ..headers["Content-Type"] = "application/json"
        ..body = jsonEncode({"prompt": prompt});
      final streamed = await request.send();
      if (streamed.statusCode != 200) {
        throw Exception("HTTP ${streamed.statusCode}");
      }
      final buffer = <int>[];
      String lastText = "";
      await for (final chunk in streamed.stream) {
        buffer.addAll(chunk);
        lastText = utf8.decode(buffer, allowMalformed: true).trim();
        setState(() => _affirmation = lastText);
      }
      if (lastText.isEmpty) {
        setState(() => _affirmation = _fallbackAffirmation(total));
      }
    } catch (_) {
      setState(() => _affirmation = _fallbackAffirmation(total));
    }
  }

  String _fallbackAffirmation(int total) {
    const lines = [
      "Trust the path. Your next step is guided.",
      "Focus your energy; small actions create big flow.",
      "You are aligned. Move with quiet confidence.",
      "Say yes to the opportunity that returns.",
      "Your patience is power. Keep the course.",
      "Clarity grows when you choose simplicity.",
    ];
    return lines[total % lines.length];
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ───────────────────────── UI ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = [
      Color.lerp(_cDeepBlue, _cMagenta, _bgMove.value)!,
      Color.lerp(_cMagenta, _cTurquoise, 0.6 * _bgMove.value)!,
      Color.lerp(_cTurquoise, _cSunshine, 0.8 * (1 - _bgMove.value))!,
    ];
    return AnimatedBuilder(
      animation: _bgMove,
      builder: (_, __) {
        return Scaffold(
          body: Stack(
            children: [
              // Cosmic gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
              ),
              // Cosmic particles
              ..._particles.map((p) => Positioned(
                left: p.x,
                top: p.y,
                child: Opacity(
                  opacity: p.opacity,
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.white, blurRadius: 4, spreadRadius: 1),
                      ],
                    ),
                  ),
                ),
              )),
              SafeArea(
                child: Column(
                  children: [
                    if (!_isVip && _topBanner != null)
                      SizedBox(height: 50, width: double.infinity, child: AdWidget(ad: _topBanner!)),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            // Pulsing logo
                            AnimatedBuilder(
                              animation: _logoCtrl,
                              builder: (_, child) => Transform.scale(
                                scale: _logoScale.value,
                                child: child,
                              ),
                              child: Image.asset(
                                'assets/images/logolot.png',
                                width: 200,
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Glowing title
                            AnimatedBuilder(
                              animation: _logoCtrl,
                              builder: (_, __) => Text(
                                "COSMIC DICE",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.orbitron(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  shadows: [Shadow(color: _cSunshine, blurRadius: _titleGlow.value)],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Explanation Box with subtle glow
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(color: _cMagenta.withOpacity(0.3), blurRadius: 10, spreadRadius: 2),
                                ],
                              ),
                              child: _ExplanationBox(isVip: _isVip),
                            ),
                            const SizedBox(height: 16),
                            // Dice Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _DiceBox(
                                  value: _d1,
                                  rolling: _rolling,
                                  controller: _dice1Ctrl,
                                  spinX: _spinX1,
                                  spinY: _spinY1,
                                  spinZ: _spinZ1,
                                  transX: _transX1,
                                  transY: _transY1,
                                ),
                                const SizedBox(width: 18),
                                _DiceBox(
                                  value: _d2,
                                  rolling: _rolling,
                                  controller: _dice2Ctrl,
                                  spinX: _spinX2,
                                  spinY: _spinY2,
                                  spinZ: _spinZ2,
                                  transX: _transX2,
                                  transY: _transY2,
                                ),
                                const SizedBox(width: 18),
                                _DiceBox(
                                  value: _d3,
                                  rolling: _rolling,
                                  controller: _dice3Ctrl,
                                  spinX: _spinX3,
                                  spinY: _spinY3,
                                  spinZ: _spinZ3,
                                  transX: _transX3,
                                  transY: _transY3,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _rolling ? "Rolling the cosmic cubes..." : "Tap ROLL to receive your number and affirmation.",
                              style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: 220,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: _rolling ? null : _rollDice,
                                icon: const Icon(Icons.casino, color: Colors.white),
                                label: Text(
                                  _rolling ? "Rolling..." : "ROLL",
                                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _cMagenta.withOpacity(0.9),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  elevation: 8,
                                  shadowColor: _cMagenta,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LimitPill(count: _rollsThisHour),
                            const SizedBox(height: 24),
                            // Affirmation Box with glow
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  if (!_aiLoading && _affirmation != null)
                                    BoxShadow(color: _cSunshine.withOpacity(0.4), blurRadius: 15, spreadRadius: 3),
                                ],
                              ),
                              child: _AffirmationBox(
                                loading: _aiLoading,
                                text: _affirmation,
                                total: _d1 + _d2 + _d3,
                                isVip: _isVip,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 220,
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                label: Text("Back", style: GoogleFonts.orbitron(color: Colors.white)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white54),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_isVip && _bottomBanner != null)
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
}

// ───────────────────────── Widgets ─────────────────────────
class _LimitPill extends StatelessWidget {
  final int count;
  const _LimitPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        "Rolls this hour: $count / 3",
        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _AffirmationBox extends StatelessWidget {
  final bool loading;
  final String? text;
  final int total;
  final bool isVip;

  const _AffirmationBox({
    required this.loading,
    required this.text,
    required this.total,
    required this.isVip,
  });

  @override
  Widget build(BuildContext context) {
    final title = "Your Lucky Number: $total";
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (loading) ...[
            const LinearProgressIndicator(minHeight: 4, color: _cSunshine, backgroundColor: Colors.white24),
            const SizedBox(height: 12),
            Text("Attuning your affirmation...", style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 13)),
          ] else ...[
            Text(
              text ?? "Roll the dice to receive your affirmation.",
              textAlign: TextAlign.center,
              style: GoogleFonts.merriweather(color: Colors.white, fontSize: 18, height: 1.6),
            ),
            const SizedBox(height: 10),
            if (!isVip)
              Text(
                "VIP gets deeper readings.",
                style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 11),
              ),
          ],
        ],
      ),
    );
  }
}

class _ExplanationBox extends StatelessWidget {
  final bool isVip;

  const _ExplanationBox({required this.isVip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        "The Cosmic Dice connect your intention with universal flow.\n\n"
            "Each roll channels your current energy into a single number — a reflection of where opportunity forms for you right now.\n\n"
            "${isVip
            ? 'As a VIP, your affirmation unlocks deeper meaning and specific daily direction.'
            : 'Upgrade to VIP for longer, more powerful affirmations tuned to your path.'}"
        ,
        textAlign: TextAlign.center,
        style: GoogleFonts.merriweather(
          color: Colors.white,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}

class _DiceBox extends StatelessWidget {
  final int value; // 1..6
  final bool rolling;
  final AnimationController controller;
  final Animation<double> spinX;
  final Animation<double> spinY;
  final Animation<double> spinZ;
  final Animation<double> transX;
  final Animation<double> transY;

  const _DiceBox({
    required this.value,
    required this.rolling,
    required this.controller,
    required this.spinX,
    required this.spinY,
    required this.spinZ,
    required this.transX,
    required this.transY,
  });

  @override
  Widget build(BuildContext context) {
    // Define cube faces with cosmic glow
    Widget face(int faceValue, Matrix4 transform) {
      final active = <int>{};
      switch (faceValue) {
        case 1:
          active.addAll([5]);
          break;
        case 2:
          active.addAll([1, 9]);
          break;
        case 3:
          active.addAll([1, 5, 9]);
          break;
        case 4:
          active.addAll([1, 3, 7, 9]);
          break;
        case 5:
          active.addAll([1, 3, 5, 7, 9]);
          break;
        case 6:
          active.addAll([1, 3, 4, 6, 7, 9]);
          break;
      }
      Widget dot(bool on) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.white24,
          shape: BoxShape.circle,
          boxShadow: on ? [const BoxShadow(color: Colors.white70, blurRadius: 4)] : null,
        ),
      );
      Widget cell(int idx) => Center(child: dot(active.contains(idx)));
      return Transform(
        transform: transform,
        alignment: Alignment.center,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cDeepBlue, _cMagenta],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white30),
            boxShadow: const [
              BoxShadow(color: _cTurquoise, blurRadius: 10, offset: Offset(2, 2)),
              BoxShadow(color: _cSunshine, blurRadius: 8, spreadRadius: 2),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              crossAxisCount: 3,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: List.generate(9, (i) => cell(i + 1)),
            ),
          ),
        ),
      );
    }

    // Face transforms for standard die layout
    Matrix4 getFaceTransform(int face) {
      switch (face) {
        case 1:
          return Matrix4.identity()..translate(0.0, 0.0, -35.0);
        case 6:
          return Matrix4.identity()..translate(0.0, 0.0, 35.0);
        case 2:
          return Matrix4.identity()..rotateY(pi / 2)..translate(0.0, 0.0, -35.0);
        case 5:
          return Matrix4.identity()..rotateY(-pi / 2)..translate(0.0, 0.0, -35.0);
        case 3:
          return Matrix4.identity()..rotateX(-pi / 2)..translate(0.0, 0.0, -35.0);
        case 4:
          return Matrix4.identity()..rotateX(pi / 2)..translate(0.0, 0.0, -35.0);
        default:
          return Matrix4.identity()..translate(0.0, 0.0, -35.0);
      }
    }

    final cubeFaces = [
      face(1, getFaceTransform(1)),
      face(6, getFaceTransform(6)),
      face(2, getFaceTransform(2)),
      face(5, getFaceTransform(5)),
      face(3, getFaceTransform(3)),
      face(4, getFaceTransform(4)),
    ];

    final cube = Stack(children: cubeFaces);

    Matrix4 getFinalTransform() {
      switch (value) {
        case 1:
          return Matrix4.identity();
        case 6:
          return Matrix4.identity()..rotateY(pi);
        case 2:
          return Matrix4.identity()..rotateY(-pi / 2);
        case 5:
          return Matrix4.identity()..rotateY(pi / 2);
        case 3:
          return Matrix4.identity()..rotateX(pi / 2);
        case 4:
          return Matrix4.identity()..rotateX(-pi / 2);
        default:
          return Matrix4.identity();
      }
    }

    final glowBlur = rolling ? 20.0 : 10.0;

    if (!rolling) {
      return Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: _cSunshine.withOpacity(0.5), blurRadius: glowBlur, spreadRadius: 5),
          ],
        ),
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..multiply(getFinalTransform()),
          alignment: Alignment.center,
          child: cube,
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: _cSunshine.withOpacity(0.5), blurRadius: glowBlur, spreadRadius: 5),
          ],
        ),
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateX(spinX.value)
            ..rotateY(spinY.value)
            ..rotateZ(spinZ.value)
            ..translate(transX.value, transY.value),
          alignment: Alignment.center,
          child: child,
        ),
      ),
      child: Container(
        width: 88,
        height: 88,
        child: cube,
      ),
    );
  }
}

class _Pips extends StatelessWidget {
  final int value;
  const _Pips({required this.value});

  @override
  Widget build(BuildContext context) {
    final active = <int>{};
    switch (value) {
      case 1:
        active.addAll([5]);
        break;
      case 2:
        active.addAll([1, 9]);
        break;
      case 3:
        active.addAll([1, 5, 9]);
        break;
      case 4:
        active.addAll([1, 3, 7, 9]);
        break;
      case 5:
        active.addAll([1, 3, 5, 7, 9]);
        break;
      default:
        active.addAll([1, 3, 4, 6, 7, 9]); // 6
    }
    Widget dot(bool on) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: on ? Colors.white : Colors.white24,
        shape: BoxShape.circle,
        boxShadow: on ? [const BoxShadow(color: Colors.white70, blurRadius: 4)] : null,
      ),
    );
    Widget cell(int idx) => Center(child: dot(active.contains(idx)));
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: List.generate(9, (i) => cell(i + 1)),
      ),
    );
  }
}