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

@MainActor
@Observable
public final class LocalizationEditorService {
    enum LocalizationEditorServiceError: Error {
        case reviseSupportBundleFailed
    }

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
                tableName: key.tableName,
                locale: locale
            )

            try LocalizedStringsFile.set(key.key, newValue, in: stringsURL)

            try self.reviseSupportBundle(
                superBundle: key.superBundle,
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

            try LocalizedStringsFile.remove(key.key, in: stringsURL)

            try self.reviseSupportBundle(
                superBundle: key.superBundle,
                supportBundleURL: supportBundleURL,
                installName: installName)
        } catch {
            Logger.error("Error: \(error)", LogCategory.localization)
        }
    }

    @MainActor
    func reviseSupportBundle(
        superBundle: Bundle,
        supportBundleURL: URL,
        installName: String
    ) throws {
        let rootSupportBundleURL = supportBundleURL.deletingLastPathComponent().deletingLastPathComponent()
        // If URL is unchanged, then deletingLastPathComponent failed.
        guard rootSupportBundleURL != supportBundleURL else {
            Logger.error("Invalid bundle URL", LogCategory.localization)
            return
        }
        let superBundleID = superBundle.bundleID
        let uniqueInstallName = "\(installName).\(UUIDBase58.idBase58)"

        do {
            let dstURL = try LocalizedStringBundlePaths.applicationSupportBundleURL(
                superBundleID: superBundleID, installName: uniqueInstallName)

            try LocalizedStringBundlePaths.copyStringDirectories(
                from: supportBundleURL,
                to: dstURL,
                overwriteExisting: true)

            // Reload bundle & register
            if let b = Bundle(url: dstURL) {
                runtime.setSupportBundle(
                    b, forSuperBundleID: superBundleID,
                    installName: installName, name: uniqueInstallName)
            }
        } catch {
            Logger.error("Error: \(error)", LogCategory.localization)
            throw LocalizationEditorServiceError.reviseSupportBundleFailed
        }
    }
}
