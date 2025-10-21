import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // for bannerAdUnitId etc.

const _cTurquoise = Color(0xFF12D1C0);
const _cMagenta = Color(0xFFFF4D9A);
const _cSunshine = Color(0xFFFFD166);
const _cDeepBlue = Color(0xFF0A003D);

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});
  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with TickerProviderStateMixin {
  // Animations
  late final AnimationController _bgAnim;
  late final Animation<double> _bgMove;
  late final AnimationController _starsAnim;
  late final AnimationController _spinPulse; // visual pulse while spinning

  // Wheel
  bool _isSpinning = false;
  double _angle = 0.0;

  // Fortune
  String? _fortuneMessage;

  // Stars
  final List<Offset> _stars = [];
  final Random _rng = Random();

  // Cached banners (no rebuild leaks)
  BannerAd? _topBanner;
  BannerAd? _bottomBanner;

  @override
  void initState() {
    super.initState();

    // Background gradient animation (gentle)
    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _bgMove = CurvedAnimation(parent: _bgAnim, curve: Curves.easeInOut);

    // Stars twinkle
    _starsAnim = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();

    // Pulse while spinning (also used as timer)
    _spinPulse = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _spinPulse.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // end of spin
        setState(() {
          _isSpinning = false;
          _generateFortune();
        });
      }
    });

    _generateStars();
    _loadSavedFortune();

    // Preload banners once
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

  void _generateFortune() {
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

    _fortuneMessage = "$fortune\n\n✨ Lucky Day: $day\n🎨 Lucky Color: $color";
  }

  void _spinWheel() {
    if (_isSpinning) return;

    final random = Random();
    final spins = 3 + random.nextInt(4);
    final stopAngle = random.nextDouble() * 2 * pi;

    setState(() {
      _isSpinning = true;
      _fortuneMessage = null;
      // Set the new angle NOW so AnimatedRotation handles the 4s rotation
      _angle += spins * 2 * pi + stopAngle;
    });

    _spinPulse
      ..reset()
      ..forward(); // after 4s -> listener above generates the fortune
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _starsAnim.dispose();
    _spinPulse.dispose();
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
              // Animated gradient background
              RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                  ),
                ),
              ),

              // Star twinkle overlay (only repaints its layer)
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _starsAnim,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _StarPainter(_stars, _starsAnim.value),
                    );
                  },
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
                            const SizedBox(height: 30),

                            // Wheel: rotates over 4s using _angle delta; pulses while spinning
                            AnimatedBuilder(
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
                                          child: Text(
                                            "SPIN",
                                            style: GoogleFonts.orbitron(
                                              color: _cDeepBlue,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 34),

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

                            const SizedBox(height: 30),

                            if (_fortuneMessage != null)
                              Container(
                                padding: const EdgeInsets.all(20),
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white30, width: 1),
                                  boxShadow: [
                                    BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 12),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "🔮 Your Cosmic Fortune 🔮",
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _fortuneMessage!,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
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
                                  ],
                                ),
                              ),

                            const SizedBox(height: 28),

                            SizedBox(
                              width: 220,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                label: Text(
                                  "Back to Generator",
                                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
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
}

class _StarPainter extends CustomPainter {
  final List<Offset> stars; // generated in a 400x800 "virtual canvas"
  final double animationValue;

  _StarPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);

    for (final v in stars) {
      // Map the virtual coords (0..400, 0..800) into real screen size
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
