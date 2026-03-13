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

/// An editable localized label.
struct LocalizationEditableLabel: View {
    @Environment(LocalizationRuntime.self) private var localization
    @Environment(LocalizationEditorService.self) private var editor

    let key: LocalizationKey

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        Group {
            if editor.isEditingStrings {
                TextField("", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .onAppear { draft = editor.currentValue(for: key) }
                    .focused($focused)
                    .onSubmit {
                        Task { await editor.setSupportValue(draft, for: key) }
                    }
                    .contextMenu {
                        Button(.applyLabel) {
                            Task { await editor.setSupportValue(draft, for: key) }
                        }
                        Button(.resetLabel) {
                            Task { await editor.clearSupportValue(for: key) }
                        }
                    }
            } else {
                // Force refresh when support reloads
                Text(key.resource)
                    .id(localization.revision)
            }
        }
    }
}
