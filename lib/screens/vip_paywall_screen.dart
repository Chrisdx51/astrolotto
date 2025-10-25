import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VipPaywallScreen extends StatefulWidget {
  const VipPaywallScreen({super.key});

  @override
  State<VipPaywallScreen> createState() => _VipPaywallScreenState();
}

class _VipPaywallScreenState extends State<VipPaywallScreen> {
  bool _processing = false;

  Future<void> _subscribe() async {
    setState(() => _processing = true);

    // TODO (later): replace with Google Play Billing / RevenueCat / your backend
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_vip', true);

    if (!mounted) return;
    setState(() => _processing = false);

    // back to Premium Realm
    Navigator.pop(context); // close paywall
    Navigator.pushReplacementNamed(context, '/premium');
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
              onPressed: _processing ? null : _subscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF12D1C0),
                foregroundColor: const Color(0xFF0A003D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _processing ? "Activating…" : "Subscribe Now",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
