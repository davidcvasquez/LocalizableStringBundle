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

/// A layered localization key that enables managing strings in multiple domains (packages or an app) starting from an embedded bundle.
/// Live updates and remote service can also be implemented using a support bundle in the Application Support directory.
public struct LocalizationKey: Hashable, Codable {
    static let resourcesDirectoryName: String = "Resources"

    enum LocalizationKeyError: Error {
        case bundleIDNotFound
    }

    /// A key for a localized string.
    public var key: String { self.rawKey }

    /// The ID for the super bundle used to originally register this key.
    public var superBundleIdentifier: String? {
        self.superBundle.bundleID
    }

    private let rawKey: String

    /// The super bundle from which the Strings sub-directory is copied to a support bundle.
    public let superBundle: Bundle

    /// The table name for a given group of strings.
    public let tableName: String

    /// Support bundles for live updates and remote service.
    public private(set) static var supportBundles: [String: Bundle] = [:]
    public private(set) static var supportBundleNames: [String: String] = [:]
    public private(set) static var installNames: [String: String] = [:]

    static func installSupportBundle(
        bundleID: String,
        bundle: Bundle,
        installName: String,
        name: String? = nil
    ) {
        if let oldBundle = Self.supportBundles[bundleID] {
            Logger.debug("Removing old bundle for \(bundleID): \(ObjectIdentifier(oldBundle))", LogCategory.localization)
        }
        Self.supportBundles[bundleID] = bundle
        Self.membership.removeValue(forKey: bundleID)

        if let newBundle = Self.supportBundles[bundleID] {
            Logger.debug("Installed new bundle for \(bundleID): \(ObjectIdentifier(newBundle))", LogCategory.localization)
        }

        LocalizationKey.installNames[bundleID] = installName

        if let name {
            LocalizationKey.supportBundleNames[bundleID] = name
        }
    }

    static func removeSupportBundle(bundleID: String) {
        Self.supportBundles.removeValue(forKey: bundleID)
        Self.membership.removeValue(forKey: bundleID)
    }

    public static var superBundles: [String: Bundle] = [:]

    // Cache only whether a key exists in the override bundle for a bundle-id,
    // NOT the translated value.
    private static var membership: [String: Set<String>] = [:]
    private static var localeObserverInstalled = false

    /// Initializer by the key and super bundle that owns the embedded bundle.
    public init(_ rawKey: String,
                bundle: Bundle,
                tableName: String = "Localizable"
    ) {
        self.rawKey = rawKey
        self.superBundle = bundle
        self.tableName = tableName
        Self.installLocaleChangeObserverIfNeeded()
    }

    // Codable conformance only stores the key and super bundle ID, since a bundle is not Codable.
    private enum CodingKeys: String, CodingKey {
        case rawKey
        case superBundleID
        case tableName
    }

    /// Initializer from a decoder.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.rawKey = try container.decode(String.self, forKey: .rawKey)
        if let superBundleID = try? container.decode(String.self, forKey: .superBundleID),
           let superBundle = Self.superBundles[superBundleID] {
            self.superBundle = superBundle
        } else {
            throw LocalizationKeyError.bundleIDNotFound
        }
        self.tableName = try container.decode(String.self, forKey: .tableName)
        Self.installLocaleChangeObserverIfNeeded()
    }

    /// Codable conformance only stores the key and super bundle ID, since a bundle is not Codable.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawKey, forKey: .rawKey)
        try container.encode(tableName, forKey: .tableName)
        let superBundleID = superBundle.bundleID
        try container.encode(superBundleID, forKey: .superBundleID)
    }

    private static func installLocaleChangeObserverIfNeeded() {
        guard !localeObserverInstalled else { return }
        localeObserverInstalled = true

        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: nil
        ) { _ in
            // Locale changed -> clear membership decisions.
            membership.removeAll()
        }
    }

    // - Returns: The support bundle associated with the ID of the original super bundle.
    private var supportBundle: Bundle? {
        Self.supportBundles[self.superBundle.bundleID]
    }

    // - Returns: Whether the given bundle (and bundle ID) contains the stored key.
    private func bundleContainsKey(_ bundle: Bundle, bundleID: String) -> Bool {
        // If we have a cache for this bundleID and it contains the key, return true.
        if let cached = Self.membership[bundleID], cached.contains(rawKey) {
            return true
        }

        // Otherwise, probe the bundle to see if the key exists.
        let sentinel = "\u{1F6D1}__L10N_MISSING__\u{1F6D1}"
        let found = bundle.localizedString(
            forKey: rawKey, value: sentinel, table: self.tableName) != sentinel

        if found {
            // Insert this key into the cached set for the bundleID for fast lookups.
            Self.membership[bundleID, default: []].insert(rawKey)
        }

        return found
    }

    // - Returns: Either the support bundle or the super bundle as a fallback.
    private var effectiveBundle: Bundle {
        guard let bundle = supportBundle,
              bundleContainsKey(bundle, bundleID: bundle.bundleID) else {
            return superBundle
        }

        return bundle
    }

    /// - Returns: A LocalizedStringResource built from the stored key and bundle.
    public var resource: LocalizedStringResource {
        let bundle = effectiveBundle

        Logger.debug("Effective bundle for \(rawKey): \(ObjectIdentifier(bundle))", LogCategory.localization)

        return LocalizedStringResource(.init(rawKey), table: self.tableName, bundle: bundle)
    }

    /// Parameterized / plural-aware localized string that handles an integer count parameter of 0, 1, or more.
    ///
    /// Usage:
    /// ```
    /// LocalizationKey.selectedDocumentCount(0)
    /// LocalizationKey.selectedDocumentCount(1)
    /// LocalizationKey.selectedDocumentCount(2)
    /// ```
    public func callAsFunction(_ args: any CVarArg...) -> String {
        String(format: String(localized: resource), locale: .current, args)
    }
}
