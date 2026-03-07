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

import Foundation
import CompactUUID
import OSLog
import LoggerCategories

/// Installer for layered localized string bundles in multiple domains (packages or an app), starting from an embedded bundle.
/// Live updates and remote service can also be implemented using a support bundle in the Application Support directory.
public enum LocalizedStringBundleInstaller {
    enum LocalizedStringBundleInstallerError: Error {
        case bundleIDNotFound
        case embeddedURLNotFound
        case overwriteNotEnabled
        case invalidURLs
    }

    /// Installs a support string bundle in Application Support using an embedded source bundle and registers a super fallback bundle.
    ///  - parameters:
    ///    - from: The bundle that owns the embedded bundle (e.g. Bundle.module for a package, Bundle.main for app).
    ///    - installName: The filename to use in Application Support, e.g. "Application-Strings" (becomes "Application-Strings.bundle").
    ///    - overwriteExisting: Whether any existing bundle with the same name should be overwritten.
    public static func install(
        from superBundle: Bundle,
        installName: String? = nil,
        overwriteExisting: Bool = false
    ) throws {
        let superBundleID = superBundle.bundleID

        LocalizationKey.superBundles[superBundleID] = superBundle

        guard let installName else {
            return
        }

        let uniqueInstallName = "\(installName).\(UUIDBase58.idBase58)"
        // Build Application Support destination: .../<app-bundle-id>/Resources/<installName>.bundle
        let dstURL = try LocalizedStringBundlePaths.applicationSupportBundleURL(
            superBundleID: superBundleID, installName: uniqueInstallName)

        try LocalizedStringBundlePaths.copyStringDirectories(
            from: superBundle,
            subdirectory: "Strings", to: dstURL, overwriteExisting: true)

        // Load support bundle and register by ID.
        if let supportBundle = Bundle(url: dstURL) {
            LocalizationKey.installSupportBundle(
                bundleID: superBundleID,
                bundle: supportBundle,
                installName: installName,
                name: uniqueInstallName)
        }
    }

    fileprivate static var areMenuNamesInstalled: Bool = false
}

extension Bundle {
    /// Returns a stable identifier for the bundle. Falls back when `bundleIdentifier` is unavailable (e.g., SwiftPM resource bundles).
    /// Priority:
    /// 1. `bundleIdentifier`
    /// 2. `CFBundleName` from Info.plist (prefixed with `spm.`)
    /// 3. Last path component of the bundle URL without extension (prefixed with `spm.`)
    /// 4. "spm.unknown"
    public var bundleID: String {
        if let id = self.bundleIdentifier, !id.isEmpty {
            return id
        }
        if let name = self.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String, !name.isEmpty {
            return "spm.\(name)"
        }
        let last = self.bundleURL.deletingPathExtension().lastPathComponent
        if !last.isEmpty {
            return "spm.\(last)"
        }
        return "spm.unknown"
    }
}
