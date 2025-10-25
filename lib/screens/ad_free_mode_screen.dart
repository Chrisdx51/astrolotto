import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;

import '../widgets/cosmic_loading.dart';

class AdFreeModeScreen extends StatefulWidget {
  const AdFreeModeScreen({super.key});

  @override
  State<AdFreeModeScreen> createState() => _AdFreeModeScreenState();
}

class _AdFreeModeScreenState extends State<AdFreeModeScreen> {
  bool _working = false;
  String _affirmation = "✨ Your ad-free cosmic peace is activating...";
  final String _defaultZodiac = "Leo"; // fallback zodiac for demo use

  @override
  void initState() {
    super.initState();
    _fetchAffirmation();
  }

  // 🌌 Correct AI connection using {prompt} and expecting {result}
  Future<void> _fetchAffirmation() async {
    setState(() => _working = true);

    final prompt =
        "Write a gentle cosmic affirmation for a person with the zodiac sign $_defaultZodiac. "
        "It should be about serenity, freedom from distractions, and inner balance.";

    try {
      final uri = Uri.parse('https://auranaguidance.co.uk/api/adfreemode');
      debugPrint("🔮 [CosmosAI] POST $uri");
      debugPrint("🪐 [Prompt] $prompt");

      final res = await http
          .post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": prompt}),
      )
          .timeout(const Duration(seconds: 25));

      debugPrint("⭐ [CosmosAI] status: ${res.statusCode}");
      debugPrint("📦 [CosmosAI] body: ${res.body}");

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        final aiResult = decoded['result']?.toString().trim();

        if (aiResult != null && aiResult.isNotEmpty) {
          setState(() => _affirmation = aiResult);
        } else {
          _fallbackAffirmation();
        }
      } else {
        _fallbackAffirmation();
      }
    } on TimeoutException {
      debugPrint("⏳ [CosmosAI] Timeout — fallback triggered");
      _fallbackAffirmation(custom:
      "The cosmos is taking its time to respond... breathe deeply, you are already aligned with peace.");
    } catch (e) {
      debugPrint("❌ [CosmosAI] Error: $e");
      _fallbackAffirmation();
    } finally {
      setState(() => _working = false);
    }
  }

  void _fallbackAffirmation({String? custom}) {
    setState(() {
      _affirmation = custom ??
          "🌙 The stars are quiet tonight, but your calm remains unshaken. "
              "Every breath draws you closer to celestial peace.";
    });
  }

  void _copyAffirmation() {
    Clipboard.setData(ClipboardData(text: _affirmation));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Affirmation copied ✨"),
        backgroundColor: Colors.deepPurpleAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ────────────────────────────── UI ──────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_working) return const CosmicLoading(room: "affirm");

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1430),
        centerTitle: true,
        title: Text(
          "🧿 Ad-Free Cosmic Mode",
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          const _AffirmationBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✨ Logo
                  Image.asset(
                    'assets/images/logolot.png',
                    height: 90,
                  ).animate().fadeIn(duration: 700.ms).move(
                    begin: const Offset(0, 30),
                    end: const Offset(0, 0),
                  ),

                  const SizedBox(height: 20),

                  // 🌌 Intro Text
                  Text(
                    "Welcome to your ad-free sanctuary 🌌",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: .2, end: 0),

                  const SizedBox(height: 30),

                  // 💫 Affirmation Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151A2D).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.tealAccent.withOpacity(0.12),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      _affirmation,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.amberAccent,
                        fontSize: 17,
                        height: 1.6,
                      ),
                    ),
                  ).animate().fadeIn(duration: 900.ms).move(
                    begin: const Offset(0, 20),
                    end: const Offset(0, 0),
                  ),

                  const SizedBox(height: 40),

                  // 🌠 Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _fetchAffirmation,
                        icon: const Icon(Icons.refresh),
                        label: const Text("New Affirmation"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF12D1C0),
                          foregroundColor: const Color(0xFF0A003D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _copyAffirmation,
                        icon: const Icon(Icons.copy, color: Colors.white70),
                        label: const Text(
                          "Copy",
                          style: TextStyle(color: Colors.white70),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🌌 Pulsing background animation
class _AffirmationBackground extends StatefulWidget {
  const _AffirmationBackground();

  @override
  State<_AffirmationBackground> createState() => _AffirmationBackgroundState();
}

class _AffirmationBackgroundState extends State<_AffirmationBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
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
      builder: (_, __) {
        final t = _controller.value * 2 * pi;
        final glow1 = 0.12 + 0.05 * sin(t);
        final glow2 = 0.08 + 0.04 * cos(t);
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.4,
              colors: [
                const Color(0xFF12D1C0).withOpacity(glow1),
                const Color(0xFFFFD166).withOpacity(glow2),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
