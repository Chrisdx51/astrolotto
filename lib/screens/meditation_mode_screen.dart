import 'dart:async';
import 'dart:convert';
import 'dart:math';

//import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';

class MeditationModeScreen extends StatefulWidget {
  const MeditationModeScreen({super.key});

  @override
  State<MeditationModeScreen> createState() => _MeditationModeScreenState();
}

enum MedVoiceMode { breathingVisual, guidedReading }

class _MeditationModeScreenState extends State<MeditationModeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── TTS
  late FlutterTts _tts;
  bool _ttsActive = false;
  bool _queueRunning = false;
  final List<String> _ttsQueue = [];

  // ── App state
  bool _working = false;
  String _message = '';
  String _zodiac = 'Aries';
  double _progress = 0;

  // Breathing: slider controls full cycle (inhale + exhale) seconds
  int _cycleSeconds = 8; // default full cycle length (4 in + 4 out)
  String _ambientTrack = 'meditation_loop.mp3';

  // ── Audio
  //final AudioPlayer _bgPlayer = AudioPlayer();
  //final AudioPlayer _tonePlayer = AudioPlayer();
  bool _bgPlaying = false;

  // ── Mode
  MedVoiceMode _mode = MedVoiceMode.breathingVisual;

  // ── Animations
  late AnimationController _breathController; // duration = _cycleSeconds
  late AnimationController _auraController;
  late AnimationController _particleController;

  // ── Timers/streams
  Timer? _phaseTimer; // toggles inhale/exhale every half cycle
  Timer? _progressTimer;
  Timer? _statusTimer;
  http.StreamedResponse? _activeStream;
  String _partialSentence = '';

  // Cooldown
  DateTime? _lastMeditationTime;

  // UI bits
  String _breatheText = "Inhale…"; // visual only
  Color _breatheColor = const Color(0xFF43D38F); // default: calm green
  String _statusMessage = 'Preparing your inner calm…';

  // Labels + colors
  final List<String> _zodiacs = const [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  final Map<String, Color> _zodiacColors = const {
    'Aries': Color(0xFFFF6B6B),
    'Taurus': Color(0xFF43D38F),
    'Gemini': Color(0xFFFFD166),
    'Cancer': Color(0xFF58C4FF),
    'Leo': Color(0xFFFFA24E),
    'Virgo': Color(0xFFB78CFF),
    'Libra': Color(0xFFFF62B2),
    'Scorpio': Color(0xFF7A6BFF),
    'Sagittarius': Color(0xFFFFD166),
    'Capricorn': Color(0xFF43D38F),
    'Aquarius': Color(0xFF58C4FF),
    'Pisces': Color(0xFFB78CFF),
  };

  final List<String> _statusLines = const [
    'Preparing your inner calm…',
    'Crafting a personal guided meditation…',
    'Aligning mind, body, and breath…',
    'Weaving serenity into your moment…',
    'Almost ready — soften your shoulders…',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tts = FlutterTts();
    _initTts();

    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _cycleSeconds),
    )..repeat();
    _auraController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat(reverse: true);
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat();

    _loadPreferences();
    _startBreathingVisual(); // default
  }

  // ─────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _breathController.stop();
      _auraController.stop();
      _particleController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _breathController.repeat();
      _auraController.repeat(reverse: true);
      _particleController.repeat();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Prefs
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _zodiac = prefs.getString('zodiac') ?? 'Aries';
      _cycleSeconds = prefs.getInt('breathingCycleSeconds') ?? 8;
      _ambientTrack = prefs.getString('ambientTrack') ?? 'meditation_loop.mp3';
      _message = prefs.getString('lastMeditation') ?? '';
      final last = prefs.getInt('lastMeditationTime');
      if (last != null) _lastMeditationTime = DateTime.fromMillisecondsSinceEpoch(last);
    });

    // ensure controller matches stored cycle
    _updateBreathTiming(restart: true);
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('zodiac', _zodiac);
    await prefs.setInt('breathingCycleSeconds', _cycleSeconds);
    await prefs.setString('ambientTrack', _ambientTrack);
    if (_message.isNotEmpty) await prefs.setString('lastMeditation', _message);
    if (_lastMeditationTime != null) {
      await prefs.setInt('lastMeditationTime', _lastMeditationTime!.millisecondsSinceEpoch);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TTS (prefer calm British female → fallback)
  // ─────────────────────────────────────────────────────────────
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-GB');        // soft British female first
      await _tts.setSpeechRate(0.34);         // slower, more human
      await _tts.setPitch(1.02);              // subtle warmth
      await _tts.setVolume(1.0);

      try {
        final voices = await _tts.getVoices;
        if (voices != null && voices.isNotEmpty) {
          final mapped = voices.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();

          Map<String, dynamic>? chosen;

          // en-GB + female
          chosen = mapped.firstWhere(
                (v) =>
            (v['locale'] ?? '').toString().toLowerCase().startsWith('en_gb') &&
                (v['name'] ?? '').toString().toLowerCase().contains('female'),
            orElse: () => {},
          );
          // any en-GB
          chosen = chosen!.isNotEmpty
              ? chosen
              : mapped.firstWhere(
                (v) => (v['locale'] ?? '').toString().toLowerCase().startsWith('en_gb'),
            orElse: () => {},
          );
          // en-US + female
          chosen = chosen!.isNotEmpty
              ? chosen
              : mapped.firstWhere(
                (v) =>
            (v['locale'] ?? '').toString().toLowerCase().startsWith('en_us') &&
                (v['name'] ?? '').toString().toLowerCase().contains('female'),
            orElse: () => {},
          );
          // any en-US
          chosen = chosen!.isNotEmpty
              ? chosen
              : mapped.firstWhere(
                (v) => (v['locale'] ?? '').toString().toLowerCase().startsWith('en_us'),
            orElse: () => {},
          );
          // any female
          chosen = chosen!.isNotEmpty
              ? chosen
              : mapped.firstWhere(
                (v) => (v['name'] ?? '').toString().toLowerCase().contains('female'),
            orElse: () => {},
          );
          chosen = chosen!.isNotEmpty ? chosen : mapped.first;

          if (chosen != null && chosen.isNotEmpty) {
            await _tts.setVoice(Map<String, String>.from(chosen));
          }
        }
      } catch (_) {}

      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TTS init error: $e')),
      );
    }
  }

  void _enqueueSpeech(String raw) {
    final s = _sanitizeForTts(raw);
    if (s.isEmpty) return;
    _ttsQueue.add(s);
    _runQueue();
  }

  Future<void> _runQueue() async {
    if (_queueRunning) return;
    _queueRunning = true;
    try {
      while (_ttsActive && _mode == MedVoiceMode.guidedReading && _ttsQueue.isNotEmpty) {
        final next = _ttsQueue.removeAt(0);
        await _tts.speak(next);
      }
    } finally {
      _queueRunning = false;
    }
  }

  Future<void> _stopAllVoice() async {
    _ttsActive = false;
    _ttsQueue.clear();
    await _tts.stop();
    if (mounted) setState(() {});
  }

  Future<void> _replayVoice() async {
    if (_message.trim().isEmpty) return;
    await _stopAllVoice();
    _ttsActive = true;
    final parts = _splitBySentences(_sanitizeForTts(_message));
    for (final s in parts) {
      _enqueueSpeech(s);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Breathing logic
  // ─────────────────────────────────────────────────────────────
  void _startBreathingVisual() {
    _stopAllVoice(); // visual-only
    _mode = MedVoiceMode.breathingVisual;
    _breatheText = "Inhale…";
    _breatheColor = _zodiacColors[_zodiac] ?? const Color(0xFF43D38F);
    _updateBreathTiming(restart: true);
    setState(() {});
  }

  void _updateBreathTiming({bool restart = false}) {
    // Restart the controller with new duration
    _breathController.stop();
    _breathController.duration = Duration(seconds: max(4, _cycleSeconds));
    if (restart) {
      _breathController.reset();
      _breathController.repeat();
    } else {
      _breathController.repeat();
    }

    // Half-cycle timer toggles text: inhale ↔ exhale
    _phaseTimer?.cancel();
    final half = (_cycleSeconds / 2).clamp(2, 30).toDouble();
    _phaseTimer = Timer.periodic(Duration(milliseconds: (half * 1000).round()), (t) {
      if (!mounted || _mode != MedVoiceMode.breathingVisual) {
        t.cancel();
        return;
      }
      setState(() {
        _breatheText = _breatheText.startsWith('Inhale') ? 'Exhale…' : 'Inhale…';
        _breatheColor = _zodiacColors[_zodiac] ?? _breatheColor;
      });
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Hour cooldown guard
  // ─────────────────────────────────────────────────────────────
  bool _canRequestNewMeditationNow() {
    if (_lastMeditationTime == null) return true;
    final diff = DateTime.now().difference(_lastMeditationTime!);
    return diff.inMinutes >= 60;
  }

  Future<void> _showCooldownDialog() async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10162C),
        title: Text('Please check back soon', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18)),
        content: Text(
          'You can revisit in 1 hour for a fresh in-depth meditation guide.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.tealAccent, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Guided meditation flow
  // ─────────────────────────────────────────────────────────────
  Future<void> _showWaitDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF10162C),
        title: Text("Creating Your Meditation", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18)),
        content: Text(
          "Our deep-intelligence engine is carefully crafting a long guided meditation tailored to your rhythm.\n\n"
              "It studies tone, pacing, imagery and breath to create a calm session just for you. "
              "This can take a few moments — thank you for your patience.",
          style: GoogleFonts.poppins(color: Colors.white70, height: 1.5, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.tealAccent, fontSize: 16)),
          )
        ],
      ),
    );
  }

  Future<void> _onGuidedPressed() async {
    if (!_canRequestNewMeditationNow()) {
      await _showCooldownDialog();
      return;
    }

    await _showWaitDialog();

    _stopAllVoice();
    _mode = MedVoiceMode.guidedReading;
    _ttsActive = true;
    setState(() {});

    await _fetchMeditationTextStreamed(startStreamingSpeech: true);

    _lastMeditationTime = DateTime.now();
    await _savePreferences();
  }


  // ─────────────────────────────────────────────────────────────
  // Fetch (streamed) + stream-speak
  // ─────────────────────────────────────────────────────────────
  Future<void> _fetchMeditationTextStreamed({required bool startStreamingSpeech}) async {
    if (!mounted) return;

    _activeStream?.stream.drain();

    setState(() {
      _working = true;
      _message = '';
      _progress = 0;
      _partialSentence = '';
      _statusMessage = _statusLines.first;
    });

    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      final i = _statusLines.indexOf(_statusMessage);
      _statusMessage = _statusLines[(i + 1) % _statusLines.length];
      if (mounted) setState(() {});
    });

    // Smooth progress to ~92%, then glide to 100 on finish
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_progress < 92) {
        _progress += max(0.45, (92 - _progress) * 0.03);
        if (_progress > 92) _progress = 92;
        if (mounted) setState(() {});
      }
    });

    final req = http.Request(
      'POST',
      Uri.parse('https://auranaguidance.co.uk/api/meditate'),
    )
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        "prompt":
        "Write a calm, long guided meditation for zodiac $_zodiac. "
            "Use warm feminine tone, short sentences, gentle imagery, soft pauses. No lists."
      });

    try {
      final res = await req.send();
      if (res.statusCode != 200) {
        throw Exception('Status ${res.statusCode}');
      }
      _activeStream = res;

      final decoder = utf8.decoder.bind(res.stream);
      await for (final chunk in decoder) {
        if (!mounted) break;
        _message += chunk;

        _partialSentence += chunk;
        final parts = _splitBySentences(_partialSentence);
        _partialSentence = parts.isNotEmpty ? parts.removeLast() : '';

        if (startStreamingSpeech && _ttsActive && _mode == MedVoiceMode.guidedReading) {
          for (final s in parts) {
            _enqueueSpeech(s);
          }
        }
        setState(() {});
      }

      if (startStreamingSpeech && _ttsActive && _mode == MedVoiceMode.guidedReading && _partialSentence.trim().isNotEmpty) {
        _enqueueSpeech(_partialSentence.trim());
      }

      _finishLoading();
      await _savePreferences();
    } catch (e) {
      await _fallbackOffline(e.toString());
    }
  }

  List<String> _splitBySentences(String text) {
    final t = text.trim();
    if (t.isEmpty) return [];
    final parts = t.split(RegExp(r'(?<=[\.\!\?])\s+'));
    return parts;
  }

  void _finishLoading() {
    _progressTimer?.cancel();
    // glide 92 → 100 smoothly
    Timer.periodic(const Duration(milliseconds: 90), (t) {
      _progress += 2.0;
      if (_progress >= 100) {
        _progress = 100;
        t.cancel();
      }
      if (mounted) setState(() {});
    });

    _statusTimer?.cancel();
    _working = false;
    if (mounted) setState(() {});
  }

  Future<void> _fallbackOffline(String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('lastMeditation');
    _message = cached ??
        "Inhale softly. Exhale slowly. Imagine warm light around you. "
            "Let the mind rest by the shores of your breath. You are safe.";
    _finishLoading();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Using offline meditation ($reason)')),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────
  String _sanitizeForTts(String text) {
    return text
        .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), ' ')
        .replaceAll(RegExp(r'https?://\S+'), ' ')
        .replaceAll(RegExp(r'[•●►▪️🟣🔮✨🌙💫⭐️🌟]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(',', ' —')
        .replaceAll(RegExp(r'—{2,}'), '—')
        .trim();
  }

  Future<void> _toggleAmbient() async {
    if (_bgPlaying) {
     // await _bgPlayer.stop();
      _bgPlaying = false;
    } else {
      //await _bgPlayer.play(
       // AssetSource('sounds/$_ambientTrack'),
        //volume: 0.36,
     // );
     // await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      _bgPlaying = true;
    }
    if (mounted) setState(() {});
    await _savePreferences();
  }

  Future<void> _openToneSheet({
    required String title,
    required String asset,
    required String teach,
  }) async {
    // Stop any previous tone
    //await _tonePlayer.stop();

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E1533),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        bool playing = false;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    teach,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (!playing) {
                      //  await _tonePlayer.play(AssetSource('sounds/$asset'), volume: 0.6);
                      //  await _tonePlayer.setReleaseMode(ReleaseMode.loop);
                      } else {
                      //  await _tonePlayer.stop();
                      }
                      setModal(() => playing = !playing);
                    },
                    icon: Icon(playing ? Icons.stop : Icons.play_arrow, color: Colors.black),
                    label: Text(playing ? 'Stop Tone' : 'Play Tone',
                        style: GoogleFonts.poppins(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Ensure tone stops when sheet closes
    //await _tonePlayer.stop();
  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    //_bgPlayer.dispose();
   // _tonePlayer.dispose();
    _stopAllVoice();
    _progressTimer?.cancel();
    _statusTimer?.cancel();
    _phaseTimer?.cancel();
    _breathController.dispose();
    _auraController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = const Color(0xFF080B16);

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0E1431), Color(0xFF0B0F1F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Cosmic Meditation',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () {
              if (_message.trim().isNotEmpty) {
                Share.share(_message, subject: 'My Cosmic Meditation');
              } else {
                Share.share('Just tried the Cosmic Meditation in Astro Lotto Luck ✨🧘‍♀️');
              }
            },
            icon: const Icon(Icons.share, color: Colors.white),
          ),
          IconButton(
            tooltip: _bgPlaying ? 'Pause ambience' : 'Play ambience',
            onPressed: _toggleAmbient,
            icon: Icon(_bgPlaying ? Icons.music_off : Icons.music_note, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Dark cosmic gradient
          AnimatedBuilder(
            animation: _auraController,
            builder: (_, __) => _AuraBackground(t: _auraController.value),
          ),
          // Subtle shimmering stars
          _ParticleBackground(animation: _particleController),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Bigger logo
                Hero(
                  tag: 'logo',
                  child: Image.asset('assets/images/logolot.png', height: 140),
                ),
                const SizedBox(height: 16),

                // VIP info / how-to box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x1412D1C0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.tealAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Pick your zodiac and breathing pace. Tap ‘Guided Message’ for a calm, long meditation read in a soothing voice. "
                              "It’s crafted personally for you, so a short wait is normal.",
                          style: GoogleFonts.poppins(color: Colors.white70, height: 1.55, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Settings ABOVE the orb (zodiac + breathing cycle)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x1710162C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      // Zodiac picker
                      Row(
                        children: [
                          const Icon(Icons.star_rate_rounded, color: Colors.tealAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _zodiac,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0F1430),
                              iconEnabledColor: Colors.white,
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                              items: _zodiacs.map((z) => DropdownMenuItem(
                                value: z,
                                child: Text(z, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                              )).toList(),
                              onChanged: (v) {
                                setState(() {
                                  _zodiac = v!;
                                  _breatheColor = _zodiacColors[_zodiac] ?? _breatheColor;
                                });
                                _savePreferences();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Breathing cycle slider (controls full cycle)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite, color: Colors.tealAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Breathing Cycle: $_cycleSeconds s (Inhale ${_cycleSeconds ~/ 2}s / Exhale ${_cycleSeconds ~/ 2}s)',
                                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15)),
                                Slider(
                                  value: _cycleSeconds.toDouble(),
                                  min: 4, // min cycle 4s (2 in + 2 out)
                                  max: 16, // max 16s (8 + 8)
                                  divisions: 12,
                                  label: '$_cycleSeconds s',
                                  onChanged: (v) {
                                    setState(() => _cycleSeconds = v.round());
                                    _savePreferences();
                                    _updateBreathTiming(restart: true);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Four tone notes in a row (with labels), above the orb
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _toneChip(
                      '432 Hz',
                          () => _openToneSheet(
                        title: '432 Hz — Heart Harmony',
                        asset: 'tone_432.mp3',
                        teach: "432 Hz promotes deep calm and grounding. "
                            "Hum softly — a warm “mmm.”",
                      ),
                    ),
                    _toneChip(
                      '528 Hz',
                          () => _openToneSheet(
                        title: '528 Hz — Love & Renewal',
                        asset: 'tone_528.mp3',
                        teach: "528 Hz is the Love frequency — imagine a warm light expanding.",
                      ),
                    ),
                    _toneChip(
                      '639 Hz',
                          () => _openToneSheet(
                        title: '639 Hz — Connection & Clarity',
                        asset: 'tone_639.mp3',
                        teach: "639 Hz supports connection — soften throat & shoulders.",
                      ),
                    ),
                    _toneChip(
                      '741 Hz',
                          () => _openToneSheet(
                        title: '741 Hz — Intuition & Cleansing',
                        asset: 'tone_741.mp3',
                        teach: "741 Hz awakens intuition — clear mind, long hum.",
                      ),
                    ),
                  ],
                ),



                const SizedBox(height: 14),

                // Orb
                _breathingOrb(),

                const SizedBox(height: 20),

                // Loading/progress or message
                _working ? _progressSec() : _msgSec(),

                const SizedBox(height: 14),

                // Replay button (text) appears after message exists
                if (!_working && _message.trim().isNotEmpty)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: _replayVoice,
                      icon: const Icon(Icons.play_arrow, color: Colors.tealAccent),
                      label: Text(
                        'Play Again',
                        style: GoogleFonts.poppins(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Buttons: Guided + Stop side-by-side, then Breathing Mode
                Row(
                  children: [
                    Expanded(
                      child: _GlowingButton(
                        onPressed: _working ? null : _onGuidedPressed,
                        icon: const Icon(Icons.self_improvement, color: Colors.black),
                        label: 'Guided Message',
                        color: Colors.tealAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _GlowingButton(
                      onPressed: _stopAllVoice,
                      icon: const Icon(Icons.stop, color: Colors.white),
                      color: Colors.redAccent,
                      isIconOnly: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _GlowingButton(
                  onPressed: _startBreathingVisual, // starts the visual breathing exercise
                  icon: const Icon(Icons.air, color: Colors.black),
                  label: 'Breathing Mode',
                  color: const Color(0xFFFFD166),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tone chip with music note + label
  Widget _toneChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x2212D1C0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            const Icon(Icons.music_note, color: Colors.tealAccent, size: 20),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _breathingOrb() => AnimatedBuilder(
    animation: _breathController,
    builder: (_, __) {
      // 0..1 across the cycle; 0..0.5 inhale, 0.5..1 exhale
      final v = _breathController.value;
      final scale = 0.82 + (sin(v * 2 * pi) * 0.16 + 0.16);
      final glow = 0.24 + (sin(v * 2 * pi) * 0.10 + 0.10);

      final base = (_zodiacColors[_zodiac] ?? const Color(0xFF43D38F));

      return Shimmer.fromColors(
        baseColor: base.withOpacity(0.85),
        highlightColor: Colors.white.withOpacity(0.75),
        period: const Duration(seconds: 3),
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              radius: 0.86,
              colors: [
                base.withOpacity(glow * 0.8), // dimmer for readability
                const Color(0xFF0B1126),     // darker inner to pop text
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: base.withOpacity(0.30),
                blurRadius: 34,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Text(
                _breatheText,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  shadows: const [
                    Shadow(blurRadius: 8, color: Colors.black, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _progressSec() => Column(
    children: [
      Text(
        '${_progress.toInt()}%',
        style: GoogleFonts.orbitron(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        _statusMessage,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 16,
          height: 1.55,
        ),
      ),
      const SizedBox(height: 16),
      const CircularProgressIndicator(
        color: Colors.tealAccent,
        strokeWidth: 5,
      ),
    ],
  );

  Widget _msgSec() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1430),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      _message.isEmpty
          ? 'Tap “Guided Message” to receive a calm spoken meditation…'
          : _message,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: 17.5,
        height: 1.65,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Backgrounds + Buttons
// ─────────────────────────────────────────────────────────────
class _AuraBackground extends StatelessWidget {
  final double t;
  const _AuraBackground({required this.t});

  @override
  Widget build(BuildContext context) {
    final c1 = const Color(0xFF0A0F25);
    final c2 = Color.lerp(const Color(0xFF10173A), const Color(0xFF0D1838), t)!;
    final c3 = const Color(0xFF0A0E1D);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c1, c2, c3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _ParticleBackground extends StatelessWidget {
  final AnimationController animation;
  const _ParticleBackground({required this.animation});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) {
          return CustomPaint(
            painter: _ParticlePainter(animation.value),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(0);
    for (int i = 0; i < 26; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.8 + 0.6;
      final opacity = 0.08 + 0.10 * (0.5 + 0.5 * sin((x + y + t * 400) / 140));
      paint.color = Colors.white.withOpacity(opacity.clamp(0.05, 0.22));
      canvas.drawCircle(
        Offset(x, (y + (t * 45)) % size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GlowingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Icon icon;
  final String? label;
  final Color color;
  final bool isIconOnly;

  const _GlowingButton({
    required this.onPressed,
    required this.icon,
    this.label,
    required this.color,
    this.isIconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isIconOnly ? 60 : double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isIconOnly ? 14 : 16),
        boxShadow: [
          if (onPressed != null)
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: isIconOnly
            ? const SizedBox.shrink()
            : Text(
          label!,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: isIconOnly ? Colors.white : Colors.black,
          minimumSize: isIconOnly ? const Size(60, 56) : const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isIconOnly ? 14 : 16)),
          padding: EdgeInsets.symmetric(horizontal: isIconOnly ? 0 : 16),
        ),
      ),
    );
  }
}
