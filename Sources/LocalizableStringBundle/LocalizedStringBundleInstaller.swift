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
    ///    - embeddedBundleName: The embedded bundle name (without ".bundle"), e.g. "Application-Strings".
    ///    - installName: The filename to use in Application Support, e.g. "Application-Strings" (becomes "Application-Strings.bundle").
    ///    - overwriteExisting: Whether any existing bundle with the same name should be overwritten.
    public static func install(
        from superBundle: Bundle,
        embeddedBundleName: String,
        installName: String,
        overwriteExisting: Bool = false
    ) throws {
        guard let superBundleID = superBundle.bundleIdentifier else {
            throw LocalizedStringBundleInstallerError.bundleIDNotFound
        }

        LocalizationKey.superBundles[superBundleID] = superBundle

        // Find the embedded string bundle inside the domain super bundle.
        guard let embeddedURL = superBundle.url(
            forResource: embeddedBundleName, withExtension: "bundle") else {
            throw LocalizedStringBundleInstallerError.embeddedURLNotFound
        }

        let uniqueInstallName = "\(installName).\(UUIDBase58.idBase58)"

        // Build Application Support destination: .../<app-bundle-id>/Resources/<installName>.bundle
        let dstURL = try LocalizedStringBundlePaths.applicationSupportBundleURL(
            superBundleID: superBundleID, installName: uniqueInstallName)

        // Copy embedded bundle to support bundle location, according to overwriteExisting.
        try LocalizedStringBundlePaths.copyDirectoryBundle(
            from: embeddedURL, to: dstURL, overwriteExisting: overwriteExisting)

        // Load support bundle and register by ID.
        if let supportBundle = Bundle(url: dstURL) {
            LocalizationKey.installSupportBundle(
                bundleID: superBundleID,
                bundle: supportBundle,
                installName: installName,
                name: uniqueInstallName)
        }
    }
}
