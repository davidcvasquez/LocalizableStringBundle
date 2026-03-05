//===----------------------------------------------------------------------===//
//
// This source file is part of the LocalizableStringBundle open source project
//
// Copyright (c) 2026 David C. Vasquez and the LocalizableStringBundle project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See the project's LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import OSLog
import CompactUUID
import LoggerCategories
import SwiftUI

@Observable
public final class LocalizationEditorService {
    public var isEditingStrings: Bool = false
    public var locale: String = Locale.current.language.languageCode?.identifier ?? "en"

    private let runtime: LocalizationRuntime

    public init(runtime: LocalizationRuntime) {
        self.runtime = runtime
    }

    /// Returns the *current* displayed string (support-first then fallback to super).
    public func currentValue(for key: LocalizationKey) -> String {
        // This gives the effective localized value (support or fallback)
        String(localized: key.resource)
    }

    /// Writes a support value for this key into Application Support, then reloads the support bundle.
    @MainActor
    public func setSupportValue(_ newValue: String, for key: LocalizationKey) async {
        guard let superBundleID = key.superBundleIdentifier else {
            Logger.error("superBundleID not found", LogCategory.localization)
            return
        }
        guard let installName = LocalizationKey.installNames[superBundleID] else {
            Logger.error("installName not found", LogCategory.localization)
            return
        }

        do {
            let supportBundleURL = try LocalizedStringBundlePaths.supportBundleURL(
                forSuperBundleID: superBundleID)
            let stringsURL = LocalizedStringBundlePaths.localizableStringsURL(
                supportBundleURL: supportBundleURL,
                locale: locale
            )

            try LocalizedStringsTextFile.set(key.key, newValue, in: stringsURL)

            self.reviseSupportBundle(
                superBundleID: superBundleID,
                supportBundleURL: supportBundleURL,
                installName: installName)
        } catch {
            Logger.error("Error: \(error)", LogCategory.localization)
        }
    }

    /// Removes a support value so the app falls back to embedded localization.
    @MainActor
    public func clearSupportValue(for key: LocalizationKey) async {
        guard let superBundleID = key.superBundleIdentifier else {
            Logger.error("superBundleID not found", LogCategory.localization)
            return
        }
        guard let installName = LocalizationKey.installNames[superBundleID] else {
            Logger.error("installName not found", LogCategory.localization)
            return
        }

        do {
            let supportBundleURL = try LocalizedStringBundlePaths.supportBundleURL(
                forSuperBundleID: superBundleID)
            let stringsURL = LocalizedStringBundlePaths.localizableStringsURL(
                supportBundleURL: supportBundleURL,
                locale: locale
            )

            try LocalizedStringsTextFile.remove(key.key, in: stringsURL)

            self.reviseSupportBundle(
                superBundleID: superBundleID,
                supportBundleURL: supportBundleURL,
                installName: installName)
        } catch {
            Logger.error("Error: \(error)", LogCategory.localization)
        }
    }

    @MainActor
    func reviseSupportBundle(
        superBundleID: String,
        supportBundleURL: URL,
        installName: String
    ) {
        self.bumpInfoVersion(supportBundleURL)

        let rootSupportBundleURL = supportBundleURL.deletingLastPathComponent().deletingLastPathComponent()
        // If URL is unchanged, then deletingLastPathComponent failed.
        guard rootSupportBundleURL != supportBundleURL else {
            Logger.error("Invalid bundle URL", LogCategory.localization)
            return
        }
        let uniqueInstallName = "\(installName).\(UUIDBase58.idBase58)"

        do {
            let dstURL = try LocalizedStringBundlePaths.applicationSupportBundleURL(
                superBundleID: superBundleID, installName: uniqueInstallName)
            try LocalizedStringBundlePaths.copyDirectoryBundle(
                from: supportBundleURL, to: dstURL, overwriteExisting: true)

            // Reload bundle & register
            if let b = Bundle(url: dstURL) {
                runtime.setSupportBundle(
                    b, forSuperBundleID: superBundleID, installName: installName)
            }
        } catch {
            Logger.error("Error: \(error)", LogCategory.localization)
        }
    }

    // Bump the CFBundleVersion and CFBundleShortVersionString values.
    // The version is stored in Info.plist at LocalizedStringBundlePaths.infoURL
    @MainActor
    private func bumpInfoVersion(_ supportBundleURL: URL) {
        do {
            // Locate Info.plist for the support bundle
            let infoPlistURL = LocalizedStringBundlePaths.infoURL(
                supportBundleURL: supportBundleURL)

            // Load existing plist as a mutable dictionary
            let data = try Data(contentsOf: infoPlistURL)
            var format = PropertyListSerialization.PropertyListFormat.xml
            guard var plist = try PropertyListSerialization.propertyList(from: data, options: [], format: &format) as? [String: Any] else {
                throw NSError(domain: "LocalizationRuntime", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Info.plist format"])
            }

            // Helper to increment a numeric string (e.g., "7" -> "8")
            func incrementNumericString(_ s: String) -> String {
                if let n = Int(s) { return String(n + 1) }
                return "1"
            }

            // Helper to increment the last component of a dotted version (e.g., "1.2.3" -> "1.2.4")
            func incrementDottedVersion(_ s: String) -> String {
                var parts = s.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
                guard !parts.isEmpty else { return "1" }
                let lastIdx = parts.count - 1
                if let n = Int(parts[lastIdx]) {
                    parts[lastIdx] = String(n + 1)
                    return parts.joined(separator: ".")
                } else {
                    // If last is not numeric, append a numeric patch
                    parts.append("1")
                    return parts.joined(separator: ".")
                }
            }

            // Bump CFBundleVersion
            if let currentBuild = plist["CFBundleVersion"] as? String {
                plist["CFBundleVersion"] = incrementNumericString(currentBuild)
            } else if let currentBuildNum = plist["CFBundleVersion"] as? NSNumber {
                plist["CFBundleVersion"] = String(currentBuildNum.intValue + 1)
            } else {
                plist["CFBundleVersion"] = "1"
            }

            // Bump CFBundleShortVersionString
            if let currentShort = plist["CFBundleShortVersionString"] as? String {
                plist["CFBundleShortVersionString"] = incrementDottedVersion(currentShort)
            } else {
                plist["CFBundleShortVersionString"] = "1.0.1"
            }

            // Write the updated plist back to disk in XML format
            let updatedData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try updatedData.write(to: infoPlistURL, options: .atomic)
        } catch {
            // If bumping fails, continue with reloading; this is best-effort in dev
        }
    }
}

struct LocalizationEditableLabel: View {
    @Environment(LocalizationRuntime.self) private var localization
    @Environment(LocalizationEditorService.self) private var editor

    let key: LocalizationKey

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        Group {
            if editor.isEditingStrings {
                TextField("", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .onAppear { draft = editor.currentValue(for: key) }
                    .focused($focused)
                    .onSubmit {
                        Task { await editor.setSupportValue(draft, for: key) }
                    }
                    .contextMenu {
                        Button(.applyLabel) {
                            Task { await editor.setSupportValue(draft, for: key) }
                        }
                        Button(.resetLabel) {
                            Task { await editor.clearSupportValue(for: key) }
                        }
                    }
            } else {
                // Force refresh when support reloads
                Text(key.resource)
                    .id(localization.revision)
            }
        }
    }
}
