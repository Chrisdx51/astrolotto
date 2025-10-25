import 'dart:math';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'results_screen.dart';
import 'main.dart';
import 'cosmic_insights_screen.dart';
import 'spin_wheel_screen.dart';
import 'saved_draws_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/premium_realm_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _cTurquoise = Color(0xFF12D1C0);
const _cMagenta = Color(0xFFFF4D9A);
const _cSunshine = Color(0xFFFFD166);
const _cDeepBlue = Color(0xFF0A003D);

class _Rule {
  final int count, max;
  final int? bonusMax;
  final int bonusCount;
  const _Rule(this.count, this.max, {this.bonusMax, this.bonusCount = 0});
}

const Map<String, _Rule> _rules = {
  'EuroMillions': _Rule(5, 50, bonusMax: 12, bonusCount: 2),
  'UK Lotto': _Rule(6, 59),
  'US Powerball': _Rule(5, 69, bonusMax: 26, bonusCount: 1),
  'Irish Lotto': _Rule(6, 47),
};

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});
  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen>
    with TickerProviderStateMixin {
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  // 💎 VIP status flag
  bool _isVip = false;

// 🧿 Check VIP status directly from Supabase
  Future<void> _checkVipStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return; // Not logged in

      final response = await supabase
          .from('profiles')
          .select('is_vip')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && response['is_vip'] == true) {
        setState(() => _isVip = true);
        debugPrint('✅ VIP status confirmed from Supabase');
      } else {
        setState(() => _isVip = false);
        debugPrint('🚫 Not VIP');
      }
    } catch (e) {
      debugPrint('⚠️ VIP check failed: $e');
    }
  }



  BannerAd? _topBanner;
  BannerAd? _bottomBanner;

  final _nameCtrl = TextEditingController();
  final _townCtrl = TextEditingController();
  String _countryName = 'United Kingdom';
  String _countryEmoji = '🇬🇧';
  DateTime? _dob;
  TimeOfDay? _tob;
  String _lottery = 'EuroMillions';

  String _moonIcon = '🌙';
  String _moonLabel = 'Cosmic Phase';
  String _fortune = 'Enter your birth date to unlock your cosmic luck...';
  String? _zodiac;

  late final AnimationController _ballsAnim;
  late final AnimationController _logoAnim;
  late final Animation<double> _logoFall;
  late final Animation<double> _logoBounce;



  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
    _loadVipStatus();
    _checkVipStatus(); // 🔮 Check Supabase for VIP flag


    // Cache banners once (don’t recreate inside build)
    _topBanner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();

    _bottomBanner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();

    _ballsAnim =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _logoAnim =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _logoFall = Tween<double>(begin: -0.8, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoAnim,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _logoBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnim,
        curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _logoAnim.forward());
  }



  @override
  void dispose() {
    _ballsAnim.dispose();
    _logoAnim.dispose();
    _nameCtrl.dispose();
    _townCtrl.dispose();
    _interstitialAd?.dispose();
    _topBanner?.dispose();
    _bottomBanner?.dispose();
    super.dispose();
  }

  Future<void> _loadVipStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isVip = prefs.getBool('is_vip') ?? false;
    });
  }


  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialGenerateId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdReady = true;
        },
        onAdFailedToLoad: (error) => _isAdReady = false,
      ),
    );
  }

  void _showAdThenGoToSpinWheel() {
    InterstitialAd.load(
      adUnitId: interstitialGenerateId, // use your actual interstitial ad ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SpinWheelScreen()),
              );
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SpinWheelScreen()),
              );
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SpinWheelScreen()),
          );
        },
      ),
    );
  }


  void _showInterstitialThenNavigate(
      List<int> mainNumbers, List<int> bonusNumbers) {
    if (_isAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isAdReady = false;
          _loadInterstitialAd();
          _navigateToResults(mainNumbers, bonusNumbers);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isAdReady = false;
          _loadInterstitialAd();
          _navigateToResults(mainNumbers, bonusNumbers);
        },
      );
      _interstitialAd!.show();
    } else {
      _navigateToResults(mainNumbers, bonusNumbers);
      _loadInterstitialAd();
    }
  }


  Future<void> _navigateToResults(List<int> main, List<int> bonus) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          lottery: _lottery,
          mainNumbers: main,
          bonusNumbers: bonus,
          name: _nameCtrl.text.trim(),
          country: _countryName,
          zodiac: _zodiac ?? 'Unknown',
          moonPhase: _moonLabel,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _dob = null;
        _tob = null;
        _fortune = 'Enter your birth date to unlock your cosmic luck...';
        _moonLabel = 'Cosmic Phase';
        _zodiac = null;
        _moonIcon = '🌙';
        _lottery = 'EuroMillions';
        _countryName = 'United Kingdom';
        _countryEmoji = '🇬🇧';
        _nameCtrl.clear();
        _townCtrl.clear();
      });
    }
  }

  void _onGeneratePressed() {
    if (_nameCtrl.text.trim().isEmpty || _dob == null) {
      _snack("Please enter your full name and date of birth first.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87.withOpacity(0.85),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Padding(
          padding: EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "🔮 Aligning the Stars...",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Please enjoy this short ad while we align your cosmic chart\nand calculate your personalized lucky numbers.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: _cSunshine),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      _generateNumbers();
    });
  }

  void _generateNumbers() {
    final rule = _rules[_lottery]!;
    final seedBase =
        "${_nameCtrl.text}${_dob?.millisecondsSinceEpoch}${_lottery}${_countryName}";
    final seed = seedBase.hashCode & 0x7FFFFFFF;
    final rnd = Random(seed);

    final mainSet = <int>{};
    while (mainSet.length < rule.count) {
      mainSet.add(rnd.nextInt(rule.max) + 1);
    }
    final mainNumbers = mainSet.toList()..shuffle(rnd);

    final bonusSet = <int>{};
    if (rule.bonusCount > 0 && rule.bonusMax != null) {
      while (bonusSet.length < rule.bonusCount) {
        bonusSet.add(rnd.nextInt(rule.bonusMax!) + 1);
      }
    }
    final bonusNumbers = bonusSet.toList()..shuffle(rnd);

    final m = MoonCalc.fromDate(_dob!);
    _moonLabel =
    '${m.phaseName} • ${(m.illumination * 100).toStringAsFixed(0)}% illuminated';
    _fortune = _fortuneFromPhase(m.phaseName);
    _zodiac = _zodiacFromDate(_dob!);

    _showInterstitialThenNavigate(mainNumbers, bonusNumbers);
  }

  String _fortuneFromPhase(String p) {
    final s = p.toLowerCase();
    if (s.contains('new')) return 'A fresh cosmic beginning 🌑';
    if (s.contains('waxing crescent')) return 'Your luck is growing 🌒';
    if (s.contains('first quarter')) return 'Take bold action 🌓';
    if (s.contains('waxing gibbous')) return 'Magic builds up 🌔';
    if (s.contains('full')) return 'Your energy peaks 🌕';
    if (s.contains('waning gibbous')) return 'Share your winnings 🌖';
    if (s.contains('last quarter')) return 'Reflect wisely 🌗';
    return 'A quiet moment for cosmic renewal 🌘';
  }

  String _zodiacFromDate(DateTime d) {
    final m = d.month, day = d.day;
    if ((m == 1 && day >= 20) || (m == 2 && day <= 18)) return 'Aquarius';
    if ((m == 2 && day >= 19) || (m == 3 && day <= 20)) return 'Pisces';
    if ((m == 3 && day >= 21) || (m == 4 && day <= 19)) return 'Aries';
    if ((m == 4 && day >= 20) || (m == 5 && day <= 20)) return 'Taurus';
    if ((m == 5 && day >= 21) || (m == 6 && day <= 20)) return 'Gemini';
    if ((m == 6 && day >= 21) || (m == 7 && day <= 22)) return 'Cancer';
    if ((m == 7 && day >= 23) || (m == 8 && day <= 22)) return 'Leo';
    if ((m == 8 && day >= 23) || (m == 9 && day <= 22)) return 'Virgo';
    if ((m == 9 && day >= 23) || (m == 10 && day <= 22)) return 'Libra';
    if ((m == 10 && day >= 23) || (m == 11 && day <= 21)) return 'Scorpio';
    if ((m == 11 && day >= 22) || (m == 12 && day <= 21)) return 'Sagittarius';
    return 'Capricorn';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const _AnimatedBackground(),
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                child: Column(
                  children: [
                    if (!_isVip && _topBanner != null)
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: AdWidget(ad: _topBanner!),
                      ),

                    AnimatedBuilder(
                      animation: _logoAnim,
                      builder: (context, child) {
                        if (_logoAnim.value < 0.7) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              MediaQuery.of(context).size.height * _logoFall.value,
                            ),
                            child: _fallingLogo(),
                          );
                        } else {
                          return Transform.scale(
                            scale: 1.0 + (_logoBounce.value * 0.1),
                            child: _glowingLogo(),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'ASTRO LOTTO LUCK',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2,
                          shadows: const [
                            Shadow(
                              color: _cSunshine,
                              offset: Offset(0, 0),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _magicStrip(),
                    const SizedBox(height: 20),
                    RepaintBoundary(child: _introBox()),
                    const SizedBox(height: 25),
                    _glassInput(
                        '👤 Full Name', _nameCtrl, 'Type your full name here'),
                    _glassInput('🏠 Birthplace (optional)', _townCtrl, 'Optional'),
                    _glassPicker(
                        '🌍 Country', '$_countryEmoji $_countryName', _pickCountry),
                    _glassPicker(
                        '📅 Date of Birth',
                        _dob == null
                            ? 'Select date'
                            : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                        _pickDob),
                    _glassPicker(
                        '⏰ Time of Birth (optional)',
                        _tob == null
                            ? 'Select time'
                            : '${_tob!.hour}:${_tob!.minute.toString().padLeft(2, "0")}',
                        _pickTob),
                    _glassDropdown('🎲 Lottery', _lottery, _rules.keys.toList(),
                            (v) {
                          setState(() => _lottery = v ?? _lottery);
                        }),
                    const SizedBox(height: 30),
                    _MagicBalls(anim: _ballsAnim, currentRule: _rules[_lottery]!),
                    const SizedBox(height: 25),
                    _generateButton(),
                    const SizedBox(height: 25),
                    _featureButtons(),
                    const SizedBox(height: 25),
                    _logoutButton(),
                    const SizedBox(height: 25),
                    if (!_isVip && _bottomBanner != null)
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: AdWidget(ad: _bottomBanner!),
                      ),

                    const SizedBox(height: 25),
                    const Divider(color: Colors.white24),
                    _footerNote(),
                    const SizedBox(height: 25),
                    _shareAppTab(),
                    const SizedBox(height: 20),

                    // 🌟 VIP Upgrade Button
                    if (!_isVip) _upgradeToVipButton(),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _upgradeToVipButton() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: GestureDetector(
      onTap: _showVipPopup,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_cTurquoise, _cMagenta],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _cTurquoise.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Upgrade to VIP — Deeper Cosmic Insights Await",
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );



  Widget _fallingLogo() => Stack(
    alignment: Alignment.center,
    children: [
      ...List.generate(
        5,
            (i) => Positioned(
          top: 50.0 * i,
          child: Opacity(
            opacity: (1.0 - (i * 0.2)),
            child: Image.asset('assets/images/logolot.png',
                width: 200 - (i * 10)),
          ),
        ),
      ),
      Image.asset('assets/images/logolot.png', width: 240),
    ],
  );

  Widget _glowingLogo() => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: _cSunshine.withOpacity(0.6),
          blurRadius: 30,
          spreadRadius: 5,
        ),
        BoxShadow(
          color: _cMagenta.withOpacity(0.4),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Image.asset('assets/images/logolot.png', width: 240),
  );

  Widget _shareAppTab() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_cMagenta, _cTurquoise],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: _cMagenta.withOpacity(0.4),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    ),
    child: GestureDetector(
      onTap: _shareApp,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.share, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            "SHARE THIS APP ✨",
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ),
  );

  void _shareApp() async {
    final text =
        "🔮 Discover your COSMIC LOTTERY LUCK! Get personalized numbers from the stars! Download Astro Lotto Luck now: [App Link] ✨🌙 #AstroLottoLuck";
    await Share.share(text);
  }

  Widget _magicStrip() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_cTurquoise, _cMagenta],
        stops: [0.0, 1.0],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: _cTurquoise.withOpacity(0.3),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Row(
      children: [
        Text(_moonIcon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _fortune,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _introBox() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white30, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Text(
      "✨ To receive your personalized cosmic lottery numbers, enter your full name and birth date. Our generator uses your astrological alignment, moon phase, and energy flow at birth to reveal numbers infused with your unique celestial signature 🌙💫",
      textAlign: TextAlign.center,
      style: GoogleFonts.orbitron(
        color: Colors.white,
        fontSize: 18,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
    ),
  );

  Widget _glassInput(
      String label, TextEditingController ctrl, String hint) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white30, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextField(
              controller: ctrl,
              style: GoogleFonts.orbitron(color: Colors.black, fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle:
                GoogleFonts.orbitron(color: Colors.black54, fontSize: 16),
              ),
              enableInteractiveSelection: true,
              keyboardType: TextInputType.text,
            ),
          ),
        ],
      );

  Widget _glassPicker(String label, String value, VoidCallback onTap) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white30, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.orbitron(
                          color: Colors.black, fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down,
                      color: Colors.black54, size: 24),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _glassDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.orbitron(
                color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16)),
        const SizedBox(height: 5),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white30, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down,
                  color: Colors.black54, size: 24),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e,
                      style: GoogleFonts.orbitron(
                          color: Colors.black, fontSize: 16)),
                ),
              )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _generateButton() => SizedBox(
    width: 280,
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _cSunshine,
        foregroundColor: Colors.black,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 12,
        shadowColor: _cSunshine.withOpacity(0.5),
      ),
      onPressed: _onGeneratePressed,
      child: Text(
        'Reveal My Cosmic Lotto Numbers ✨',
        style: GoogleFonts.orbitron(
          fontWeight: FontWeight.w400,
          fontSize: 16,
          letterSpacing: 1,
        ),
      ),
    ),
  );

  Widget _featureButtons() => Column(
    children: [
      _AnimatedCosmicButton(
        label: "🔮 Daily Lucky Forecast",
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CosmicInsightsScreen())),
      ),
      _AnimatedCosmicButton(
        label: "🎡 Spin the Cosmic Wheel",
        onPressed: _showAdThenGoToSpinWheel,
      ),

      _AnimatedCosmicButton(
        label: "💎 View Saved Draws",
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const SavedDrawsScreen())),
      ),
      if (_isVip)
        _AnimatedCosmicButton(
          label: "👑 Enter VIP Realm",
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PremiumRealmScreen()),
          ),
        ),

    ],
  );

  Widget _logoutButton() => SizedBox(
    width: 180,
    child: ElevatedButton.icon(
      onPressed: () async {
        final supabase = Supabase.instance.client;
        await supabase.auth.signOut();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      icon: const Icon(Icons.logout, color: Colors.white),
      label: Text("Logout",
          style: GoogleFonts.orbitron(
              color: Colors.white, fontWeight: FontWeight.w400)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.3),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  );

  Widget _footerNote() => Text(
    "🔞 18+ • Entertainment Only • Please play responsibly 💫",
    textAlign: TextAlign.center,
    style: GoogleFonts.orbitron(
      color: Colors.white70,
      fontSize: 12,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
  );

  void _pickCountry() {
    showCountryPicker(
      context: context,
      onSelect: (c) {
        setState(() {
          _countryName = c.name;
          _countryEmoji = c.flagEmoji;
        });
      },
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 21),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _zodiac = _zodiacFromDate(picked);
      });
    }
  }

  Future<void> _pickTob() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      setState(() => _tob = picked);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

// ───────────────────────────────
// VIP UPGRADE POPUP
// ───────────────────────────────
  void _showVipPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF10162C),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amberAccent.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.amberAccent.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logolot.png', height: 80),
                    const SizedBox(height: 14),
                    Text(
                      "🌟 Unlock VIP Cosmic Access",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.orbitron(
                        color: Colors.amberAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Step deeper into the Cosmos with exclusive access powered by the advanced Cosmos AI System. "
                          "Gain personal guidance, ad-free serenity, and pages unavailable to regular users. "
                          "The stars align to create your most accurate and personalized lottery experiences ever.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 16),
                    const _VipFeature(
                        icon: Icons.auto_awesome,
                        text: "The VIP Generator — deeper, more powerful number readings using Cosmos AI."),
                    const _VipFeature(
                        icon: Icons.psychology,
                        text: "Cosmos AI Personalization — your data aligns with celestial trends for unique insights."),
                    const _VipFeature(
                        icon: Icons.self_improvement,
                        text: "Ad-Free Experience — peaceful focus during every reading."),
                    const _VipFeature(
                        icon: Icons.nightlight_round,
                        text: "Dream → Numbers, Manifestation Journal & Meditation Rooms."),
                    const _VipFeature(
                        icon: Icons.wb_sunny,
                        text: "Daily Cosmic Forecast & Lucky Crystal insights."),
                    const _VipFeature(
                        icon: Icons.star_border,
                        text: "Early access to new features & spiritual events."),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final supabase = Supabase.instance.client;
                          final prefs = await SharedPreferences.getInstance();

                          try {
                            // get current Supabase user
                            final user = supabase.auth.currentUser;
                            if (user == null) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please log in first.")),
                              );
                              return;
                            }

                            // update VIP flag in Supabase
                            await supabase
                                .from('profiles')
                                .update({'is_vip': true})
                                .eq('id', user.id);

                            // save locally
                            await prefs.setBool('is_vip', true);

                            // refresh UI
                            if (context.mounted) {
                              Navigator.pop(context); // close popup
                              setState(() => _isVip = true);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "🌟 VIP access unlocked! Welcome to the Cosmos Realm!",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.teal,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint("❌ VIP upgrade error: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Something went wrong: $e")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF12D1C0),
                          foregroundColor: const Color(0xFF0A003D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Subscribe & Unlock VIP Access ✨",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Maybe later",
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


}
// 🌙 small helper widget for popup items
class _VipFeature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _VipFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.amberAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// --------------------
/// Background (isolated)
/// --------------------
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _bgAnim;
  late final Animation<double> _bgMove;
  late final AnimationController _starsAnim;
  final List<Offset> _stars = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _bgAnim =
    AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _bgMove = CurvedAnimation(parent: _bgAnim, curve: Curves.easeInOut);

    _starsAnim =
    AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();

    // initial rough set; final layout happens in build via size
    _generateStars(50);
  }

  void _generateStars(int count) {
    _stars.clear();
    for (int i = 0; i < count; i++) {
      _stars.add(Offset(_rng.nextDouble() * 400, _rng.nextDouble() * 800));
    }
  }


  @override
  void dispose() {
    _bgAnim.dispose();
    _starsAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_bgMove, _starsAnim]),
        builder: (context, _) {
          final colors = [
            Color.lerp(_cDeepBlue, _cMagenta, _bgMove.value)!,
            Color.lerp(_cMagenta, _cTurquoise, 0.6 * _bgMove.value)!,
            Color.lerp(_cTurquoise, _cSunshine, 0.8 * (1 - _bgMove.value))!,
          ];
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
              ),
              CustomPaint(
                size: Size.infinite,
                painter: _StarPainter(_stars, _starsAnim.value),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Magic balls isolated so the rest of the form doesn’t rebuild
class _MagicBalls extends StatelessWidget {
  final AnimationController anim;
  final _Rule currentRule;
  const _MagicBalls({required this.anim, required this.currentRule});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final pulse = 1 + (anim.value * 0.08);
        final ballCount = currentRule.count + currentRule.bonusCount;
        final numbers = List.generate(ballCount, (i) => i + 1);
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            numbers.length,
                (i) => Transform.scale(
              scale: pulse,
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    _cSunshine,
                    i.isEven ? _cMagenta : _cTurquoise,
                  ]),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: (i.isEven ? _cMagenta : _cTurquoise)
                          .withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  numbers[i].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedCosmicButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _AnimatedCosmicButton({required this.label, required this.onPressed});

  @override
  State<_AnimatedCosmicButton> createState() => _AnimatedCosmicButtonState();
}

class _AnimatedCosmicButtonState extends State<_AnimatedCosmicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Transform.scale(
          scale: _pulse.value,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: 280,
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_cSunshine, _cTurquoise],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _cSunshine.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: _cTurquoise.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: GoogleFonts.orbitron(
                  color: Colors.black,
                  fontSize: 16,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<Offset> stars;
  final double animationValue;

  _StarPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);

    for (var i = 0; i < stars.length; i++) {
      // Map preset star coords into current screen size
      final s = stars[i];
      final dx = (s.dx / 400.0) * size.width;
      final dy = (s.dy / 800.0) * size.height;

      final twinkle = (sin(animationValue * pi * 4 + dx * 0.01) + 1) / 2;
      paint.color = Colors.white.withOpacity(0.3 + (twinkle * 0.5));

      canvas.drawCircle(
        Offset(dx, dy),
        2 + (twinkle * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MoonCalc {
  final String phaseName;
  final String icon;
  final double illumination;
  MoonCalc(
      {required this.phaseName, required this.icon, required this.illumination});

  static MoonCalc fromDate(DateTime date) {
    final ref = DateTime(2000, 1, 6, 18);
    final days = date.toUtc().difference(ref.toUtc()).inHours / 24.0;
    const synodic = 29.53058867;
    final phase = (days % synodic + synodic) % synodic;
    final illum = 0.5 * (1 - cos(2 * pi * phase / synodic));
    String name, emoji;
    if (phase < 1.84566) {
      name = 'New Moon';
      emoji = '🌑';
    } else if (phase < 5.53699) {
      name = 'Waxing Crescent';
      emoji = '🌒';
    } else if (phase < 9.22831) {
      name = 'First Quarter';
      emoji = '🌓';
    } else if (phase < 12.91963) {
      name = 'Waxing Gibbous';
      emoji = '🌔';
    } else if (phase < 16.61096) {
      name = 'Full Moon';
      emoji = '🌕';
    } else if (phase < 20.30228) {
      name = 'Waning Gibbous';
      emoji = '🌖';
    } else if (phase < 23.99361) {
      name = 'Last Quarter';
      emoji = '🌗';
    } else {
      name = 'Waning Crescent';
      emoji = '🌘';
    }
    return MoonCalc(
        phaseName: name, icon: emoji, illumination: illum.clamp(0, 1));
  }
}
