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
@MainActor
public enum LocalizedStringBundlePaths {
    enum LocalizedStringBundlePathsError: Error {
        case bundleIDNotFound
        case overwriteNotEnabled
        case invalidURLs
        case resourceNotFound
        case copyStringDirectoriesFailed
    }

    /// - Returns: The URL for the support bundle associated with the given original super bundle ID.
    public static func supportBundleURL(forSuperBundleID superBundleID: String) throws -> URL {
        guard let supportBundleName = LocalizationKey.supportBundleNames[superBundleID] else {
            Logger.debug("supportBundleName not found", LogCategory.localization)
            throw LocalizedStringBundlePathsError.bundleIDNotFound
        }
        let fm = FileManager.default
        let base = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let appID = Bundle.main.bundleID

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

    public static func copyStringDirectories(
        from superBundle: Bundle,
        subdirectory: String,
        to supportBundleURL: URL,
        overwriteExisting: Bool = false
    ) throws {
        guard let subdirectoryURL = superBundle.url(
            forResource: subdirectory, withExtension: nil) ?? superBundle.resourceURL else {

            Logger.debug("subdirectory not found", LogCategory.localization)
            throw LocalizedStringBundlePathsError.resourceNotFound
        }

        try copyStringDirectories(
            from: subdirectoryURL,
            to: supportBundleURL,
            overwriteExisting: overwriteExisting)
    }

    public static func copyStringDirectories(
        from srcURL: URL,
        to supportBundleURL: URL,
        overwriteExisting: Bool = false
    ) throws {
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: supportBundleURL, withIntermediateDirectories: true)

            let entries = try fm.contentsOfDirectory(
                at: srcURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            // Copy all of the "*.lproj" directories over to the supportBundle.
            for src in entries {
                let values = try src.resourceValues(forKeys: [.isDirectoryKey])
                guard values.isDirectory == true else { continue }
                guard src.pathExtension == "lproj" else { continue }

                let dst = supportBundleURL.appendingPathComponent(src.lastPathComponent, isDirectory: true)

                if fm.fileExists(atPath: dst.path) {
                    if overwriteExisting {
                        _ = try fm.replaceItemAt(dst, withItemAt: src)
                    } else {
                        continue
                    }
                } else {
                    try fm.copyItem(at: src, to: dst)
                }
            }
        } catch {
            Logger.error("Error: \(error)", LogCategory.localization)
            throw LocalizedStringBundlePathsError.copyStringDirectoriesFailed
        }
   }

    /// - Returns: The URL for the localizable strings file.
    public static func localizableStringsURL(
        supportBundleURL: URL,
        tableName: String = "Localizable",
        locale: String = "en"
    ) -> URL {
        supportBundleURL
            .appendingPathComponent(localeProjectDirectoryName(locale), isDirectory: true)
            .appendingPathComponent("\(tableName)\(stringsFileExtension)", isDirectory: false)
    }

    /// - Returns: The URL for the localizable stringsdict file (for plurals).
    public static func localizableStringsdictURL(
        supportBundleURL: URL,
        tableName: String = "Localizable",
        locale: String = "en"
    ) -> URL {
        supportBundleURL
            .appendingPathComponent(localeProjectDirectoryName(locale), isDirectory: true)
            .appendingPathComponent("\(tableName)\(stringsDictFileExtension)", isDirectory: false)
    }

    private static func localeProjectDirectoryName(_ locale: String) -> String {
        "\(locale).lproj"
    }

    private static let stringsFileExtension: String = ".strings"
    private static let stringsDictFileExtension: String = ".stringsdict"
}
