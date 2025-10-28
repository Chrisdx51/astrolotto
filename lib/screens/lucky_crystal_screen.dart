import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/astro_service.dart';
import '../main.dart'; // for BannerAdWidget

const _cDeepBlue = Color(0xFF0A003D);
const _cSunshine = Color(0xFFFFD166);

class LuckyCrystalScreen extends StatefulWidget {
  final String? name;
  final DateTime? dob;
  final bool isPremium;
  const LuckyCrystalScreen({super.key, this.name, this.dob, this.isPremium = true});

  @override
  State<LuckyCrystalScreen> createState() => _LuckyCrystalScreenState();
}

class _LuckyCrystalScreenState extends State<LuckyCrystalScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDob;
  String _sign = '';
  String _zodiacSource = '';
  String _crystal = '';
  String _meaning = '';
  String _charm = '';
  String _charmMeaning = '';
  String _birthstone = '';
  String _birthstoneMeaning = '';
  List<int> _luckyNumbers = [];
  String _aiMessage = '';
  bool _loading = true;
  double _progress = 0;
  Timer? _progressTimer;
  Timer? _messageTimer;
  String _statusMessage = 'Preparing your crystal energy...';
  late AnimationController _glowController;

  final List<String> _guidanceMessages = [
    'Amethyst vibrates with spiritual clarity, guiding your intuition.',
    'Place Aquamarine near water to amplify emotional flow.',
    'Citrine radiates abundance; keep it in your workspace for prosperity.',
    'Wear Rose Quartz to invite love and harmony into your heart.',
    'Obsidian shields your energy; carry it during challenging times.',
    'Lapis Lazuli enhances wisdom; meditate with it for insight.',
    'Carnelian boosts courage; hold it when facing bold decisions.',
    'Green Aventurine attracts luck; place it in your pocket daily.',
    'Tiger’s Eye sharpens focus; use it during goal-setting rituals.',
    'Smoky Quartz grounds ambitions; keep it near your desk.',
    'Moonstone aligns with lunar energy; wear it under moonlight.',
    'Amazonite balances emotions; hold it during stressful moments.',
    'Cleanse your crystals under running water to renew their energy.',
    'Charge your crystals in moonlight for deeper cosmic connection.',
    'Place Citrine in sunlight to amplify its vibrant energy.',
    'Meditate with Amethyst to deepen your spiritual practice.',
    'Carry Rose Quartz to foster self-love and compassion.',
    'Use Obsidian for protection during energy-clearing rituals.',
    'Lapis Lazuli aids communication; keep it near during conversations.',
    'Carnelian sparks creativity; place it in your creative space.',
    'Green Aventurine supports growth; use it in manifestation rituals.',
    'Tiger’s Eye enhances confidence; wear it during presentations.',
    'Smoky Quartz clears negativity; place it in your living space.',
    'Moonstone connects to intuition; meditate with it at dusk.',
    'Amazonite soothes the mind; hold it during meditation.',
    'Combine crystals for amplified energy; try Amethyst and Citrine.',
    'Cleanse crystals with sage smoke for spiritual purification.',
    'Charge Rose Quartz in rosewater for enhanced love energy.',
    'Obsidian reflects truth; use it for shadow work.',
    'Lapis Lazuli opens the third eye; meditate with it nightly.',
    'Carnelian ignites passion; keep it close during projects.',
    'Green Aventurine invites opportunity; carry it on new ventures.',
    'Tiger’s Eye promotes clarity; use it during decision-making.',
    'Smoky Quartz stabilizes energy; place it at your home’s entrance.',
    'Moonstone enhances dreams; keep it under your pillow.',
    'Amazonite fosters harmony; wear it during conflicts.',
    'Crystals amplify intentions; set a clear goal before using them.',
    'Cleanse your crystals regularly to maintain their potency.',
    'Charge crystals under a full moon for maximum alignment.',
    'Citrine attracts wealth; place it in your wallet or cash drawer.',
    'Rose Quartz heals emotional wounds; carry it during tough times.',
    'Obsidian grounds energy; use it during grounding meditations.',
    'Lapis Lazuli inspires truth; wear it when seeking honesty.',
    'Carnelian fuels motivation; keep it near during workouts.',
    'Green Aventurine brings peace; place it in your bedroom.',
    'Tiger’s Eye protects ambition; carry it during challenges.',
    'Smoky Quartz dispels fear; meditate with it for courage.',
    'Moonstone channels lunar wisdom; use it during new moons.',
  ];

  final List<Color> _crystalColors = [
    Colors.purpleAccent, // Amethyst
    Colors.cyanAccent, // Aquamarine
    Colors.amberAccent, // Citrine
    Colors.pinkAccent, // Rose Quartz
    Colors.black54, // Obsidian
    Colors.blueAccent, // Lapis Lazuli
    Colors.orangeAccent, // Carnelian
    Colors.greenAccent, // Green Aventurine
    Colors.brown.shade300, // Tiger’s Eye
    Colors.grey.shade600, // Smoky Quartz
    Colors.white70, // Moonstone
    Colors.tealAccent, // Amazonite
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _rotateMessages();
    if (widget.dob != null && widget.name != null) {
      _selectedDob = widget.dob;
      _setupInfo();
    }
  }

  void _rotateMessages() {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() {
        final i = _guidanceMessages.indexOf(_statusMessage);
        _statusMessage = _guidanceMessages[(i + 1) % _guidanceMessages.length];
      });
    });
  }

  Future<void> _setupInfo() async {
    setState(() => _loading = true);

    if (widget.dob != null || _selectedDob != null) {
      final dob = widget.dob ?? _selectedDob!;
      _sign = AstroService.getZodiacSign(dob);
      _zodiacSource = 'Your Zodiac Sign';
      _birthstone = _getBirthstone(dob.month);
      _birthstoneMeaning = _getBirthstoneMeaning(dob.month);
    } else {
      _sign = AstroService.getZodiacSign(DateTime.now());
      _zodiacSource = 'Current Zodiac Cycle';
      _birthstone = 'Not available';
      _birthstoneMeaning = 'Select your birth date to discover your birthstone.';
    }

    final _data = _crystalData[_sign] ?? _crystalData['Pisces']!;
    _crystal = _data['crystal']!;
    _meaning = _data['meaning']!;
    _charm = _data['charm']!;
    _charmMeaning = _data['charmMeaning']!;
    _luckyNumbers = _data['lucky']!;

    _progressTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      setState(() {
        if (_progress < 90) _progress += 4;
      });
    });

    try {
      final uri = Uri.parse('https://auranaguidance.co.uk/api/crystal');
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'prompt':
          'Write a magical, inspiring message for the zodiac sign $_sign. '
              'Mention the lucky crystal $_crystal and birthstone $_birthstone. '
              'Keep it short, poetic, and positive — 3 to 5 sentences.'
        });

      debugPrint('🔮 STREAMING → $uri');

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        throw Exception("HTTP ${streamedResponse.statusCode}");
      }

      final buffer = <int>[];

      streamedResponse.stream.listen((chunk) {
        buffer.addAll(chunk);
        final text = utf8.decode(buffer, allowMalformed: true);

        if (!mounted) return;
        setState(() => _aiMessage = text.trim());
      }, onDone: () {
        if (!mounted) return;
        _progressTimer?.cancel();
        setState(() {
          _progress = 100;
          _loading = false;
        });
      }, onError: (_) {
        _fallbackCrystal();
      });
    } catch (_) {
      _fallbackCrystal();
    }
  }

  void _fallbackCrystal() {
    if (!mounted) return;
    _progressTimer?.cancel();
    setState(() {
      _aiMessage =
      '✨ Crystal guidance is delayed. Trust your intuition for now.';
      _progress = 100;
      _loading = false;
    });
  }


  String _getBirthstone(int month) {
    const birthstones = {
      1: 'Garnet',
      2: 'Amethyst',
      3: 'Aquamarine',
      4: 'Diamond',
      5: 'Emerald',
      6: 'Pearl',
      7: 'Ruby',
      8: 'Peridot',
      9: 'Sapphire',
      10: 'Opal',
      11: 'Topaz',
      12: 'Turquoise',
    };
    return birthstones[month] ?? 'Unknown';
  }

  String _getBirthstoneMeaning(int month) {
    const meanings = {
      1: 'Garnet promotes vitality and strength, grounding your intentions.',
      2: 'Amethyst enhances spiritual clarity and inner peace.',
      3: 'Aquamarine fosters calm and emotional balance.',
      4: 'Diamond amplifies energy and brings clarity to your goals.',
      5: 'Emerald encourages growth, love, and prosperity.',
      6: 'Pearl nurtures purity and emotional harmony.',
      7: 'Ruby ignites passion and protects your energy.',
      8: 'Peridot attracts abundance and positive energy.',
      9: 'Sapphire enhances wisdom and mental clarity.',
      10: 'Opal sparks creativity and emotional depth.',
      11: 'Topaz promotes confidence and goal achievement.',
      12: 'Turquoise protects and aligns with cosmic energy.',
    };
    return meanings[month] ?? 'Select your birth date for a personalized meaning.';
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

  Future<void> _saveInsight() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_crystal_insights') ?? [];
    saved.add('$_sign — $_crystal, $_birthstone\n$_aiMessage');
    await prefs.setStringList('saved_crystal_insights', saved);
    _toast('Saved to your Crystal Journal 💎');
  }

  void _shareInsight() {
    Share.share('💎 $_sign\'s Lucky Crystal: $_crystal, Birthstone: $_birthstone\n\n$_aiMessage\n#AuranaApp');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF10162C),
              onSurface: Colors.white70,
            ),
            dialogBackgroundColor: const Color(0xFF0A003D),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.amberAccent,
                textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            textTheme: TextTheme(
              bodyMedium: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _messageTimer?.cancel();
    _glowController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cDeepBlue,
      appBar: AppBar(
        backgroundColor: _cDeepBlue,
        centerTitle: true,
        title: Text(
          'Lucky Crystal & Charm',
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
              colors: [Colors.blue.shade900, _cDeepBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.isPremium
          ? null
          : const Padding(
        padding: EdgeInsets.only(bottom: 4),
        child: BannerAdWidget(),
      ),
      body: Stack(
        children: [
          const _AuroraBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/logolot.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                _instructionBox(),
                const SizedBox(height: 20),
                Text(
                  DateFormat('EEEE, d MMM').format(DateTime.now()),
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_sign — $_zodiacSource',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.dob == null) _inputSection(),
                const SizedBox(height: 20),
                _crystalCard('💎 Your Crystal', _crystal, _meaning),
                _crystalCard('🌟 Your Birthstone', _birthstone, _birthstoneMeaning),
                _crystalCard('🧿 Your Lucky Charm', _charm, _charmMeaning),
                _numbersCard(),
                _insightCard(),
                const SizedBox(height: 30),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.auto_awesome, color: Colors.white),
                    label: Text(
                      'Back to Cosmic Realm',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                      shadowColor: Colors.blueAccent.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionBox() => Container(
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
          'Embark on Your Crystal Journey',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your name and select your birth date to unlock personalized cosmic insights. Our celestial AI will reveal your lucky crystal, birthstone, and charm, along with a mystical message to guide your path. Stay on this page as the universe aligns your energies — it may take up to 5 minutes. Use the Share and Save buttons to capture your insights.',
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
  ).animate().fadeIn(duration: 800.ms);

  Widget _inputSection() => Container(
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
          'Personalize Your Cosmic Journey',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDob == null
                      ? 'Select your birth date'
                      : DateFormat('yyyy-MM-dd').format(_selectedDob!),
                  style: GoogleFonts.poppins(
                    color: _selectedDob == null ? Colors.white38 : Colors.white,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              if (_nameController.text.isEmpty || _selectedDob == null) {
                _toast('Please enter your name and select a birth date');
                return;
              }
              _setupInfo();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: Text(
              'Discover Your Crystals',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _crystalCard(String title, String value, String meaning) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF10162C), _cDeepBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.blueAccent.withOpacity(0.25)),
      boxShadow: [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.15),
          blurRadius: 15,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.orbitron(
            color: Colors.blueAccent,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          meaning,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms),
  );

  Widget _numbersCard() => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.blueAccent.withOpacity(0.25)),
      boxShadow: [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.1),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          '🔢 Lucky Numbers',
          style: GoogleFonts.orbitron(
            color: Colors.amberAccent,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _luckyNumbers
              .map((n) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _cSunshine.withOpacity(0.9),
                  Colors.orangeAccent.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              '$n',
              style: GoogleFonts.orbitron(
                color: _cDeepBlue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ))
              .toList(),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms),
  );

  Widget _insightCard() => Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF151A2D),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.blueAccent.withOpacity(0.25)),
      boxShadow: [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.2),
          blurRadius: 16,
          spreadRadius: 3,
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
          'Cosmic Crystal Insight',
          style: GoogleFonts.orbitron(
            color: Colors.blueAccent,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, _) {
                    final colorIndex = (_progress ~/ _crystalColors.length) % _crystalColors.length;
                    return LinearProgressIndicator(
                      value: _progress / 100,
                      color: _crystalColors[colorIndex],
                      backgroundColor: Colors.white12,
                      minHeight: 8,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
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
          )
        else
          Column(
            children: [
              Text(
                _aiMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconButton(
                    icon: Icons.share,
                    tooltip: 'Share Insight',
                    onTap: _shareInsight,
                  ),
                  const SizedBox(width: 16),
                  _iconButton(
                    icon: Icons.bookmark_add,
                    tooltip: 'Save Insight',
                    onTap: _saveInsight,
                  ),
                ],
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

class _AuroraBackground extends StatefulWidget {
  const _AuroraBackground();

  @override
  State<_AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<_AuroraBackground>
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
      builder: (context, _) {
        return CustomPaint(
          painter: _AuroraPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double progress;
  _AuroraPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: [
        Colors.blueAccent.withOpacity(0.08 + progress * 0.12),
        Colors.purpleAccent.withOpacity(0.07),
        Colors.transparent,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

final Map<String, Map<String, dynamic>> _crystalData = {
  'Aries': {
    'crystal': 'Carnelian',
    'meaning': 'Boosts courage and brings swift victories.',
    'charm': 'Copper Coin',
    'charmMeaning': 'Attracts quick rewards and confidence.',
    'lucky': [1, 9, 19]
  },
  'Taurus': {
    'crystal': 'Green Aventurine',
    'meaning': 'Steady growth and grounded luck.',
    'charm': 'Leaf Charm',
    'charmMeaning': 'Symbol of prosperity through patience.',
    'lucky': [2, 6, 24]
  },
  'Gemini': {
    'crystal': 'Citrine',
    'meaning': 'Radiates optimism and creative energy.',
    'charm': 'Feather',
    'charmMeaning': 'Brings adaptability and positive surprises.',
    'lucky': [3, 5, 14]
  },
  'Cancer': {
    'crystal': 'Moonstone',
    'meaning': 'Awakens intuition and emotional clarity.',
    'charm': 'Shell',
    'charmMeaning': 'Protects while guiding toward fortune.',
    'lucky': [2, 7, 20]
  },
  'Leo': {
    'crystal': 'Tiger’s Eye',
    'meaning': 'Inspires courage and decisive power.',
    'charm': 'Sun Charm',
    'charmMeaning': 'Radiates energy and ambition.',
    'lucky': [1, 10, 28]
  },
  'Virgo': {
    'crystal': 'Amazonite',
    'meaning': 'Brings harmony and balance to actions.',
    'charm': 'Key',
    'charmMeaning': 'Unlocks clarity and precision.',
    'lucky': [5, 14, 23]
  },
  'Libra': {
    'crystal': 'Rose Quartz',
    'meaning': 'Encourages peace and emotional healing.',
    'charm': 'Scales',
    'charmMeaning': 'Draws balance and love.',
    'lucky': [6, 15, 24]
  },
  'Scorpio': {
    'crystal': 'Obsidian',
    'meaning': 'Shields energy and reveals hidden luck.',
    'charm': 'Arrowhead',
    'charmMeaning': 'Focuses determination toward success.',
    'lucky': [8, 18, 27]
  },
  'Sagittarius': {
    'crystal': 'Lapis Lazuli',
    'meaning': 'Inspires wisdom and clear direction.',
    'charm': 'Compass',
    'charmMeaning': 'Guides adventures into golden paths.',
    'lucky': [3, 12, 30]
  },
  'Capricorn': {
    'crystal': 'Smoky Quartz',
    'meaning': 'Grounds ambitions and manifests goals.',
    'charm': 'Mountain',
    'charmMeaning': 'Represents persistence and reward.',
    'lucky': [8, 17, 26]
  },
  'Aquarius': {
    'crystal': 'Amethyst',
    'meaning': 'Enhances intuition and creative insight.',
    'charm': 'Star',
    'charmMeaning': 'Signals alignment with destiny.',
    'lucky': [4, 11, 22]
  },
  'Pisces': {
    'crystal': 'Aquamarine',
    'meaning': 'Brings calm, clarity, and emotional flow.',
    'charm': 'Fish Charm',
    'charmMeaning': 'Encourages luck through faith and surrender.',
    'lucky': [7, 16, 25]
  },
};