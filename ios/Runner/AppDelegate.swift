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

    // ✅ Step 1: Initialize Firebase safely
    if FirebaseApp.app() == nil {
      if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
      let options = FirebaseOptions(contentsOfFile: path) {
        FirebaseApp.configure(options: options)
        print("✅ Firebase initialized")
      } else {
        print("❌ Missing GoogleService-Info.plist")
      }
    }

    // ✅ Step 2: Start Flutter engine
    flutterEngine = FlutterEngine(name: "AstroLottoEngine")
    flutterEngine?.run(withEntrypoint: "main_ios")

    if let engine = flutterEngine {
      GeneratedPluginRegistrant.register(with: engine)
    }

    // ✅ Step 3: Show Flutter UI safely
    if let engine = flutterEngine {
      let flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
      window = UIWindow(frame: UIScreen.main.bounds)
      window?.rootViewController = flutterVC
      window?.makeKeyAndVisible()
      print("✅ Flutter UI displayed")
    }

    // ⚡ Step 4: Delay AdMob init until after 3 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
      GADMobileAds.sharedInstance().start(completionHandler: nil)
      print("✅ AdMob initialized after delay")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
