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

    // ✅ Initialize Firebase (safe check)
    if FirebaseApp.app() == nil {
      if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
      let options = FirebaseOptions(contentsOfFile: path) {
        print("✅ Firebase plist FOUND at: \(path)")
        print("✅ Firebase will init for BUNDLE_ID: \(options.bundleID)")
        FirebaseApp.configure(options: options)
      } else {
        print("❌ GoogleService-Info.plist NOT FOUND in bundle. App will crash without it.")
        assertionFailure("Missing GoogleService-Info.plist in iOS Runner target")
      }
    }

    // ✅ Create a Flutter engine (ensures Flutter renders even without SceneDelegate)
    flutterEngine = FlutterEngine(name: "AstroLottoEngine")
    flutterEngine?.run()
    GeneratedPluginRegistrant.register(with: flutterEngine!)

    // ✅ Show Flutter view controller manually (fixes black screen)
    if let flutterEngine = flutterEngine {
      let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
      self.window = UIWindow(frame: UIScreen.main.bounds)
      self.window?.rootViewController = flutterViewController
      self.window?.makeKeyAndVisible()
      print("✅ FlutterViewController loaded successfully.")
    }

    // ✅ Initialize AdMob after short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      GADMobileAds.sharedInstance().start(completionHandler: nil)
      print("✅ AdMob initialized safely after Flutter startup.")
    }

    print("✅ AppDelegate finished launching successfully.")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
