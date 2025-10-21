import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'main.dart';

const _cTurquoise = Color(0xFF12D1C0);
const _cMagenta = Color(0xFFFF4D9A);
const _cSunshine = Color(0xFFFFD166);
const _cDeepBlue = Color(0xFF0A003D);

class CosmicInsightsScreen extends StatefulWidget {
  const CosmicInsightsScreen({super.key});

  @override
  State<CosmicInsightsScreen> createState() => _CosmicInsightsScreenState();
}

class _CosmicInsightsScreenState extends State<CosmicInsightsScreen>
    with TickerProviderStateMixin {
  String _selectedSign = 'aries';
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  bool _isFetching = false; // prevents double fetch

  late final AnimationController _controller;
  late final Animation<double> _pulse;
  late final AnimationController _bgAnim;
  late final Animation<double> _bgMove;
  late final AnimationController _starsAnim;
  late final AnimationController _boxAnim;
  late final Animation<double> _boxScale;
  final List<Offset> _stars = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgMove = CurvedAnimation(parent: _bgAnim, curve: Curves.easeInOut);

    _starsAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _boxAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _boxScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _boxAnim, curve: Curves.easeOut),
    );

    _generateStars();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchHoroscope());
  }

  void _generateStars() {
    _stars.clear();
    for (int i = 0; i < 60; i++) {
      _stars.add(Offset(
        _rng.nextDouble() * 400,
        _rng.nextDouble() * 800,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgAnim.dispose();
    _starsAnim.dispose();
    _boxAnim.dispose();
    super.dispose();
  }

  Future<void> _fetchHoroscope() async {
    if (_isFetching) return;
    _isFetching = true;
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://ohmanda.com/api/horoscope/$_selectedSign');
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _data = {
            'description': json['horoscope'] ?? 'No horoscope available today.',
            'mood': _randomMood(),
            'color': _randomColor(),
            'lucky_number': (10 + Random().nextInt(89)).toString(),
          };
        });
        _boxAnim.forward(from: 0.0);
      } else {
        setState(() => _data = {'description': 'Unable to load horoscope.'});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _data = {'description': 'Error: $e'});
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _isFetching = false;
    }
  }

  String _randomMood() {
    const moods = [
      'Confident',
      'Inspired',
      'Focused',
      'Peaceful',
      'Joyful',
      'Energetic',
      'Reflective',
    ];
    return moods[Random().nextInt(moods.length)];
  }

  String _randomColor() {
    const colors = [
      'Mystic Gold',
      'Cosmic Blue',
      'Violet Dream',
      'Turquoise Glow',
      'Emerald Aura',
      'Crimson Spark',
      'Silver Light',
    ];
    return colors[Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    final desc = _data?['description'] ?? "Loading your stars...";
    final mood = _data?['mood'] ?? "—";
    final color = _data?['color'] ?? "—";
    final number = _data?['lucky_number'] ?? "—";

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
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
              ),
              // Twinkling stars
              AnimatedBuilder(
                animation: _starsAnim,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: StarPainter(_stars, _starsAnim.value),
                  );
                },
              ),
              SafeArea(
                child: Column(
                  children: [
                    const BannerAdWidget(isTop: true),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: _pulse,
                              child: Text(
                                "🔮 Daily Cosmic Forecast 🔮",
                                style: GoogleFonts.orbitron(
                                  fontSize: 28,
                                  color: _cSunshine,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1,
                                  shadows: [
                                    Shadow(
                                      color: _cSunshine.withOpacity(0.6),
                                      blurRadius: 10,
                                    ),
                                    Shadow(
                                      color: _cMagenta.withOpacity(0.4),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _cTurquoise.withOpacity(0.3),
                                    _cMagenta.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _cSunshine.withOpacity(0.5),
                                    width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _cSunshine.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedSign,
                                  dropdownColor: Colors.white,
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Colors.white),
                                  style: GoogleFonts.orbitron(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  items: const [
                                    'aries',
                                    'taurus',
                                    'gemini',
                                    'cancer',
                                    'leo',
                                    'virgo',
                                    'libra',
                                    'scorpio',
                                    'sagittarius',
                                    'capricorn',
                                    'aquarius',
                                    'pisces',
                                  ]
                                      .map((sign) => DropdownMenuItem(
                                    value: sign,
                                    child: Text(
                                      sign.toUpperCase(),
                                      style: GoogleFonts.orbitron(
                                        color: _cMagenta,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ))
                                      .toList(),
                                  onChanged: (v) async {
                                    if (v != null) {
                                      setState(() => _selectedSign = v);
                                      await _fetchHoroscope();
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Horoscope content
                            _isLoading
                                ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                    color: _cSunshine),
                              ),
                            )
                                : ScaleTransition(
                              scale: _boxScale,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color:
                                      _cSunshine.withOpacity(0.5),
                                      width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                      _cSunshine.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color:
                                      _cMagenta.withOpacity(0.2),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      desc,
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontSize: 16,
                                        height: 1.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    Divider(
                                        color: _cSunshine
                                            .withOpacity(0.3),
                                        thickness: 1),
                                    const SizedBox(height: 10),
                                    _infoRow("🌈 Lucky Color", color),
                                    _infoRow("🎯 Lucky Number", number),
                                    _infoRow("💫 Mood", mood),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Buttons
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _fetchHoroscope,
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white),
                                  label: Text(
                                    "Refresh",
                                    style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    _cTurquoise.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(20)),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                  label: Text(
                                    "Back",
                                    style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    _cMagenta.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(20)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // Disclaimer
                            Opacity(
                              opacity: 0.85,
                              child: Text(
                                "🔞 18+ • Entertainment Only • This horoscope is for fun and inspiration.\nNo prediction guarantees lottery wins or outcomes. Always play responsibly 💫",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.orbitron(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const BannerAdWidget(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.orbitron(
              color: Colors.white70,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: _cSunshine,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class StarPainter extends CustomPainter {
  final List<Offset> stars;
  final double animationValue;
  StarPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var star in stars) {
      final twinkle = (sin(animationValue * pi * 4 + star.dx) + 1) / 2;
      paint.color = Colors.white.withOpacity(0.3 + (twinkle * 0.5));
      canvas.drawCircle(star, 1.5 + (twinkle * 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
