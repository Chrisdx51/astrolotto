import UIKit
import Flutter
import FirebaseCore
import GoogleMobileAds

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  var flutterEngine: FlutterEngine?
  var debugLabel: UILabel?

  override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 🧩 STEP 1: Show temporary on-screen debug label (before Flutter)
    setupDebugLabel(text: "🟣 Starting Astro Lotto Luck...")
    print("🟣 [INIT] AppDelegate starting...")

    // 🧩 STEP 2: Firebase init (safe)
    if FirebaseApp.app() == nil {
      if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
      let options = FirebaseOptions(contentsOfFile: path) {
        FirebaseApp.configure(options: options)
        updateDebugLabel("✅ Firebase initialized OK")
        print("✅ [INIT] Firebase configured successfully.")
      } else {
        updateDebugLabel("❌ Firebase plist missing!")
        print("❌ [ERROR] GoogleService-Info.plist not found.")
      }
    }

    // 🧩 STEP 3: Create and run Flutter engine
    flutterEngine = FlutterEngine(name: "AstroLottoEngine")
    flutterEngine?.run(withEntrypoint: "main_ios")
    print("⚙️ [ENGINE] FlutterEngine created, running main_ios...")

    if let engine = flutterEngine {
      GeneratedPluginRegistrant.register(with: engine)
      print("✅ [PLUGIN] Plugins registered successfully.")
    } else {
      updateDebugLabel("❌ Flutter engine failed.")
      print("❌ [ERROR] Flutter engine failed to start.")
      return false
    }

    // 🧩 STEP 4: Attach Flutter UI
    if let engine = flutterEngine {
      let flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
      window = UIWindow(frame: UIScreen.main.bounds)
      window?.rootViewController = flutterVC
      window?.makeKeyAndVisible()
      updateDebugLabel("🌌 Flutter view ready!")
      print("✅ [UI] FlutterViewController loaded successfully.")
    }

    // 🧩 STEP 5: Start AdMob after short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      GADMobileAds.sharedInstance().start(completionHandler: nil)
      self.updateDebugLabel("💰 AdMob initialized")
      print("✅ [ADS] Google Mobile Ads initialized.")
    }

    updateDebugLabel("🚀 Launch complete — Flutter should take over.")
    print("🚀 [DONE] iOS launch finished cleanly.")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Debug Overlay Helpers
  private func setupDebugLabel(text: String) {
    debugLabel = UILabel(frame: CGRect(x: 20, y: 60, width: UIScreen.main.bounds.width - 40, height: 100))
    debugLabel?.text = text
    debugLabel?.textColor = .white
    debugLabel?.textAlignment = .center
    debugLabel?.numberOfLines = 0
    debugLabel?.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    debugLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.backgroundColor = .black
    window?.addSubview(debugLabel!)
    window?.makeKeyAndVisible()
  }

  private func updateDebugLabel(_ newText: String) {
    DispatchQueue.main.async {
      self.debugLabel?.text = newText
    }
  }
}
