import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumRealmScreen extends StatelessWidget {
  const PremiumRealmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1430),
        title: const Text("🌌 Premium Realm"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(context, "🌙 Cosmic Forecast", "Find your lucky cosmic windows", "/forecast"),
          _buildCard(context, "🔮 Lucky Crystal & Charm", "Your weekly energy crystal", "/crystal"),
          _buildCard(context, "🌌 VIP Generator", "Advanced celestial number generator", "/vip"),
          _buildCard(context, "🌠 Dream → Numbers", "Turn your dreams into numbers", "/dream"),
          _buildCard(context, "🕯️ Manifestation Journal", "Write intentions, track energy", "/journal"),
          _buildCard(context, "🧘 Meditation Mode", "Align with sound before you play", "/meditation"),
          _buildCard(context, "📈 Luck Tracker", "See when your energy peaks", "/tracker"),
          _buildCard(context, "🧿 Ad-Free Cosmic Mode", "Enjoy the stars without ads", "/adfree"),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String subtitle, String route) {
    return Card(
      color: const Color(0xFF10162C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.orbitron(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.amberAccent, size: 18),
        onTap: () {
          // These routes will be added later step-by-step.
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
