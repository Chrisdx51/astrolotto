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

    // ✅ Initialize Firebase safely
    if FirebaseApp.app() == nil {
      if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
      let options = FirebaseOptions(contentsOfFile: path) {
        print("✅ Firebase plist FOUND at: \(path)")
        FirebaseApp.configure(options: options)
      } else {
        print("❌ GoogleService-Info.plist NOT FOUND in bundle.")
        assertionFailure("Missing GoogleService-Info.plist in iOS Runner target")
      }
    }

    // ✅ Create a dedicated Flutter engine and run the iOS entrypoint
    flutterEngine = FlutterEngine(name: "AstroLottoEngine")
    flutterEngine?.run(withEntrypoint: "main_ios") // 👈 Uses your iOS-specific main()

    // ✅ Register all Flutter plugins (very important)
    if let engine = flutterEngine {
      GeneratedPluginRegistrant.register(with: engine)
    }

    // ✅ Attach Flutter view controller to the window
    if let engine = flutterEngine {
      let flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
      window = UIWindow(frame: UIScreen.main.bounds)
      window?.rootViewController = flutterVC
      window?.makeKeyAndVisible()
      print("✅ FlutterViewController displayed successfully.")
    } else {
      print("❌ FlutterEngine failed to initialize — check main_ios() entrypoint.")
    }

    // ✅ Initialize AdMob after Flutter is ready (avoids freezes)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      GADMobileAds.sharedInstance().start(completionHandler: nil)
      print("✅ Google Mobile Ads initialized.")
    }

    // ✅ Return super to complete setup
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
