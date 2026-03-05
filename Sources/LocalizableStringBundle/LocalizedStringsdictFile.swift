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

public struct LocalizedStringsdictFile {
    public static func load(from url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return plist as? [String: Any] ?? [:]
    }

    public static func save(_ dict: [String: Any], to url: URL) throws {
        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        try atomicWrite(data, to: url)
    }

    /// Usage:
    /// ```
    /// try StringsdictFile.setPluralVariants(
    ///    key: "selectedDocumentCount",
    ///    valueType: "lld",
    ///    zero: "No books selected (LIVE)",
    ///    one: "%lld book selected (LIVE)",
    ///    other: "%lld books selected (LIVE)",
    ///    in: stringsdictURL
    /// )
    /// ```
    public static func setPluralVariants(
        key: String,
        valueType: String = "lld",
        zero: String,
        one: String,
        other: String,
        in url: URL
    ) throws {
        var root = (try? load(from: url)) ?? [:]

        let entry: [String: Any] = [
            "NSStringLocalizedFormatKey": "%#@value@",
            "value": [
                "NSStringFormatSpecTypeKey": "NSStringPluralRuleType",
                "NSStringFormatValueTypeKey": valueType,
                "zero": zero,
                "one": one,
                "other": other
            ]
        ]

        root[key] = entry
        try save(root, to: url)
    }

    private static func atomicWrite(_ data: Data, to url: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        let tmp = url.deletingLastPathComponent()
            .appendingPathComponent(".tmp-\(UUID().uuidString)")
        try data.write(to: tmp, options: .atomic)
        _ = try fm.replaceItemAt(url, withItemAt: tmp)
    }
}
