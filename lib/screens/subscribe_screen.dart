import 'dart:async'; // ✅ Needed for StreamSubscription
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

class _SubscribeScreenState extends State<SubscribeScreen> {
  final InAppPurchase _iap = InAppPurchase.instance;
  final Set<String> _productIds = {'vip-weekly', 'vip-monthly', 'vip-yearly'};
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isProcessing = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    final available = await _iap.isAvailable();
    setState(() => _isAvailable = available);

    if (!available) {
      setState(() => _statusMessage = "Store not available right now.");
      return;
    }

    // Query products
    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      setState(() => _statusMessage = "Error loading products: ${response.error}");
      return;
    }

    if (response.productDetails.isEmpty) {
      setState(() => _statusMessage = "No VIP plans found in Play Store.");
      return;
    }

    setState(() => _products = response.productDetails);

    // Listen for purchase events
    _iap.purchaseStream.listen((purchases) {
      for (var purchase in purchases) {
        _handlePurchase(purchase);
      }
    });
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased) {
      // Always complete the purchase first (Play requires it)
      try {
        await _iap.completePurchase(purchase);
      } catch (_) {
        // If completePurchase throws (rare), continue to try saving VIP anyway
      }

      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;

        if (user == null) {
          setState(() {
            _statusMessage = "Please log in before subscribing.";
            _isProcessing = false;
          });
          return;
        }

        // ✅ 1) Mark VIP in Supabase
        await supabase
            .from('profiles')
            .update({'is_vip': true})
            .eq('id', user.id);

        // ✅ 2) Save VIP locally so other screens (Generator/Wheel) see it immediately
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_vip', true);

        // ✅ 3) Update UI
        if (!mounted) return;
        setState(() {
          _statusMessage = "🌟 Welcome to the VIP Cosmic Realm!";
          _isProcessing = false;
        });

        // (Optional) Take them straight to the Premium Realm:
        // Navigator.pushReplacementNamed(context, '/premium');

      } catch (e) {
        if (!mounted) return;
        setState(() {
          _statusMessage = "Error saving VIP status: $e";
          _isProcessing = false;
        });
      }
    } else if (purchase.status == PurchaseStatus.error) {
      if (!mounted) return;
      setState(() {
        _statusMessage = "Purchase failed: ${purchase.error}";
        _isProcessing = false;
      });
    } else if (purchase.status == PurchaseStatus.restored) {
      // If you later add "Restore Purchases", success will flow here.
      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        if (user != null) {
          await supabase
              .from('profiles')
              .update({'is_vip': true})
              .eq('id', user.id);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_vip', true);
        }
        if (!mounted) return;
        setState(() {
          _statusMessage = "✅ Purchases restored. VIP active!";
          _isProcessing = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _statusMessage = "Restore error: $e";
          _isProcessing = false;
        });
      }
    }
  }

  void _buy(ProductDetails product) {
    final purchaseParam = PurchaseParam(productDetails: product);

    setState(() {
      _isProcessing = true;
      _statusMessage = "Processing your cosmic upgrade...";
    });

    // Because VIP is a subscription, NOT a one-off item:
    _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = "Restoring VIP access...";
    });

    final Stream<List<PurchaseDetails>> purchaseStream =
        _iap.purchaseStream;

    late final StreamSubscription<List<PurchaseDetails>> subscription;

    subscription = purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.productID.contains('vip') &&
            purchase.status == PurchaseStatus.purchased) {
          try {
            final supabase = Supabase.instance.client;
            final user = supabase.auth.currentUser;

            if (user != null) {
              await supabase
                  .from('profiles')
                  .update({'is_vip': true})
                  .eq('id', user.id);
            }

            await _iap.completePurchase(purchase);

            setState(() {
              _statusMessage = "✅ VIP restored — welcome back!";
              _isProcessing = false;
            });

            subscription.cancel();
            return;
          } catch (e) {
            setState(() {
              _statusMessage = "Error restoring VIP: $e";
              _isProcessing = false;
            });
          }
        }
      }

      setState(() {
        _statusMessage = "No active VIP subscription found.";
        _isProcessing = false;
      });

      subscription.cancel();
    });

    await _iap.restorePurchases();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        title: Text("Become a VIP",
            style: GoogleFonts.orbitron(color: Colors.white)),
        backgroundColor: const Color(0xFF0F1430),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logolot.png', height: 100),
              const SizedBox(height: 20),
              Text(
                "Unlock Ad-Free Cosmic Power\n+ Deep AI-Powered Predictions\n+ Access All VIP Realms",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 25),

              if (!_isAvailable)
                Text(_statusMessage, style: const TextStyle(color: Colors.red))
              else if (_products.isEmpty)
                Text("Loading VIP plans...",
                    style: GoogleFonts.poppins(color: Colors.white70))
              else
                Column(
                  children: _products.map((product) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : () => _buy(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF12D1C0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "${product.title.split('(')[0].trim()} - ${product.price}",
                          style: GoogleFonts.orbitron(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 25),
              if (_isProcessing)
                const CircularProgressIndicator(color: Colors.amberAccent),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isProcessing ? null : _restorePurchases,
                child: Text(
                  "Restore Purchases",
                  style: GoogleFonts.orbitron(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 15),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
