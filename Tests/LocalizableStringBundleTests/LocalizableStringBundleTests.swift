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

import XCTest
import LocalizableStringBundle
import LocalizableStringBundleUI
import OSLog

final class LocalizableStringBundleTests: XCTestCase {
    @MainActor
    func testInternalStringsInstaller() {
        do {
            try LocalizableStringBundleUI.Strings.install()
        } catch {
            XCTFail("Failed to install LocalizableStringBundleUI.Strings: \(error)")
        }
    }

    @MainActor
    func testInternalStringLookups() {
        do {
            try LocalizableStringBundleUI.Strings.install()
        } catch {
            XCTFail("Failed to install LocalizableStringBundleUI.Strings: \(error)")
        }

        let applyLabel = String(localized: LocalizationKey.applyLabel.resource)
        XCTAssertEqual(applyLabel, "Apply")

        let resetLabel = String(localized: LocalizationKey.resetLabel.resource)
        XCTAssertEqual(resetLabel, "Reset")
    }

    @MainActor
    func testApplicationSupportStringsInstaller() {
        do {
            try Strings.install()
        } catch {
            XCTFail("Failed to install Strings: \(error)")
        }
    }

    @MainActor
    func testApplicationSupportStringLookups() {
        do {
            try Strings.install()
        } catch {
            XCTFail("Failed to install Strings: \(error)")
        }

        let testLabel = String(localized: LocalizationKey.testLabel.resource)
        XCTAssertEqual(testLabel, "Test")

        let anotherTestLabel = String(localized: LocalizationKey.anotherTestLabel.resource)
        XCTAssertEqual(anotherTestLabel, "Another Test")
    }
}

@MainActor
public enum Strings {
    @MainActor
    public static func install() throws {
        try LocalizedStringBundleInstaller.install(
            from: .module,
            installName: "Test-Strings",
            overwriteExisting: true)
    }
}

@MainActor
fileprivate func testName(_ key: String) -> LocalizationKey {
    LocalizationKey(key, bundle: .module, tableName: "Test")
}

public extension LocalizationKey {
    static let testLabel = testName("test")
    static let anotherTestLabel = testName("anotherTest")
}
