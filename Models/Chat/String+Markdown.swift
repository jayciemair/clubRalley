//
//  String+Markdown.swift
//  Checkpoint
//
//  Parses basic markdown formatting for chat messages
//

import SwiftUI

extension String {
    /// Converts markdown-style formatting to AttributedString
    /// Supports: **bold**, *italic*
    func parseBasicMarkdown() -> AttributedString {
        var result = self

        // First, handle bold text
        let boldPattern = "\\*\\*(.+?)\\*\\*"
        let boldRegex = try? NSRegularExpression(pattern: boldPattern, options: [])
        let nsRange = NSRange(result.startIndex..<result.endIndex, in: result)

        var boldRanges: [(String, Range<String.Index>)] = []

        if let regex = boldRegex {
            let matches = regex.matches(in: result, options: [], range: nsRange)

            for match in matches.reversed() {
                if let range = Range(match.range, in: result),
                   let contentRange = Range(match.range(at: 1), in: result) {
                    let content = String(result[contentRange])
                    boldRanges.insert((content, range), at: 0)
                    result.replaceSubrange(range, with: content)
                }
            }
        }

        // Then, handle italic text (single asterisks)
        let italicPattern = "\\*([^\\*]+?)\\*"
        let italicRegex = try? NSRegularExpression(pattern: italicPattern, options: [])
        let nsRange2 = NSRange(result.startIndex..<result.endIndex, in: result)

        var italicRanges: [(String, Range<String.Index>)] = []

        if let regex = italicRegex {
            let matches = regex.matches(in: result, options: [], range: nsRange2)

            for match in matches.reversed() {
                if let range = Range(match.range, in: result),
                   let contentRange = Range(match.range(at: 1), in: result) {
                    let content = String(result[contentRange])
                    italicRanges.insert((content, range), at: 0)
                    result.replaceSubrange(range, with: content)
                }
            }
        }

        // Create attributed string with formatting
        var attributed = AttributedString(result)

        // Apply bold formatting
        for (content, _) in boldRanges {
            if let range = attributed.range(of: content) {
                attributed[range].font = .custom("Satoshi-Bold", size: 16)
            }
        }

        // Apply italic formatting
        for (content, _) in italicRanges {
            if let range = attributed.range(of: content) {
                attributed[range].font = .custom("Satoshi-Medium", size: 16)
                // Note: Using Medium as italic since Satoshi-Italic might not exist
            }
        }

        return attributed
    }

    /// Simple version that just removes markdown syntax
    func stripMarkdown() -> String {
        var result = self

        // Remove bold markers
        result = result.replacingOccurrences(of: "**", with: "")

        // Remove italic markers
        result = result.replacingOccurrences(of: "*", with: "")

        return result
    }
}