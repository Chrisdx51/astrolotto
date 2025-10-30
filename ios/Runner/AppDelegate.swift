import UIKit
import Flutter
import FirebaseCore   // ✅ Needed for Firebase Messaging to work on iOS

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Initialize Firebase before Flutter starts (safe if already configured)
    do {
      if FirebaseApp.app() == nil {
        FirebaseApp.configure()
      }
    } catch {
      print("⚠️ Firebase already configured or not available yet: \(error)")
    }


    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
