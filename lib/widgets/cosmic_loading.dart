import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🌌 Cosmic Loading Widget (Room-aware Version)
/// Each AI room (Forecast, Dream, Crystal, etc.) shows unique loading messages.
class CosmicLoading extends StatefulWidget {
  final String room; // e.g. "forecast", "dream", "crystal"
  const CosmicLoading({super.key, required this.room});

  @override
  State<CosmicLoading> createState() => _CosmicLoadingState();
}

class _CosmicLoadingState extends State<CosmicLoading> {
  double _progress = 0;
  late Timer _timer;
  late List<String> _messages;
  String _phaseText = '';

  @override
  void initState() {
    super.initState();
    _messages = _getMessagesForRoom(widget.room);
    _phaseText = _messages.first;

    // Simulated slow progress (about 15 seconds total)
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        _progress += 1;
        if (_progress < 100) {
          _phaseText = _messages[(_progress ~/ (100 / _messages.length))
              .clamp(0, _messages.length - 1)];
        } else {
          _timer.cancel();
          _phaseText = '✨ Finalizing your cosmic insight...';
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  List<String> _getMessagesForRoom(String room) {
    switch (room.toLowerCase()) {
      case 'forecast':
        return [
          'Charting planetary movements...',
          'Measuring lunar influence...',
          'Synchronizing with your zodiac timeline...',
          'Decoding your celestial forecast...',
          'Interpreting starlight fluctuations...',
          'Preparing your cosmic report...'
        ];
      case 'dream':
        return [
          'Opening the dream realm...',
          'Scanning symbolic echoes...',
          'Unraveling hidden meanings...',
          'Mapping subconscious patterns...',
          'Aligning dream energies...',
          'Translating ethereal messages...'
        ];
      case 'crystal':
        return [
          'Attuning crystal frequencies...',
          'Detecting your energy resonance...',
          'Matching aura harmonics...',
          'Charging your crystal alignment...',
          'Balancing cosmic energy flow...',
          'Preparing your crystal insight...'
        ];
      case 'manifest':
        return [
          'Activating manifestation grid...',
          'Collecting vibrational intentions...',
          'Amplifying universal energy...',
          'Projecting your affirmations...',
          'Harmonizing quantum fields...',
          'Finalizing your manifestation message...'
        ];
      case 'meditate':
        return [
          'Centering breath with cosmic rhythm...',
          'Quieting mind frequencies...',
          'Tuning in to starlight stillness...',
          'Opening the third eye gateway...',
          'Balancing inner cosmos...',
          'Preparing your meditation guidance...'
        ];
      case 'vip':
        return [
          'Summoning elite astral codes...',
          'Activating VIP constellations...',
          'Calculating rare cosmic patterns...',
          'Aligning high-frequency numbers...',
          'Tuning energy matrix for fortune...',
          'Preparing your VIP result...'
        ];
      default:
        return [
          'Connecting to Cosmic AI...',
          'Scanning the astral map...',
          'Aligning planetary coordinates...',
          'Reading your soul vibration...',
          'Translating cosmic whispers...',
          'Finalizing universal connection...'
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing circle
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF12D1C0), Color(0xFF0A003D)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.tealAccent.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${_progress.toInt()}%',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _phaseText,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
