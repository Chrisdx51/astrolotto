import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'generator_screen.dart';

const _cTurquoise = Color(0xFF12D1C0);
const _cMagenta = Color(0xFFFF4D9A);
const _cSunshine = Color(0xFFFFD166);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _client = Supabase.instance.client;

  bool _isLoading = false;
  bool _isSignInMode = true;
  bool _showPassword = false;
  late AnimationController _anim;
  late Animation<double> _bgMove;
  late AnimationController _cardAnim;
  late Animation<double> _cardScale;
  late AnimationController _starsAnim;
  final List<Offset> _stars = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _bgMove = CurvedAnimation(parent: _anim, curve: Curves.easeInOutSine);
    _cardAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _cardScale = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut));
    _starsAnim = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _generateStars();
    _initializeConsentFlow();
  }

  void _generateStars() {
    _stars.clear();
    for (int i = 0; i < 70; i++) {
      _stars.add(Offset(_rng.nextDouble() * 400, _rng.nextDouble() * 800));
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _cardAnim.dispose();
    _starsAnim.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _initializeConsentFlow() async {
    final consentInfo = ConsentInformation.instance;
    final params = ConsentRequestParameters(tagForUnderAgeOfConsent: false);

    consentInfo.requestConsentInfoUpdate(
      params,
          () async {
        try {
          final available = await consentInfo.isConsentFormAvailable();
          if (available) {
            ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
              if (error != null) {
                debugPrint("⚠️ Auto form error: ${error.message}");
              } else {
                debugPrint("✅ Consent form handled on init.");
              }
            });
          } else {
            debugPrint("✅ No consent form required right now.");
          }
        } catch (e) {
          debugPrint("⚠️ isConsentFormAvailable() failed: $e");
        }
      },
          (FormError error) {
        debugPrint("⚠️ requestConsentInfoUpdate failed: ${error.message}");
      },
    );
  }

  Future<void> _showConsentForm() async {
    final consentInfo = ConsentInformation.instance;
    final params = ConsentRequestParameters(tagForUnderAgeOfConsent: false);

    debugPrint("🌀 User tapped Manage Consent...");

    consentInfo.requestConsentInfoUpdate(
      params,
          () async {
        try {
          final available = await consentInfo.isConsentFormAvailable();
          if (available) {
            ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
              if (error != null) {
                debugPrint("⚠️ Consent form error: ${error.message}");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Consent form error: ${error.message}",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    backgroundColor: _cMagenta.withOpacity(0.8),
                  ),
                );
              } else {
                debugPrint("✅ Consent form displayed successfully.");
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "No consent changes available right now.",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                backgroundColor: _cMagenta.withOpacity(0.8),
              ),
            );
          }
        } catch (e) {
          debugPrint("❌ isConsentFormAvailable() failed: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Consent check failed: $e",
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
              backgroundColor: _cMagenta.withOpacity(0.8),
            ),
          );
        }
      },
          (FormError error) {
        debugPrint("⚠️ requestConsentInfoUpdate failed: ${error.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Consent update failed: ${error.message}",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            backgroundColor: _cMagenta.withOpacity(0.8),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _password.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _snack('Please enter email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignInMode) {
        await _client.auth.signInWithPassword(email: email, password: pass);
      } else {
        final res = await _client.auth.signUp(email: email, password: pass);
        if (res.session == null) {
          _snack('Account created! Check your email to confirm, then sign in.');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.of(context).pushReplacement(_fadeTo(const GeneratorScreen()));
      }
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: GoogleFonts.orbitron(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      backgroundColor: _cMagenta.withOpacity(0.8),
    ),
  );

  PageRouteBuilder _fadeTo(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgMove,
      builder: (context, child) {
        final colors = [
          Color.lerp(_cTurquoise, _cMagenta, _bgMove.value)!,
          Color.lerp(_cMagenta, _cSunshine, 0.5 + 0.4 * _bgMove.value)!,
        ];
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          body: Stack(
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
              AnimatedBuilder(
                animation: _starsAnim,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: StarPainter(_stars, _starsAnim.value),
                  );
                },
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: ScaleTransition(
                        scale: _cardScale,
                        child: _authCard(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _authCard() => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _cSunshine.withOpacity(0.5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _cSunshine.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: _cMagenta.withOpacity(0.2),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logolot.png', width: 220, height: 150, fit: BoxFit.contain),
              const SizedBox(height: 10),
              Text(
                '✨ Astro Lotto Luck',
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(color: _cSunshine.withOpacity(0.5), blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignInMode ? 'Welcome back, cosmic dreamer' : 'Create your star-bound account',
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white70,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 22),
              _RoundedField(
                controller: _email,
                hint: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 16),
              _RoundedField(
                controller: _password,
                hint: 'Password',
                obscure: !_showPassword,
                icon: Icons.lock_outline,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                suffix: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Switch(
                    value: _isSignInMode,
                    onChanged: (v) => setState(() => _isSignInMode = v),
                    activeColor: _cSunshine,
                    inactiveThumbColor: _cMagenta,
                  ),
                  Text(
                    _isSignInMode ? 'Sign in' : 'Sign up',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: AnimatedBuilder(
                  animation: _starsAnim,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        if (_isLoading)
                          CustomPaint(
                            size: Size.infinite,
                            painter: SparklePainter(_starsAnim.value),
                          ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cSunshine,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                            shadowColor: _cSunshine.withOpacity(0.5),
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation(Colors.black),
                            ),
                          )
                              : Text(
                            _isSignInMode ? 'Enter Your Luck' : 'Join the Stars',
                            style: GoogleFonts.orbitron(
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.privacy_tip_outlined, color: Colors.white70, size: 18),
                  label: Text(
                    'Manage Consent',
                    style: GoogleFonts.orbitron(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _cSunshine.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                  onPressed: _showConsentForm,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '18+ only • Play responsibly',
                style: GoogleFonts.orbitron(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _RoundedField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    List<String>? autofillHints,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.18), Colors.white.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cSunshine.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: _cSunshine.withOpacity(0.2), blurRadius: 8, spreadRadius: 1),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w400),
            autofillHints: autofillHints,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
              hintText: hint,
              hintStyle: GoogleFonts.orbitron(color: Colors.white70, fontWeight: FontWeight.w400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              suffixIcon: suffix,
            ),
          ),
        ),
      ),
    );
  }
}

class StarPainter extends CustomPainter {
  final List<Offset> stars;
  final double animationValue;

  StarPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);
    for (var star in stars) {
      final twinkle = (sin(animationValue * pi * 4 + star.dx) + 1) / 2;
      paint.color = Colors.white.withOpacity(0.3 + (twinkle * 0.5));
      canvas.drawCircle(star, 2 + (twinkle * 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SparklePainter extends CustomPainter {
  final double animationValue;

  SparklePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _cSunshine.withOpacity(0.7);
    final random = Random(animationValue.hashCode);
    for (int i = 0; i < 10; i++) {
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      final radius = 1 + random.nextDouble() * 3;
      paint.color = _cSunshine.withOpacity(0.4 + (sin(animationValue * pi * 2 + i) + 1) / 2 * 0.3);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}