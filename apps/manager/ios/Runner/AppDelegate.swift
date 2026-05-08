import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Self.readDotenvKey("GOOGLE_MAPS_API_KEY"), !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private static func readDotenvKey(_ key: String) -> String? {
    guard let path = Bundle.main.path(forResource: ".env", ofType: nil) ??
            Bundle.main.path(forResource: "Frameworks/App.framework/flutter_assets/.env", ofType: nil),
          let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
      return nil
    }
    for raw in contents.split(separator: "\n") {
      let line = raw.trimmingCharacters(in: .whitespaces)
      if line.isEmpty || line.hasPrefix("#") { continue }
      let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
      if parts.count == 2 && parts[0].trimmingCharacters(in: .whitespaces) == key {
        return parts[1].trimmingCharacters(in: .whitespaces)
      }
    }
    return nil
  }
}
