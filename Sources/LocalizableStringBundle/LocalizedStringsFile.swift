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

public enum LocalizedStringsFile {

    public static func read(from url: URL) -> [String: String] {
        guard let data = try? Data(contentsOf: url) else { return [:] }

        do {
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)

            guard let dict = plist as? [String: Any] else { return [:] }

            var result: [String: String] = [:]
            for (key, value) in dict {
                if let stringValue = value as? String {
                    result[key] = stringValue
                }
            }
            return result
        } catch {
            return [:]
        }
    }

    public static func write(_ dict: [String: String], to url: URL) throws {
        let sortedDict = NSDictionary(
            dictionary: Dictionary(uniqueKeysWithValues: dict.sorted { $0.key < $1.key })
        )

        let data = try PropertyListSerialization.data(
            fromPropertyList: sortedDict,
            format: .xml,
            options: 0
        )

        try atomicWrite(data, to: url)
    }

    public static func set(_ key: String, _ value: String, in url: URL) throws {
        var dict = read(from: url)
        dict[key] = value
        try write(dict, to: url)
    }

    public static func remove(_ key: String, in url: URL) throws {
        var dict = read(from: url)
        dict.removeValue(forKey: key)
        try write(dict, to: url)
    }

    private static func atomicWrite(_ data: Data, to url: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        let tmp = url.deletingLastPathComponent().appendingPathComponent(".tmp-\(UUID().uuidString)")
        try data.write(to: tmp, options: .atomic)

        if fm.fileExists(atPath: url.path) {
            _ = try fm.replaceItemAt(url, withItemAt: tmp)
        } else {
            try fm.moveItem(at: tmp, to: url)
        }
    }
}
