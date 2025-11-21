import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let shareChannel = FlutterMethodChannel(name: "com.vtbh.chuckit.sharing",
                                                binaryMessenger: controller.binaryMessenger)

        shareChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "getAppGroupPath" {
                let appGroupId = "group.com.vtbh.chuckit"
                if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
                    result(containerURL.path)
                } else {
                    result(FlutterError(code: "UNAVAILABLE",
                                        message: "App Group not available",
                                        details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
