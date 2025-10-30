import UIKit
import Flutter
import FirebaseCore   // ✅ Needed for Firebase Messaging, Installations, etc.

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Initialize Firebase first — no try/catch needed, just ensure it's once.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // ✅ Register Flutter plugins AFTER Firebase is ready
    GeneratedPluginRegistrant.register(with: self)

    // ✅ Continue launching normally
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
