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

public enum LocalizedStringsTextFile {

    public static func read(from url: URL) -> [String: String] {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
        var dict: [String: String] = [:]

        for line in text.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("\""), trimmed.contains("\" = \"") else { continue }

            // naive: "key" = "value";
            let parts = trimmed.split(separator: "\"", omittingEmptySubsequences: false)
            if parts.count >= 4 {
                dict[String(parts[1])] = String(parts[3])
            }
        }
        return dict
    }

    public static func write(_ dict: [String: String], to url: URL) throws {
        let keys = dict.keys.sorted()
        var out = ""
        for k in keys {
            let v = dict[k] ?? ""
            out += "\"\(escape(k))\" = \"\(escape(v))\";\n"
        }
        try atomicWrite(out, to: url)
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

    private static func escape(_ s: String) -> String {
        s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private static func atomicWrite(_ text: String, to url: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        let tmp = url.deletingLastPathComponent().appendingPathComponent(".tmp-\(UUID().uuidString)")
        try text.data(using: .utf8)!.write(to: tmp, options: .atomic)

        if fm.fileExists(atPath: url.path) {
            _ = try fm.replaceItemAt(url, withItemAt: tmp)
        } else {
            try fm.moveItem(at: tmp, to: url)
        }
    }
}
