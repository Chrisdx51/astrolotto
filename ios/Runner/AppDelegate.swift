import UIKit
import Flutter
import FirebaseCore
import GoogleMobileAds

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

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

    // ✅ Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // ✅ Initialize Google AdMob after a short delay (to ensure Flutter is ready)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      GADMobileAds.sharedInstance().start(completionHandler: nil)
      print("✅ AdMob initialized safely after Flutter startup.")
    }

    // ✅ Continue app launch
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
