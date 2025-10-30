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
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
