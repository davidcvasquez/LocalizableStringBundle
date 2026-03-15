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
import Observation
import OSLog
import LoggerCategories

/// A runtime “localization support” store that can reload and poke SwiftUI.
@MainActor
@Observable
public final class LocalizationRuntime {
    /// Incremented whenever support bundles are reloaded.
    public private(set) var revision: UInt64 = 0

    /// The support bundles used by LocalizationKey, as keyed by super bundle IDs.
    public private(set) var supportBundles: [String: Bundle] = [:]

    public init() {}

    // Workaround for XCTest crash during deallocation.
    // Reproduces when module is built with default isolation set to MainActor.
    // https://github.com/swiftlang/swift/issues/87316
    nonisolated deinit {}

    /// Install / replace an support bundle for a particular super bundle id.
    public func setSupportBundle(
        _ bundle: Bundle,
        forSuperBundleID superBundleID: String,
        installName: String,
        name: String? = nil
    ) {
        supportBundles[superBundleID] = bundle
        revision &+= 1
        Logger.debug("update revision: \(revision) for new bundle \(ObjectIdentifier(bundle))", LogCategory.localization)
        LocalizationKey.installSupportBundle(
            bundleID: superBundleID, bundle: bundle, installName: installName, name: name)
    }

    public func removeSupportBundle(forFallbackBundleID superBundleID: String) {
        supportBundles.removeValue(forKey: superBundleID)
        revision &+= 1
        Logger.debug("update revision: \(revision)", LogCategory.localization)
        LocalizationKey.removeSupportBundle(bundleID: superBundleID)
    }
}
