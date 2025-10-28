import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VipPaywallScreen extends StatelessWidget {
  const VipPaywallScreen({super.key});

  void _openSubscribe(BuildContext context) {
    Navigator.pushNamed(context, '/subscribe');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1430),
        centerTitle: true,
        title: Text(
          "🌟 VIP Membership",
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Image.asset('assets/images/logolot.png', height: 90),
          ),
          const SizedBox(height: 14),
          Text(
            "Step into the VIP Realm",
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              color: Colors.amberAccent,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Unlock deeper insights, ad-free serenity, and premium modes crafted for true cosmic seekers.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          const _VipLine(icon: Icons.nightlight_round, text: "Dream → Numbers (mystical decoding)"),
          const _VipLine(icon: Icons.auto_awesome, text: "Manifestation Journal (empowered affirmations)"),
          const _VipLine(icon: Icons.self_improvement, text: "Meditation Mode (5-min guided calm)"),
          const _VipLine(icon: Icons.crisis_alert, text: "Lucky Crystal & Charm (personal guidance)"),
          const _VipLine(icon: Icons.wb_sunny, text: "Cosmic Forecast (daily energy)"),
          const _VipLine(icon: Icons.shield, text: "Ad-Free Cosmic Mode (pure serenity)"),
          const _VipLine(icon: Icons.stars, text: "Early access to new VIP features"),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => _openSubscribe(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF12D1C0),
                foregroundColor: const Color(0xFF0A003D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                "Subscribe Now",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe later", style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }
}

class _VipLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _VipLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.amberAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
