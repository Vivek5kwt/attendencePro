import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Initialize Firebase
    FirebaseApp.configure()
    print("🔥 FIREBASE INITIALIZED SUCCESSFULLY")

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // Register for APNs notifications
    application.registerForRemoteNotifications()

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 🔥 Called when APNs token is received
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("📨 APNs DEVICE TOKEN: \(token)")

    // Pass token to Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
  }

  // ❌ Called when APNs token fails
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("🚨 Failed to register for APNs: \(error)")
  }
}
