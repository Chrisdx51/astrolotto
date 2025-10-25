import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';

class VipGeneratorScreen extends StatefulWidget {
  const VipGeneratorScreen({super.key});

  @override
  State<VipGeneratorScreen> createState() => _VipGeneratorScreenState();
}

class _VipGeneratorScreenState extends State<VipGeneratorScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String _zodiac = 'Aries';
  String _lottoType = 'Irish Lotto';
  String _mood = 'Optimistic';

  final List<String> _zodiacs = const [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  final List<String> _lottoTypes = const [
    'Irish Lotto', 'Powerball', 'EuroMillions'
  ];

  final List<String> _moods = const [
    'Optimistic', 'Reflective', 'Energetic', 'Calm', 'Adventurous', 'Mystical'
  ];

  bool _loading = false;
  double _progress = 0;
  String _status = 'Aligning your celestial data...';
  Timer? _progressTimer;
  Timer? _messageTimer;

  List<int> _mainBalls = [];
  int? _starBall;
  String _cosmicMessage = '';

  late AnimationController _glowController;
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _glowController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _confetti =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _colorCtrl.dispose();
    _progressTimer?.cancel();
    _messageTimer?.cancel();
    _glowController.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_nameCtrl.text.trim().isEmpty || _colorCtrl.text.trim().isEmpty) {
      _snack('Please enter your name and favorite color 🌙');
      return;
    }

    setState(() {
      _loading = true;
      _progress = 0;
      _status = 'Connecting to Astro Lotto cosmic servers...';
      _mainBalls.clear();
      _starBall = null;
      _cosmicMessage = '';
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      setState(() {
        if (_progress < 90) {
          _progress += 0.4;
        } else if (_progress < 97) {
          _progress += 0.1;
        }
      });
    });

    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(minutes: 1), () {
      if (_loading) {
        setState(() {
          _status =
          'Still aligning with the stars... please be patient 🌌\nThis can take several minutes while your cosmic pattern is decoded.';
        });
      }
    });

    try {
      final uri = Uri.parse('https://auranaguidance.co.uk/api/vip-generator');
      final body = {
        'prompt':
        'VIP cosmic lotto reading for ${_nameCtrl.text} with zodiac $_zodiac, favorite color ${_colorCtrl.text}, mood $_mood for $_lottoType.'
      };
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      _progressTimer?.cancel();
      setState(() => _progress = 100);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final msg = decoded['message'] ?? '';
        final nums = RegExp(r'\d+')
            .allMatches(msg)
            .map((m) => int.parse(m.group(0)!))
            .toList();

        final (main, star) = _normalizeNumbers(nums);
        setState(() {
          _mainBalls = main;
          _starBall = star;
          _cosmicMessage = _buildCosmicMessage();
          _status = '✨ Your VIP numbers are ready!';
          _confetti.play();
        });
      } else {
        _fallback();
      }
    } catch (_) {
      _fallback();
    } finally {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _loading = false);
      });
    }
  }

  (List<int>, int) _normalizeNumbers(List<int> nums) {
    final rand = Random();
    final main = <int>{};
    int maxMainNumbers;
    int maxBallRange;
    int maxStarBall;

    switch (_lottoType) {
      case 'Irish Lotto':
        maxMainNumbers = 6;
        maxBallRange = 47;
        maxStarBall = 0; // No bonus ball in Irish Lotto
        break;
      case 'Powerball':
        maxMainNumbers = 5;
        maxBallRange = 69;
        maxStarBall = 26;
        break;
      case 'EuroMillions':
        maxMainNumbers = 5;
        maxBallRange = 50;
        maxStarBall = 12;
        break;
      default:
        maxMainNumbers = 6;
        maxBallRange = 59;
        maxStarBall = 10;
    }

    for (final n in nums) {
      main.add(((n - 1) % maxBallRange) + 1);
      if (main.length == maxMainNumbers) break;
    }
    while (main.length < maxMainNumbers) {
      main.add(rand.nextInt(maxBallRange) + 1);
    }

    return (
    main.toList()..sort(),
    maxStarBall > 0 ? rand.nextInt(maxStarBall) + 1 : 0
    );
  }

  void _fallback() {
    final rand = Random();
    final main = <int>{};
    int maxMainNumbers;
    int maxBallRange;
    int maxStarBall;

    switch (_lottoType) {
      case 'Irish Lotto':
        maxMainNumbers = 6;
        maxBallRange = 47;
        maxStarBall = 0;
        break;
      case 'Powerball':
        maxMainNumbers = 5;
        maxBallRange = 69;
        maxStarBall = 26;
        break;
      case 'EuroMillions':
        maxMainNumbers = 5;
        maxBallRange = 50;
        maxStarBall = 12;
        break;
      default:
        maxMainNumbers = 6;
        maxBallRange = 59;
        maxStarBall = 10;
    }

    while (main.length < maxMainNumbers) {
      main.add(rand.nextInt(maxBallRange) + 1);
    }
    setState(() {
      _mainBalls = main.toList()..sort();
      _starBall = maxStarBall > 0 ? rand.nextInt(maxStarBall) + 1 : null;
      _cosmicMessage =
      'Connection interrupted — fallback numbers generated through cosmic intuition.';
      _status = '✨ Intuitive Mode Active';
    });
  }

  void _copy() {
    if (_mainBalls.isEmpty) return;
    final text = _starBall != null && _starBall! > 0
        ? 'Astro Lotto VIP Numbers ($_lottoType): ${_mainBalls.join(' ')} ⭐ $_starBall'
        : 'Astro Lotto VIP Numbers ($_lottoType): ${_mainBalls.join(' ')}';
    Clipboard.setData(ClipboardData(text: text));
    _snack('Copied to clipboard 🌟');
  }

  void _share() {
    if (_mainBalls.isEmpty) return;
    final text = _starBall != null && _starBall! > 0
        ? '🌌 My Astro Lotto VIP ($_lottoType) Numbers:\n${_mainBalls.join(' ')} ⭐ $_starBall\n#AstroLottoLuck'
        : '🌌 My Astro Lotto VIP ($_lottoType) Numbers:\n${_mainBalls.join(' ')}\n#AstroLottoLuck';
    Share.share(text);
  }

  String _buildCosmicMessage() {
    return 'Your VIP $_lottoType numbers have been harmonized with planetary motion, lunar alignment, your zodiac frequency, favorite color ${_colorCtrl.text}, and your $_mood mood. '
        'Each number vibrates through your unique cosmic pathway — revealing your deep celestial luck pattern.';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1430),
        title: Text(
          '🌌 VIP Cosmic Generator',
          style: GoogleFonts.orbitron(
            color: Colors.tealAccent,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
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
          _cosmicBackdrop(),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.15,
              colors: const [
                Colors.tealAccent,
                Colors.amberAccent,
                Colors.pinkAccent,
                Colors.blueAccent,
                Colors.purpleAccent,
              ],
            ),
          ),
          _loading ? _buildLoader() : _buildMain(),
        ],
      ),
    );
  }

  Widget _cosmicBackdrop() {
    return Positioned.fill(
      child: CustomPaint(painter: _StarfieldPainter()),
    );
  }

  Widget _buildMain() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Hero(
            tag: 'logo',
            child: Image.asset('assets/images/logolot.png', height: 100),
          ),
          const SizedBox(height: 16),
          Text(
            'Astro Lotto VIP Generator',
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              color: Colors.tealAccent,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.tealAccent.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _infoBox(),
          const SizedBox(height: 24),
          _formCard(),
          const SizedBox(height: 28),
          if (_mainBalls.isNotEmpty) _resultCard(),
        ],
      ),
    );
  }

  Widget _infoBox() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF10162C),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.tealAccent.withOpacity(0.2),
          blurRadius: 15,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🌠 Why Choose VIP?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Our VIP generator aligns your zodiac, favorite color, and current mood with real-time cosmic energies — including lunar phases, planetary alignments, and stellar vibrations — to craft numbers uniquely tuned to your celestial signature.',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '✨ Allow up to 5 minutes for this intricate cosmic alignment.',
          style: GoogleFonts.poppins(
            color: Colors.amberAccent,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    ),
  );

  Widget _formCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF10162C),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.tealAccent.withOpacity(0.15),
          blurRadius: 12,
          spreadRadius: 1,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        _textField('Your Name', _nameCtrl, 'e.g. Alex'),
        const SizedBox(height: 16),
        _textField('Favorite Color', _colorCtrl, 'e.g. Blue'),
        const SizedBox(height: 16),
        _dropdown('Zodiac Sign', _zodiacs, _zodiac, (v) => _zodiac = v ?? 'Aries'),
        const SizedBox(height: 16),
        _dropdown('Current Mood', _moods, _mood, (v) => _mood = v ?? 'Optimistic'),
        const SizedBox(height: 16),
        _dropdown('Lotto Type', _lottoTypes, _lottoType,
                (v) => _lottoType = v ?? 'Irish Lotto'),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome, size: 24),
            label: Text(
              'Generate VIP Numbers',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: const Color(0xFF0A003D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 5,
              shadowColor: Colors.tealAccent.withOpacity(0.4),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _textField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0F1430),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(String label, List<String> items, String value,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1430),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.tealAccent.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: const Color(0xFF0F1430),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
              items: items
                  .map((z) => DropdownMenuItem(
                value: z,
                child: Text(
                  z,
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ))
                  .toList(),
              onChanged: (v) => setState(() => onChanged(v)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultCard() => AnimatedOpacity(
    duration: const Duration(seconds: 1),
    opacity: 1,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10162C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Cosmic VIP Numbers',
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.tealAccent.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              ..._mainBalls.map((n) => _glowingBall(n)),
              if (_starBall != null && _starBall! > 0) _starBallWidget(_starBall!),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _cosmicMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(
                icon: Icons.copy,
                color: Colors.amberAccent,
                onPressed: _copy,
                tooltip: 'Copy Numbers',
              ),
              const SizedBox(width: 16),
              _actionButton(
                icon: Icons.share,
                color: Colors.tealAccent,
                onPressed: _share,
                tooltip: 'Share Numbers',
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _glowingBall(int n) => AnimatedBuilder(
    animation: _glowController,
    builder: (_, __) {
      final glow = 0.5 + (_glowController.value * 0.5);
      return Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.tealAccent.withOpacity(0.2),
              const Color(0xFF0F1430),
            ],
          ),
          border: Border.all(
            color: Colors.tealAccent.withOpacity(glow),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.tealAccent.withOpacity(glow * 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          '$n',
          style: GoogleFonts.orbitron(
            color: Colors.tealAccent,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    },
  );

  Widget _starBallWidget(int n) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.tealAccent.shade400, Colors.teal.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.tealAccent.withOpacity(0.3),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
        const SizedBox(width: 8),
        Text(
          '⭐ $n',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'logo',
            child: Image.asset('assets/images/logolot.png', height: 100),
          ),
          const SizedBox(height: 24),
          Text(
            'Generating your VIP numbers for $_lottoType...',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 18,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _progress / 100,
                  strokeWidth: 8,
                  color: Colors.tealAccent,
                  backgroundColor: Colors.white12,
                ),
                Text(
                  '${_progress.toInt()}%',
                  style: GoogleFonts.orbitron(
                    color: Colors.tealAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StarfieldPainter extends CustomPainter {
  final Random _rand = Random();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.2);
    for (var i = 0; i < 150; i++) {
      final dx = _rand.nextDouble() * size.width;
      final dy = _rand.nextDouble() * size.height;
      final r = _rand.nextDouble() * 2;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}