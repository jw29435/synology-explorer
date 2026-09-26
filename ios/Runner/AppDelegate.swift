import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Auto-Upload: BGTaskScheduler-Handler vor Ende des App-Starts
    // registrieren (UIScene-Lebenszyklus) und Plugins in der
    // Hintergrund-Engine verfügbar machen.
    WorkmanagerPlugin.registerLaunchHandlers()
    // Den Handler immer hier registrieren: BGTaskScheduler lässt das nur
    // bis zum Ende von didFinishLaunching zu. Sonst täte es das Plugin erst
    // beim ersten Einplanen aus Dart – Absturz beim Einschalten des
    // Auto-Uploads. Gleiche ID wie in Info.plist und background.dart.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "de.jw29435.nuvoExplorer.autoUpload",
      earliestBeginInSeconds: NSNumber(value: 15 * 60)
    )
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
