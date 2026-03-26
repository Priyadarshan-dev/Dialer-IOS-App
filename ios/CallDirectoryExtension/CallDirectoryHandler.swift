//
//  CallDirectoryHandler.swift
//  CallDirectoryExtension
//
//  Created by Annular Mobile Development on 25/03/26.
//

import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // For this POC, we always perform a full reload to ensure data consistency
        // with the main app's Hive/SharedPreferences store.
        addAllIdentificationPhoneNumbers(to: context)

        context.completeRequest()
    }

    private func addAllBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // No blocking functionality implemented in this POC.
    }

    private func addAllIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        guard let data = fetchDataFromAppGroup() else {
            return
        }

        // CXCallDirectoryPhoneNumber is an Int64. The data is already sorted numerically 
        // by the AppDelegate.swift before saving.
        for entry in data {
            if let numberString = entry["number"], 
               let phoneNumber = Int64(numberString),
               let label = entry["label"] {
                context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
            }
        }
    }

    private func fetchDataFromAppGroup() -> [[String: String]]? {
        let appGroupId = "group.com.liquid.dialer.shared"
        let fileName = "call_directory_data.json"

        guard let sharedContainer = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else {
            return nil
        }

        let fileURL = sharedContainer.appendingPathComponent(fileName)

        do {
            let data = try Data(contentsOf: fileURL)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [[String: String]]
        } catch {
            return nil
        }
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // Log or handle failure
    }
}
