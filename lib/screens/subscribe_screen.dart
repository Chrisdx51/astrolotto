import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen>
    with TickerProviderStateMixin {
  final InAppPurchase _iap = InAppPurchase.instance;
  final Set<String> _productIds = {'cosmic_premium'};
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isProcessing = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  String _statusMessage = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initStore();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initStore() async {
    final available = await _iap.isAvailable();
    setState(() => _isAvailable = available);
    if (!available) {
      setState(() => _statusMessage = "Google Play unavailable");
      return;
    }

    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null || response.productDetails.isEmpty) {
      setState(() => _statusMessage = "VIP options unavailable");
      return;
    }

    setState(() => _products = response.productDetails);

    _purchaseSub = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        _handlePurchase(purchase);
      }
    });
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.error) {
      setState(() => _statusMessage = "Purchase failed");
    }

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      final token = purchase.verificationData.serverVerificationData;
      debugPrint("Purchase Token: $token");

      await _sendTokenToServer(token);

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }

      await _verifyPurchaseOnServer(purchase);
    }
  }

  Future<void> _verifyPurchaseOnServer(PurchaseDetails purchase) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final token = purchase.verificationData.serverVerificationData;
    final String offerId = purchase.productID;

    if (user == null) return;

    final res = await http.post(
      Uri.parse(
          'https://pgqnrhyaqjynxffqyjls.supabase.co/functions/v1/verify_vip_purchase'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}',
      },
      body: jsonEncode({
        "userId": user.id,
        "purchaseToken": token,
        "offerId": offerId,
      }),
    );

    print("Server verify response: ${res.body}");
    await _grantVipAccess();
  }

  Future<void> _sendTokenToServer(String token) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('profiles').update({
      'purchase_token': token,
      'is_vip': true,
      'vip_expiry': null,
    }).eq('id', user.id);

    debugPrint("Token uploaded to Supabase");
  }

  Future<void> _grantVipAccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_vip', true);

    setState(() {
      _isProcessing = false;
      _statusMessage = "VIP Activated!";
    });

    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/generator', (route) => false);
    }
  }

  void _buy(ProductDetails product) {
    setState(() {
      _isProcessing = true;
      _statusMessage = "Processing...";
    });
    final param = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = "Restoring...";
    });
    await _iap.restorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1020),
        elevation: 0,
        title: Text(
          "VIP Membership",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ---------- Animated Logo ----------
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF12D1C0).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/logolot.png',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ---------- Headline (Updated Selling Copy) ----------
            Text(
              "Unlock VIP Cosmic Power ✨",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.3,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Remove limits. Access deeper predictions. Enter exclusive realms. "
                  "Your luck deserves the VIP treatment.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                height: 1.38,
              ),
            ),
            const SizedBox(height: 26),


            // ---------- PRICING BARS (NOW AT THE TOP) ----------
            if (!_isAvailable)
              _buildErrorCard("Google Play unavailable")
            else if (_products.isEmpty)
              _buildLoadingState()
            else
              ..._products.map((p) => _buildPlanButton(p)).toList(),

            const SizedBox(height: 28),

            // ---------- VIP Benefits (now BELOW pricing) ----------
            _buildFeatureCard(
              icon: Icons.block,
              title: "No Interstitial Ads",
              subtitle:
              "Enjoy a distraction-free experience. No pop-ups or full-screen ads.",
            ),
            _buildFeatureCard(
              icon: Icons.auto_awesome,
              title: "Cosmos AI Pro Predictions",
              subtitle: "Advanced AI with deeper cosmic alignment analysis.",
            ),
            _buildFeatureCard(
              icon: Icons.lock_open,
              title: "VIP-Only Realms",
              subtitle: "Access exclusive zones and premium content.",
            ),
            _buildFeatureCard(
              icon: Icons.psychology,
              title: "Personal Lucky Insights",
              subtitle: "Daily personalized cosmic guidance.",
            ),
            _buildFeatureCard(
              icon: Icons.card_giftcard,
              title: "All Future Premium Features",
              subtitle: "Free access to every new VIP feature.",
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                "Occasional non-intrusive banner ads may appear outside VIP-only areas.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ---------- Secure Payment Badges ----------
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildTrustBadge(Icons.https, "SSL Secured"),
                _buildTrustBadge(Icons.verified, "Google Play Verified"),
                _buildTrustBadge(Icons.credit_card, "Safe Checkout"),
              ],
            ),
            const SizedBox(height: 28),

            // ---------- Restore & Status ----------
            if (_isProcessing)
              const CircularProgressIndicator(color: Color(0xFF00E5D0))
            else
              TextButton(
                onPressed: _restorePurchases,
                child: Text(
                  "Restore Purchases",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00E5D0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: GoogleFonts.poppins(
                color: _statusMessage.contains("VIP")
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helper widgets – UNCHANGED except for visual polish on plan button
  // -------------------------------------------------------------------------

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13162B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF12D1C0).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF12D1C0).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF12D1C0), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // PREMIUM COSMIC GRADIENT PLAN BUTTON (same as last version)
  Widget _buildPlanButton(ProductDetails product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A11CB), // Deep cosmic purple
            Color(0xFF2575FC), // Vibrant blue
            Color(0xFF00D4AA), // Cosmic teal
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: _isProcessing ? null : () => _buy(product),
        child: Text(
          "${product.title.split("(")[0].trim().toUpperCase()} • ${product.price}",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF13162B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(color: Color(0xFF00E5D0)),
        const SizedBox(height: 16),
        Text(
          "Connecting to Google Play...",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      ],
    );
  }
}