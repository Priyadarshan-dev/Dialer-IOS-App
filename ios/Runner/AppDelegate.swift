import Flutter
import UIKit
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // ✅ Standard single-delegate registration
        GeneratedPluginRegistrant.register(with: self)
        
        // ✅ Set up the channel for the main UI engine safely
        if let registrar = self.registrar(forPlugin: "com.liquid.dialer.AppDelegatePlugin") {
            self.setupCallDirectoryChannel(messenger: registrar.messenger())
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // This handles background engines (CallDirectory etc.)
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        // Plugins are already registered on the main bridge, 
        // but background engines need their own registration.
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        
        if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "com.liquid.dialer.AppDelegatePlugin") {
            self.setupCallDirectoryChannel(messenger: registrar.messenger())
        }
    }

    // Helper to avoid duplicating the channel logic
    private func setupCallDirectoryChannel(messenger: FlutterBinaryMessenger) {
        let callDirectoryChannel = FlutterMethodChannel(
            name: "com.liquid.dialer/call_directory",
            binaryMessenger: messenger
        )

        callDirectoryChannel.setMethodCallHandler { [weak self] call, result in
            if call.method == "syncAndReload" {
                guard let args = call.arguments as? [String: Any],
                      let appGroupId = args["appGroupId"] as? String,
                      let fileName = args["fileName"] as? String,
                      let data = args["data"] as? [String: String] else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
                    return
                }

                self?.saveToAppGroup(appGroupId: appGroupId, fileName: fileName, data: data) { success in
                    if success {
                        self?.reloadExtension(identifier: "\(Bundle.main.bundleIdentifier!).CallDirectoryExtension") { reloadSuccess in
                            result(reloadSuccess)
                        }
                    } else {
                        result(FlutterError(code: "SYNC_FAILED", message: "Failed to save to App Group", details: nil))
                    }
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - App Group Data Saving
    private func saveToAppGroup(
        appGroupId: String,
        fileName: String,
        data: [String: String],
        completion: @escaping (Bool) -> Void
    ) {
        guard let sharedContainer = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else {
            print("[DEBUG] AppDelegate: Failed to get App Group container")
            completion(false)
            return
        }

        let fileURL = sharedContainer.appendingPathComponent(fileName)

        do {
            let jsonData = try JSONSerialization.data(
                withReservedKeys: data,
                options: .prettyPrinted
            )
            try jsonData.write(to: fileURL)
            print("[DEBUG] AppDelegate: Successfully saved notes to \(fileURL.path)")
            completion(true)
        } catch {
            print("[DEBUG] AppDelegate: Error saving to App Group: \(error)")
            completion(false)
        }
    }

    // MARK: - Reload CallKit Extension
    private func reloadExtension(identifier: String, completion: @escaping (Bool) -> Void) {
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: identifier) { error in
            if let error = error {
                print("[DEBUG] AppDelegate: Error reloading extension: \(error)")
                completion(false)
            } else {
                print("[DEBUG] AppDelegate: Extension reload successful")
                completion(true)
            }
        }
    }
}

// MARK: - JSONSerialization Extension for CallKit
extension JSONSerialization {
    static func data(
        withReservedKeys dictionary: [String: String],
        options: JSONSerialization.WritingOptions = []
    ) throws -> Data {
        // ✅ CRITICAL: CallKit requires numbers to be sorted NUMERICALLY, not alphabetically.
        let sortedNumbers = dictionary.keys.compactMap { Int64($0) }.sorted()
        var sortedArray: [[String: String]] = []

        for number in sortedNumbers {
            let key = String(number)
            if let value = dictionary[key] {
                sortedArray.append([
                    "number": key,
                    "label": value
                ])
            }
        }

        return try JSONSerialization.data(withJSONObject: sortedArray, options: options)
    }
}