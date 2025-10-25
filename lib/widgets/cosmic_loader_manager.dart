import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🌌 Cosmic Loader Manager
/// Shows a full-screen overlay with percentage + themed text while AI runs.
class CosmicLoader {
  static OverlayEntry? _overlayEntry;
  static double _progress = 0;
  static Timer? _timer;

  static void show(BuildContext context, {String room = 'default'}) {
    if (_overlayEntry != null) return; // Already visible

    _progress = 0;
    _overlayEntry = OverlayEntry(
      builder: (context) => _CosmicOverlay(room: room),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Animate fake progress slowly toward 100
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      _progress += 1;
      if (_progress >= 100) _progress = 99; // stop just before 100
      _overlayEntry?.markNeedsBuild();
    });
  }

  static void hide() {
    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// Internal overlay widget
class _CosmicOverlay extends StatefulWidget {
  final String room;
  const _CosmicOverlay({required this.room});

  @override
  State<_CosmicOverlay> createState() => _CosmicOverlayState();
}

class _CosmicOverlayState extends State<_CosmicOverlay> {
  String get _phaseText {
    final msgs = _messagesForRoom(widget.room);
    final index = (CosmicLoader._progress ~/ (100 / msgs.length))
        .clamp(0, msgs.length - 1);
    return msgs[index];
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.9),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // circular bar
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: CosmicLoader._progress / 100,
                      strokeWidth: 6,
                      color: const Color(0xFF12D1C0),
                      backgroundColor: Colors.white12,
                    ),
                  ),
                  Text(
                    '${CosmicLoader._progress.toInt()}%',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _phaseText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _messagesForRoom(String room) {
    switch (room.toLowerCase()) {
      case 'forecast':
        return [
          'Charting planetary movements...',
          'Measuring lunar influence...',
          'Synchronizing with your zodiac timeline...',
          'Interpreting starlight fluctuations...',
          'Preparing your forecast report...'
        ];
      case 'dream':
        return [
          'Opening the dream realm...',
          'Scanning symbolic echoes...',
          'Unraveling hidden meanings...',
          'Aligning dream energies...',
          'Decoding ethereal messages...'
        ];
      case 'crystal':
        return [
          'Attuning crystal frequencies...',
          'Balancing aura harmonics...',
          'Charging your crystal alignment...',
          'Finalizing your crystal reading...'
        ];
      case 'manifest':
        return [
          'Activating manifestation grid...',
          'Collecting vibrational intentions...',
          'Projecting your affirmations...',
          'Harmonizing quantum fields...',
          'Finalizing manifestation message...'
        ];
      case 'vip':
        return [
          'Summoning elite astral codes...',
          'Activating VIP constellations...',
          'Calculating rare cosmic patterns...',
          'Aligning high-frequency numbers...',
          'Preparing your VIP fortune...'
        ];
      default:
        return [
          'Connecting to Cosmic AI...',
          'Scanning the astral map...',
          'Aligning planetary coordinates...',
          'Reading your soul vibration...',
          'Finalizing universal connection...'
        ];
    }
  }
}
