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
import LoggerCategories
import SwiftUI

@MainActor
public extension Button where Label == Text {
    init(_ key: LocalizationKey, action: @escaping () -> Void) {
        self.init(action: action) { Text(key.resource) }
    }
}

@MainActor
public extension Label where Title == Text, Icon == Image {
    init(_ key: LocalizationKey, systemImage: String) {
        self.init { Text(key.resource) } icon: { Image(systemName: systemImage) }
    }
}

@MainActor
public extension Text {
    init(_ key: LocalizationKey) {
        self.init(key.resource)
    }
}

@MainActor
public extension View {
    func help(_ key: LocalizationKey) -> some View {
        help(String(localized: key.resource))
    }

    func accessibilityLabel(_ key: LocalizationKey) -> some View {
        accessibilityLabel(String(localized: key.resource))
    }

    func accessibilityHint(_ key: LocalizationKey) -> some View {
        accessibilityHint(String(localized: key.resource))
    }
}
