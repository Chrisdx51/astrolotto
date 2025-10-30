import UIKit
import Flutter
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 🔎 1) Find the plist in the app bundle
    if FirebaseApp.app() == nil {
      if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
         let options = FirebaseOptions(contentsOfFile: path) {
        print("✅ Firebase plist FOUND at: \(path)")
        print("✅ Firebase will init for BUNDLE_ID: \(options.bundleID)")
        FirebaseApp.configure(options: options)            // ← robust configure
      } else {
        // If we ever get here, the file is not in the app bundle
        print("❌ GoogleService-Info.plist NOT FOUND in bundle. App will crash without it.")
        assertionFailure("Missing GoogleService-Info.plist in iOS Runner target")
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
