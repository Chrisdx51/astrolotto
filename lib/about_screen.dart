// lib/about_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _cTurquoise = Color(0xFF12D1C0);
const _cMagenta   = Color(0xFFFF4D9A);
const _cSunshine  = Color(0xFFFFD166);
const _cDeepBlue  = Color(0xFF0B0F1A);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cDeepBlue,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1430),
        title: Text("About Astro Lotto Luck",
            style: GoogleFonts.orbitron(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // header logo (optional)
            Image.asset('assets/images/logolot.png', width: 140),
            const SizedBox(height: 18),

            // tagline
            Text(
              "Where Spirituality Meets Probability",
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: _cSunshine,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),

            // pretty card block
            _CardBlock(
              title: "How our AI works",
              child: Text(
                "Astro Lotto Luck blends spiritual insight with scientific curiosity. "
                    "When you share details like your date of birth and place of birth, our system aligns that data with the cosmos — the Sun, the Moon, current lunar phase, and orbital rhythms. "
                    "From that alignment, the app surfaces numbers that ‘shine’ for you right now.\n\n"
                    "This is not fortune-telling or a promise of jackpot results. "
                    "It’s a mindful practice that combines astrology-inspired mapping with modern algorithms to create numbers that feel aligned, symbolic, and personally lucky.",
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 14),

            _CardBlock(
              title: "What that means for you",
              child: Text(
                "• Your numbers are influenced by birth data and today’s sky (Sun, Moon, and orbital context).\n"
                    "• The Moon’s phase (e.g., Waxing Gibbous, Full Moon) is acknowledged in your fortune.\n"
                    "• The stars do not say *what* the numbers will be best for — they reflect your current energy. "
                    "Use them as inspiration for play, focus, journaling, or intention-setting.\n"
                    "• Numbers can be ‘lucky’ in many ways — not only in lotteries.",
                textAlign: TextAlign.left,
                style: GoogleFonts.orbitron(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 14),

            _CardBlock(
              title: "Friendly clarity",
              child: Text(
                "We’re honest about what this is: a beautiful blend of spiritual symbolism and data-driven creativity. "
                    "It’s designed to be uplifting, reflective, and fun — a small ritual that helps you feel connected to something bigger while you play.",
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // strong, clear disclaimer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _cMagenta.withOpacity(0.20),
                    _cTurquoise.withOpacity(0.20),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _cSunshine.withOpacity(0.55), width: 1.2),
              ),
              child: Column(
                children: [
                  Text(
                    "Important Disclaimer",
                    style: GoogleFonts.orbitron(
                      color: _cSunshine,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Astro Lotto Luck is for entertainment and inspiration only. "
                        "We do not claim, guarantee, or imply that any numbers generated will win any lottery, prize, or money. "
                        "We are not affiliated with any official lottery. "
                        "Any participation in games of chance is entirely your choice and responsibility. "
                        "Please enjoy responsibly.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // big friendly back button (redundant with AppBar back, but you asked!)
            SizedBox(
              width: 240,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: Text(
                  "Back",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cMagenta.withOpacity(0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shadowColor: _cSunshine.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  final String title;
  final Widget child;
  const _CardBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF10162C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cSunshine.withOpacity(0.35), width: 1.1),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
