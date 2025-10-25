import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumRealmScreen extends StatefulWidget {
  const PremiumRealmScreen({super.key});

  @override
  State<PremiumRealmScreen> createState() => _PremiumRealmScreenState();
}

class _PremiumRealmScreenState extends State<PremiumRealmScreen>
    with SingleTickerProviderStateMixin {
  static bool _isFirstVisit = true;
  bool _isVip = false; // add this to track VIP
  late AnimationController _glowController;
  late ConfettiController _confettiController;

  // 🌠 VIP welcome messages
  final List<String> _vipMessages = const [
    "Welcome, VIP Voyager — your path aligns with the stars today.",
    "Greetings, Honoured Explorer — the cosmos awaits your command.",
    "Welcome back, Celestial Patron — your frequency has been amplified.",
    "Salutations, Stellar Insider — fortune now bends in your favour.",
    "Ah, VIP Starwalker — planetary tides dance to your rhythm tonight.",
    "Esteemed Seeker — the Premium Realm reveals its deepest constellations.",
    "Chosen One — destiny listens closely to your vibration today."
  ];

  late String _selectedMessage;

  @override
  void initState() {
    super.initState();

    // 1️⃣ check VIP status first
    _checkVipStatus();

    // 2️⃣ setup glowing animation
    _glowController =
    AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    // 3️⃣ setup confetti animation
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    // 4️⃣ pick a random welcome message
    _selectedMessage =
    _vipMessages[Random().nextInt(_vipMessages.length)];
  }

  Future<void> _checkVipStatus() async {
    // Load the saved VIP flag from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final isVip = prefs.getBool('is_vip') ?? false;

    if (!isVip && mounted) {
      // Not VIP → wait briefly so build() finishes safely
      await Future.delayed(const Duration(milliseconds: 300));

      // Pop back to previous screen
      Navigator.pop(context);

      // Show red warning message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "🚫 VIP Access Only\nUnlock the Cosmos Realm to enter.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Is VIP → mark true and allow access
      setState(() => _isVip = true);

      // Play confetti once on first entry
      if (_isFirstVisit) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _confettiController.play();
          _isFirstVisit = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1430),
        title: Text(
          'Premium Cosmic Realm',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
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

          // Confetti effect at top
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 25,
              gravity: 0.1,
              colors: const [
                Colors.tealAccent,
                Colors.amberAccent,
                Colors.pinkAccent,
                Colors.blueAccent,
                Colors.purpleAccent,
              ],
            ),
          ),

          // Scroll content
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              const SizedBox(height: 24),
              Hero(
                tag: 'logo',
                child: Image.asset(
                  'assets/images/logolot.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              // 🌟 VIP Welcome Message (scrolls with content)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10162C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.tealAccent.withOpacity(0.2), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.tealAccent.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.stars,
                        color: Colors.tealAccent, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedMessage,
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              Text(
                'Unlock Your Cosmic Potential',
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 24,
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

              // 🔮 Feature Cards
              _buildCard(context, '🌙 Cosmic Forecast',
                  'Discover your lucky cosmic windows', '/forecast'),
              _buildCard(context, '🔮 Lucky Crystal & Charm',
                  'Find your weekly energy crystal', '/crystal'),
              _buildCard(context, '🌌 VIP Generator',
                  'Advanced celestial number generator', '/vip'),
              _buildCard(context, '🕯️ Manifestation Journal',
                  'Write intentions, track cosmic energy', '/journal'),
              _buildCard(context, '🧘 Meditation Mode',
                  'Align with celestial sounds', '/meditation'),
              _buildCard(context, '🧿 Ad-Free Cosmic Mode',
                  'Experience the stars uninterrupted', '/adfree'),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cosmicBackdrop() {
    return Positioned.fill(
      child: CustomPaint(painter: _StarfieldPainter()),
    );
  }

  Widget _buildCard(
      BuildContext context, String title, String subtitle, String route) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = 0.3 + (_glowController.value * 0.3);
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, route),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10162C),
                  Colors.teal.shade900.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.tealAccent.withOpacity(glow),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.tealAccent.withOpacity(glow * 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              title: Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.amberAccent.withOpacity(glow),
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }
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
