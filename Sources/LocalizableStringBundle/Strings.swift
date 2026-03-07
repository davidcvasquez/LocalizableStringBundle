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

import SwiftUI
import OSLog
import LoggerCategories

public enum Strings {
    public static func install() throws {
        try LocalizedStringBundleInstaller.install(from: .module)
    }
}

fileprivate func menuName(_ key: String) -> LocalizationKey {
    LocalizationKey(key, bundle: .module, tableName: "MenuNames")
}

public extension LocalizationKey {

    static let applyLabel = menuName("apply")
    static let resetLabel = menuName("reset")
}
