import UIKit
import Flutter
import FirebaseCore
import GoogleMobileAds

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  var flutterEngine: FlutterEngine?

  override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Firebase (safe configure from plist in bundle)
    if FirebaseApp.app() == nil {
      if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
      let options = FirebaseOptions(contentsOfFile: path) {
        print("✅ Firebase plist FOUND at: \(path)")
        print("✅ Firebase will init for BUNDLE_ID: \(options.bundleID)")
        FirebaseApp.configure(options: options)
      } else {
        print("❌ GoogleService-Info.plist NOT FOUND in bundle.")
        assertionFailure("Missing GoogleService-Info.plist in iOS Runner target")
      }
    }

    // ✅ Create and run a Flutter engine with the iOS entrypoint
    flutterEngine = FlutterEngine(name: "AstroLottoEngine")
    flutterEngine?.run(withEntrypoint: "main_ios") // 👈 IMPORTANT
    if let engine = flutterEngine {
      GeneratedPluginRegistrant.register(with: engine)
    }

    // ✅ Manually show Flutter UI (avoids scene black screen issues)
    if let engine = flutterEngine {
      let flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
      self.window = UIWindow(frame: UIScreen.main.bounds)
      self.window?.rootViewController = flutterVC
      self.window?.makeKeyAndVisible()
      print("✅ FlutterViewController loaded successfully.")
    }

    // ✅ Start AdMob after a tiny delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      GADMobileAds.sharedInstance().start(completionHandler: nil)
      print("✅ AdMob initialized safely after Flutter startup.")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
