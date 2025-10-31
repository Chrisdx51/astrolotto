import UIKit
import Flutter
import FirebaseCore
import GoogleMobileAds

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  var flutterEngine: FlutterEngine?
  var windowLabel: UILabel?

  override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 🟣 Step 1: Setup a visible label on black background so we can SEE progress
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.backgroundColor = .black

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
        print(text)
      }
    }

    // 🟢 Step 2: Try Firebase
    updateLabel("⚙️ Initializing Firebase...")
    if FirebaseApp.app() == nil {
      if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
      let options = FirebaseOptions(contentsOfFile: path) {
        FirebaseApp.configure(options: options)
        updateLabel("✅ Firebase initialized OK")
      } else {
        updateLabel("❌ Firebase plist missing in Runner folder!")
      }
    } else {
      updateLabel("✅ Firebase already active")
    }

    // 🟢 Step 3: Try Flutter engine
    updateLabel("✨ Starting Flutter engine...")
    flutterEngine = FlutterEngine(name: "AstroLottoEngine")
    flutterEngine?.run(withEntrypoint: "main_ios")

    if let engine = flutterEngine {
      GeneratedPluginRegistrant.register(with: engine)
      updateLabel("✅ Flutter plugins registered")
    } else {
      updateLabel("❌ Flutter engine FAILED to start")
    }

    // 🟢 Step 4: Show Flutter view controller
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      if let engine = self.flutterEngine {
        let flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        self.window?.rootViewController = flutterVC
        self.window?.makeKeyAndVisible()
        updateLabel("🟩 Flutter UI visible")
      } else {
        updateLabel("❌ Could not create FlutterViewController")
      }
    }

    // 🟢 Step 5: Delay AdMob initialization
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
      updateLabel("📡 Initializing AdMob...")
      GADMobileAds.sharedInstance().start(completionHandler: { _ in
        updateLabel("✅ AdMob initialized successfully!")
      })
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
