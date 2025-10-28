import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManifestationJournalScreen extends StatefulWidget {
  const ManifestationJournalScreen({super.key});

  @override
  State<ManifestationJournalScreen> createState() =>
      _ManifestationJournalScreenState();
}

class _ManifestationJournalScreenState
    extends State<ManifestationJournalScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _intentionCtrl = TextEditingController();
  final AudioPlayer _player = AudioPlayer();

  bool _working = false;
  String _aiResponse = '';
  double _progress = 0;
  Timer? _progressTimer;
  Timer? _messageTimer;
  String _statusMessage = 'Preparing your cosmic energy...';
  int _dailyManifestations = 0;
  String? _lastManifestationDate;

  final List<String> _messages = [
    'Preparing your cosmic energy...',
    'Aligning your intention with universal flow...',
    'Gathering stardust of manifestation...',
    'Empowering your words with celestial resonance...',
    'Whispering your desires into the infinite cosmos...',
    'Almost there... stay focused on your vision...',
  ];

  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadManifestationCount();
  }

  Future<void> _loadManifestationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = prefs.getString('last_manifestation_date') ?? '';
    final count = prefs.getInt('daily_manifestations') ?? 0;

    setState(() {
      if (lastDate != today) {
        _dailyManifestations = 0;
        _aiResponse = '';
        prefs.setString('last_manifestation_date', today);
        prefs.setInt('daily_manifestations', 0);
      } else {
        _dailyManifestations = count;
        _lastManifestationDate = lastDate;
        _aiResponse = prefs.getString('last_affirmation') ?? '';
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _intentionCtrl.dispose();
    _progressTimer?.cancel();
    _messageTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _manifest() async {
    final intention = _intentionCtrl.text.trim();
    if (intention.isEmpty) {
      _toast('Please share your cosmic intention 🌟');
      return;
    }

    if (_dailyManifestations >= 2) {
      _toast('You’ve reached your two daily manifestations. Return tomorrow for more cosmic power.');
      return;
    }

    setState(() {
      _working = true;
      _statusMessage = _messages[0];
      _progress = 0;
      _aiResponse = '';
    });

    _rotateMessages();

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      setState(() {
        if (_progress < 97) {
          _progress += 0.5;
        }
      });
    });

    final uri = Uri.parse('https://auranaguidance.co.uk/api/manifest');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'prompt':
        'Create a concise, mystical, uplifting manifestation affirmation inspired by: "$intention". '
            'Cosmic. Empowering. Positive. One or two sentences maximum. No disclaimers.'
      });

    try {
      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        throw Exception('HTTP ${streamedResponse.statusCode}');
      }

      _progressTimer?.cancel();
      if (mounted) setState(() => _progress = 100);

      final buffer = <int>[];
      streamedResponse.stream.listen((chunk) {
        buffer.addAll(chunk);
        final text = utf8.decode(buffer, allowMalformed: true);

        if (!mounted) return;
        setState(() => _aiResponse = text.trim());
      }, onDone: () async {
        if (!mounted) return;
        setState(() => _working = false);
        _statusMessage = "✨ Manifestation complete";

        if (_aiResponse.isNotEmpty) {
          _playSuccessTone();
          final prefs = await SharedPreferences.getInstance();
          _dailyManifestations++;
          await prefs.setInt('daily_manifestations', _dailyManifestations);
          await prefs.setString('last_affirmation', _aiResponse);
          await prefs.setString('last_manifestation_date',
              DateTime.now().toIso8601String().split('T')[0]);
        }
      }, onError: (_) {
        _fallbackManifest();
      });
    } catch (_) {
      _fallbackManifest();
    }
  }

  void _fallbackManifest() {
    if (!mounted) return;
    setState(() {
      _working = false;
      _aiResponse =
      'The cosmos whispered softly... please try again soon.';
    });
  }


  void _rotateMessages() {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      setState(() {
        final i = _messages.indexOf(_statusMessage);
        _statusMessage = _messages[(i + 1) % _messages.length];
      });
    });
  }

  void _clearJournal() {
    setState(() {
      _intentionCtrl.clear();
      _progress = 0;
    });
  }

  Future<void> _saveAffirmation() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_affirmations') ?? [];
    saved.add(_aiResponse);
    await prefs.setStringList('saved_affirmations', saved);
    _toast('Affirmation saved to your cosmic journal 📜');
  }

  void _shareAffirmation() {
    if (_aiResponse.isNotEmpty) {
      Share.share('🌌 My Cosmic Affirmation:\n\n$_aiResponse\n#AuranaApp');
    }
  }

  void _playSuccessTone() async {
    await _player.play(AssetSource('sounds/manifest_success.mp3'), volume: 0.5);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.blueAccent.shade700,
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
        centerTitle: true,
        title: Text(
          'Manifestation Journal',
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
              colors: [Colors.blue.shade900, const Color(0xFF0F1430)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const _CosmicMist(),
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
                  'VIP Manifestation Journal',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    color: Colors.blueAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.blueAccent.withOpacity(0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _infoBox(),
                const SizedBox(height: 24),
                _inputSection(),
                const SizedBox(height: 24),
                _buttonSection(),
                const SizedBox(height: 40),
                if (_working) _buildProgressSection(),
                if (!_working && _aiResponse.isNotEmpty)
                  _buildResponseCard(_aiResponse),
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
      border: Border.all(color: Colors.blueAccent.withOpacity(0.25)),
      boxShadow: [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.15),
          blurRadius: 16,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          'Shape Your Cosmic Destiny',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Pen your deepest intention below, and our celestial AI will craft a powerful affirmation infused with stellar energy. You are granted two manifestations per day to focus your intentions, enhancing their potency in the cosmic flow. Stay on this page as your vision aligns with the universe — it may take up to 5 minutes for the magic to manifest.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
            height: 1.7,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _inputSection() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF10162C),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      boxShadow: [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.1),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ],
    ),
    child: TextField(
      controller: _intentionCtrl,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 5,
      decoration: InputDecoration(
        hintText:
        'E.g., I attract abundance, peace, and opportunities effortlessly...',
        hintStyle: GoogleFonts.poppins(
          color: Colors.white38,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
      duration: 600.ms,
    ),
  );

  Widget _buttonSection() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        flex: 3,
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _working ? null : _manifest,
            icon: const Icon(Icons.auto_awesome, size: 24),
            label: Text(
              _working ? 'Channeling the Cosmos...' : 'Manifest Your Vision',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              shadowColor: Colors.blueAccent.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 1,
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, _) {
            final glow = 0.3 + (_glowController.value * 0.3);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _clearJournal,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(glow)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(glow * 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.clear, color: Colors.white70, size: 24),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _buildProgressSection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF10162C),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.2),
          blurRadius: 16,
          spreadRadius: 3,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1.5),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 60,
                height: (260 * _progress) / 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.blueAccent,
                      Colors.cyanAccent,
                      Colors.indigoAccent,
                      Colors.purpleAccent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                child: Text(
                  '${_progress.toInt()}%',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
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
            fontSize: 16,
            height: 1.6,
            fontStyle: FontStyle.italic,
          ),
        ).animate().fadeIn(duration: 800.ms),
      ],
    ),
  );

  Widget _buildResponseCard(String text) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFF151A2D),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.blueAccent.withOpacity(0.25)),
      boxShadow: [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.2),
          blurRadius: 16,
          spreadRadius: 3,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(
          Icons.auto_awesome,
          color: Colors.amberAccent,
          size: 36,
        ).animate().scale(duration: 800.ms),
        const SizedBox(height: 12),
        Text(
          'Your Cosmic Affirmation',
          style: GoogleFonts.orbitron(
            color: Colors.blueAccent,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            height: 1.8,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _iconButton(
              icon: Icons.share,
              tooltip: 'Share Affirmation',
              onTap: _shareAffirmation,
            ),
            const SizedBox(width: 16),
            _iconButton(
              icon: Icons.bookmark_add,
              tooltip: 'Save Affirmation',
              onTap: _saveAffirmation,
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 1000.ms).move(
      begin: const Offset(0, 30),
      end: Offset.zero,
      duration: 900.ms,
      curve: Curves.easeOutCubic,
    ),
  );

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = 0.3 + (_glowController.value * 0.3);
        return Tooltip(
          message: tooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amberAccent.withOpacity(glow)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(glow * 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.amberAccent, size: 28),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CosmicMist extends StatefulWidget {
  const _CosmicMist();

  @override
  State<_CosmicMist> createState() => _CosmicMistState();
}

class _CosmicMistState extends State<_CosmicMist>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MistPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _MistPainter extends CustomPainter {
  final double progress;
  _MistPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = RadialGradient(
      colors: [
        Colors.blueAccent.withOpacity(0.08 + progress * 0.12),
        Colors.amberAccent.withOpacity(0.06),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_MistPainter oldDelegate) =>
      oldDelegate.progress != progress;
}