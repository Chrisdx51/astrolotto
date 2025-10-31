import UIKit
import Flutter
import FirebaseCore
import GoogleMobileAds

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  var flutterEngine: FlutterEngine?
  var windowLabel: UILabel?
  var admobStarted = false

  override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    window = UIWindow(frame: UIScreen.main.bounds)
    window?.backgroundColor = .black

    // 🟣 Label so we can see progress if something goes wrong
    windowLabel = UILabel(frame: window!.bounds)
    windowLabel?.textColor = .white
    windowLabel?.textAlignment = .center
    windowLabel?.numberOfLines = 0
    windowLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
    windowLabel?.text = "🚀 Launching Astro Lotto..."
    window?.addSubview(windowLabel!)
    window?.makeKeyAndVisible()

    func updateLabel(_ text: String) {
      DispatchQueue.main.async {
        self.windowLabel?.text = text
        print("🪐 \(text)")
      }
    }

    // ⚙️ Step 1: Firebase Init
    updateLabel("⚙️ Initializing Firebase...")

    if FirebaseApp.app() == nil {
      if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
      let options = FirebaseOptions(contentsOfFile: path) {
        FirebaseApp.configure(options: options)
        updateLabel("✅ Firebase initialized successfully ✅")
      } else {
        updateLabel("⚠️ GoogleService-Info.plist not found — skipping Firebase init")
        print("⚠️ Firebase plist missing — continuing without crash.")
      }
    } else {
      updateLabel("✅ Firebase already configured")
    }


    // ✨ Step 2: Flutter Engine
    updateLabel("✨ Starting Flutter engine...")
    flutterEngine = FlutterEngine(name: "AstroLottoEngine")
    flutterEngine?.run()
    if let engine = flutterEngine {
      GeneratedPluginRegistrant.register(with: engine)
      updateLabel("✅ Flutter engine ready")
    }

    // ✅ Step 3: Show Flutter after 1s
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      if let engine = self.flutterEngine {
        let flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        self.window?.rootViewController = flutterVC
        self.window?.makeKeyAndVisible()
        updateLabel("🟩 Flutter visible")
        // 🔹 Schedule AdMob only after UI appears
        self.initializeAdMobAfterDelay()
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 🧩 Step 4: Safe AdMob startup (later and once only)
  private func initializeAdMobAfterDelay() {
    guard !admobStarted else { return } // ensure only once
    admobStarted = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
      print("📡 Starting AdMob...")
      GADMobileAds.sharedInstance().start { status in
        print("✅ AdMob safely initialized after delay")
      }
    }
  }
}
