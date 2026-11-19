import Flutter
import SquareMobilePaymentsSDK
import UIKit

// Sandbox application ID for "CCD Raffle Mobile App" — see docs/credentials.local.md.
// Swap for the production Application ID before any real-money release.
private let squareApplicationId = "sandbox-sq0idb-YAjXgGPlVms4aXz3ptLiTg"

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    MobilePaymentsSDK.initialize(squareApplicationID: squareApplicationId)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
