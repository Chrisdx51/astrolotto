import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class MeditationModeScreen extends StatefulWidget {
  const MeditationModeScreen({super.key});

  @override
  State<MeditationModeScreen> createState() => _MeditationModeScreenState();
}

class _MeditationModeScreenState extends State<MeditationModeScreen>
    with TickerProviderStateMixin {
  bool _working = false;
  String _message = '';
  String _zodiac = 'Aries';
  final AudioPlayer _player = AudioPlayer();
  bool _playingSound = false;

  double _progress = 0;
  Timer? _progressTimer;

  late AnimationController _breathController;
  late AnimationController _waveController;
  Timer? _promptTimer;
  Timer? _statusTimer;

  String _breatheText = "Inhale...";
  String _statusMessage = 'Preparing your inner calm...';
  Color _breatheColor = Colors.redAccent;

  final List<Color> _chakraColors = const [
    Colors.redAccent,         // Root
    Colors.deepOrangeAccent,  // Sacral
    Colors.amberAccent,       // Solar Plexus
    Colors.greenAccent,       // Heart
    Colors.lightBlueAccent,   // Throat
    Colors.indigoAccent,      // Third Eye
    Colors.purpleAccent,      // Crown
  ];

  final List<String> _statusMessages = const [
    'Preparing your inner calm...',
    'The cosmic AI is crafting your personal meditation pathway...',
    'Synchronizing your breath with universal rhythm...',
    'Gathering celestial stillness and peace...',
    'Downloading your personalized guidance from the stars...',
    'Stay present — your VIP meditation is forming...',
  ];

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);

    _startBreathePrompt();
  }

  void _startBreathePrompt() {
    _promptTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      setState(() {
        _breatheText = _breatheText == "Inhale..." ? "Exhale..." : "Inhale...";
        // Pick a random chakra color without mutating the source list
        _breatheColor = _chakraColors[Random().nextInt(_chakraColors.length)];
      });
    });
  }

  void _startStatusRotation() {
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() {
        final i = _statusMessages.indexOf(_statusMessage);
        final nextIndex = (i < 0 ? 0 : (i + 1)) % _statusMessages.length;
        _statusMessage = _statusMessages[nextIndex];
      });
    });
  }

  // 🌌 Manual trigger for AI, VIP-style
  Future<void> _startMeditation() async {
    setState(() {
      _working = true;
      _message = '';
      _statusMessage = _statusMessages[0];
      _progress = 0;
    });
    _startStatusRotation();

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      setState(() {
        if (_progress < 95) {
          _progress += 0.6;
        } else if (_progress < 99) {
          _progress += 0.1;
        }
      });
    });

    final uri = Uri.parse('https://auranaguidance.co.uk/api/meditate');
    final body = {
      'prompt':
      'Create a soothing, deeply personalized meditation message for the zodiac sign $_zodiac. '
          'Focus on breathing, chakra alignment, inner peace, and cosmic connection. '
          'Use a calm, spiritual, and empowering tone. Keep it concise yet profound — perfect for a 5-minute session.'
    };

    debugPrint('🛰️ Meditation API: POST $uri');
    debugPrint('📦 Payload: ${jsonEncode(body)}');

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('✅ Status: ${res.statusCode}');
      debugPrint('🪐 Raw Response: ${res.body}');

      _progressTimer?.cancel();
      setState(() => _progress = 100);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        _message = decoded['result'] ??
            decoded['message'] ??
            decoded['content'] ??
            decoded['reply'] ??
            decoded['text'] ??
            'The universe is quiet, but your calm begins within.';

        setState(() {
          _working = false;
          _statusTimer?.cancel();
        });
      } else {
        setState(() {
          _message =
          'Connection interrupted. Please remain calm and try again. (HTTP ${res.statusCode})';
          _working = false;
          _statusTimer?.cancel();
        });
      }
    } catch (e, st) {
      debugPrint('❌ Meditation API error: $e');
      debugPrint('🧵 Stack: $st');

      setState(() {
        _message =
        'Cosmic connection lost. Please check your connection and try again.';
        _working = false;
        _statusTimer?.cancel();
      });
    } finally {
      _progressTimer?.cancel();
    }
  }


  Future<void> _toggleSound() async {
    if (_playingSound) {
      await _player.stop();
      setState(() => _playingSound = false);
    } else {
      await _player.play(AssetSource('sounds/meditation_loop.mp3'), volume: 0.5);
      _player.setReleaseMode(ReleaseMode.loop);
      setState(() => _playingSound = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _promptTimer?.cancel();
    _statusTimer?.cancel();
    _progressTimer?.cancel();
    _breathController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1430),
        centerTitle: true,
        title: Text(
          'Cosmic Meditation',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade900, const Color(0xFF0F1430)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                painter: _CosmicPainter(_waveController.value * 40),
                size: Size.infinite,
              );
            },
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/logolot.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'VIP Cosmic Meditation',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    color: Colors.tealAccent,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.tealAccent.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _infoBox(),
                const SizedBox(height: 32),
                _breathingCircle(),
                const SizedBox(height: 40),
                _working ? _progressSection() : _messageSection(),
                const SizedBox(height: 40),
                _meditationButton(),
                const SizedBox(height: 20),
                _soundButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF10162C),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.tealAccent.withOpacity(0.25)),
      boxShadow: [
        BoxShadow(
          color: Colors.tealAccent.withOpacity(0.15),
          blurRadius: 16,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          'Welcome to Your VIP Meditation Realm',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Dedicate 5 minutes daily to this sacred space. Follow the glowing chakra orb:\n\n'
              '• Inhale deeply as it expands and brightens\n'
              '• Exhale slowly as it softens and fades\n\n'
              'Your personalized cosmic guidance is being crafted by AI in harmony with your zodiac. '
              'Please remain on this page — it may take up to 5 minutes.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 15.5,
            height: 1.7,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _breathingCircle() => AnimatedBuilder(
    animation: _breathController,
    builder: (context, _) {
      final scale = 0.75 + (_breathController.value * 0.45);
      final glowOpacity = 0.3 + (_breathController.value * 0.4);
      return Transform.scale(
        scale: scale,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _breatheColor.withOpacity(glowOpacity),
                const Color(0xFF0F1430).withOpacity(0.8),
              ],
              radius: 0.85,
            ),
            boxShadow: [
              BoxShadow(
                color: _breatheColor.withOpacity(glowOpacity * 0.6),
                blurRadius: 60,
                spreadRadius: 15,
              ),
              BoxShadow(
                color: Colors.tealAccent.withOpacity(glowOpacity * 0.3),
                blurRadius: 100,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _breatheText,
                  style: GoogleFonts.orbitron(
                    color: _breatheColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: _breatheColor.withOpacity(0.6),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  _breatheText.contains("Inhale")
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: _breatheColor.withOpacity(0.8),
                  size: 32,
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 1000.ms)
            .scaleXY(begin: 0.8, end: 1.0, duration: 800.ms),

      );
    },
  );

  Widget _progressSection() => Column(
    children: [
      // Spacer for percent to avoid any overlap with the bar
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '${_progress.toInt()}%',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      SizedBox(
        height: 240,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.tealAccent.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 50,
              height: (240 * _progress) / 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.redAccent,
                    Colors.orangeAccent,
                    Colors.amberAccent,
                    Colors.greenAccent,
                    Colors.cyanAccent,
                    Colors.indigoAccent,
                    Colors.purpleAccent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.tealAccent.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        _statusMessage,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 17,
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
      ).animate().fadeIn(duration: 800.ms),
    ],
  );

  Widget _messageSection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF10162C),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.tealAccent.withOpacity(0.2)),
      boxShadow: [
        BoxShadow(
          color: Colors.tealAccent.withOpacity(0.1),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Text(
      _message.isNotEmpty
          ? _message
          : 'Tap "Begin Meditation" to receive your personalized cosmic guidance.',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: 18,
        height: 1.7,
        fontWeight: FontWeight.w500,
      ),
    ).animate().fadeIn(duration: 1200.ms).shimmer(duration: 2000.ms),
  );

  Widget _meditationButton() => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton.icon(
      onPressed: _working ? null : _startMeditation,
      icon: const Icon(Icons.auto_awesome, size: 26),
      label: Text(
        _working ? 'Crafting Your Meditation...' : 'Begin VIP Meditation',
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF14A1A0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        shadowColor: Colors.tealAccent.withOpacity(0.5),
      ),
    ),
  );

  Widget _soundButton() => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton.icon(
      onPressed: _toggleSound,
      icon: Icon(
        _playingSound ? Icons.pause_circle : Icons.play_circle,
        size: 26,
      ),
      label: Text(
        _playingSound ? 'Pause Cosmic Resonance' : 'Play Cosmic Resonance',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D8F8E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.tealAccent.withOpacity(0.3),
      ),
    ),
  );
}

class _CosmicPainter extends CustomPainter {
  final double offset;
  _CosmicPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.tealAccent.withOpacity(0.3),
          Colors.amberAccent.withOpacity(0.2),
          Colors.purpleAccent.withOpacity(0.2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (double i = 0; i < size.height; i += 55) {
      final path = Path();
      for (double x = 0; x < size.width; x += 12) {
        final y = i + sin((x + offset) / 55) * 18;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicPainter oldDelegate) =>
      oldDelegate.offset != offset;
}
