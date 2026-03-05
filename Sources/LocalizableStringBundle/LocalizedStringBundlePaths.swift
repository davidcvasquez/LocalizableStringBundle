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
import OSLog
import LoggerCategories

/// Paths for the localized string bundle and its localizable string files that are associated with a given bundle ID.
public enum LocalizedStringBundlePaths {
    enum LocalizedStringBundlePathsError: Error {
        case bundleIDNotFound
        case overwriteNotEnabled
        case invalidURLs
    }

    /// - Returns: The URL for the support bundle associated with the given original super bundle ID.
    public static func supportBundleURL(forSuperBundleID superBundleID: String) throws -> URL {
        guard let supportBundleName = LocalizationKey.supportBundleNames[superBundleID] else {
            throw LocalizedStringBundlePathsError.bundleIDNotFound
        }
        let fm = FileManager.default
        let base = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        guard let appID = Bundle.main.bundleIdentifier else {
            throw LocalizedStringBundlePathsError.bundleIDNotFound
        }

        let root = base.appendingPathComponent(appID, isDirectory: true)
        let folder = root.appendingPathComponent(
            LocalizationKey.resourcesDirectoryName, isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)

        return folder.appendingPathComponent("\(supportBundleName).bundle", isDirectory: true)
    }

    public static func applicationSupportBundleURL(
        superBundleID: String,
        installName: String
    ) throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let root = base.appendingPathComponent(superBundleID, isDirectory: true)
        let folder = root.appendingPathComponent(
            LocalizationKey.resourcesDirectoryName, isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)

        return folder.appendingPathComponent("\(installName).bundle", isDirectory: true)
    }

    public static func copyDirectoryBundle(
        from srcURL: URL,
        to dstURL: URL,
        overwriteExisting: Bool
    ) throws {
        guard srcURL != dstURL else {
            Logger.error("Cannot copy bundle onto itself.", LogCategory.localization)
            throw LocalizedStringBundlePathsError.invalidURLs
        }

        let fm = FileManager.default

        if fm.fileExists(atPath: dstURL.path) {
            if overwriteExisting {
                // Remove the existing directory bundle first
                try fm.removeItem(at: dstURL)
            } else {
                throw LocalizedStringBundlePathsError.overwriteNotEnabled
            }
        }

        // Ensure the parent directory exists
        try fm.createDirectory(
            at: dstURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // Copy the new bundle in
        try fm.copyItem(at: srcURL, to: dstURL)
    }

    /// - Returns: The URL for the info property list file.
    public static func infoURL(
        supportBundleURL: URL
    ) -> URL {
        supportBundleURL
            .appendingPathComponent(infoFilename, isDirectory: false)
    }

    /// - Returns: The URL for the localizable strings file.
    public static func localizableStringsURL(
        supportBundleURL: URL,
        locale: String = "en"
    ) -> URL {
        supportBundleURL
            .appendingPathComponent(localeProjectDirectoryName(locale), isDirectory: true)
            .appendingPathComponent(localizableStringsFilename, isDirectory: false)
    }

    /// - Returns: The URL for the localizable stringsdict file (for plurals).
    public static func localizableStringsdictURL(
        supportBundleURL: URL,
        locale: String = "en"
    ) -> URL {
        supportBundleURL
            .appendingPathComponent(localeProjectDirectoryName(locale), isDirectory: true)
            .appendingPathComponent(localizableStringsDictFilename, isDirectory: false)
    }

    private static func localeProjectDirectoryName(_ locale: String) -> String {
        "\(locale).lproj"
    }

    private static let infoFilename: String = "Info.plist"
    private static let localizableStringsFilename: String = "Localizable.strings"
    private static let localizableStringsDictFilename: String = "Localizable.stringsdict"
}
