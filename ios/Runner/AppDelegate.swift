import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
//     GMSServices.provideAPIKey("AIzaSyCxTvg_BtNBJ3bNM5jTp3zOyKIIAyXTDNU")
    GMSServices.provideAPIKey("AIzaSyD1aGwZKW5Or-k24idzVUlj3UdHhYT9P1Q")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
