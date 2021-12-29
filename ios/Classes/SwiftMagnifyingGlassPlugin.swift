import Flutter
import UIKit

public class SwiftMagnifyingGlassPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "magnifying_glass", binaryMessenger: registrar.messenger())
    let instance = SwiftMagnifyingGlassPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
