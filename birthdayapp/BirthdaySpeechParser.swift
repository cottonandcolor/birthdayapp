//
//  BirthdaySpeechParser.swift
//  birthdayapp
//

import Foundation

struct VoiceBirthdayFields {
    var name: String?
    var date: Date?
    var groupTag: String?
    var giftBudget: Double?
    var notes: String?
}

enum BirthdaySpeechParser {
    /// Longer phrases first so e.g. "new birthday" wins over "new".
    private static let leadingCommandPrefixes: [String] = [
        "new birthday ", "create birthday ", "add a birthday ", "add birthday ",
        "birthday for ", "remember ", "insert ", "create ", "birthday ",
        "save ", "add ", "new ", "for ", "put ", "log ",
    ]

    /// Parses name, date, group tag, gift budget, and notes from one spoken phrase.
    static func parseVoiceFields(_ text: String) -> VoiceBirthdayFields {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return VoiceBirthdayFields() }

        var date: Date?
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            var dateRange: NSRange?
            detector.enumerateMatches(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed)) { match, _, stop in
                guard let match, match.date != nil else { return }
                dateRange = match.range
                date = match.date
                stop.pointee = true
            }
            if let range = dateRange, let swiftRange = Range(range, in: trimmed) {
                trimmed = trimmed.replacingCharacters(in: swiftRange, with: "")
            }
            trimmed = trimmed
                .replacingOccurrences(of: " on ", with: " ", options: .caseInsensitive)
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ",.")))
        }

        var notes: String?
        var giftBudget: Double?
        var groupTag: String?

        for _ in 0 ..< 8 {
            var progressed = false

            if let v = stripTrailingMatch(
                pattern: #"(?i)\s+gift\s+ideas?\s+(.+)$"#,
                captureGroup: 1,
                from: &trimmed
            ) {
                notes = v
                progressed = true
            }
            if let v = stripTrailingMatch(
                pattern: #"(?i)\s+notes?\s+(.+)$"#,
                captureGroup: 1,
                from: &trimmed
            ) {
                notes = v
                progressed = true
            }
            if let v = stripTrailingBudget(from: &trimmed) {
                giftBudget = v
                progressed = true
            }
            if let v = stripTrailingMatch(
                pattern: #"(?i)\s+group\s+tag\s+(.+)$"#,
                captureGroup: 1,
                from: &trimmed
            ) {
                groupTag = v
                progressed = true
            }
            if let v = stripTrailingMatch(
                pattern: #"(?i)\s+the\s+tag\s+(.+)$"#,
                captureGroup: 1,
                from: &trimmed
            ) {
                groupTag = v
                progressed = true
            }
            if let v = stripTrailingMatch(
                pattern: #"(?i)\s+tag\s+is\s+(.+)$"#,
                captureGroup: 1,
                from: &trimmed
            ) {
                groupTag = v
                progressed = true
            }

            if !progressed { break }
        }

        let namePart = stripLeadingVoiceCommands(from: trimmed)
        let name = namePart.isEmpty ? nil : namePart

        return VoiceBirthdayFields(
            name: name,
            date: date,
            groupTag: nonEmptyTrimmed(groupTag),
            giftBudget: giftBudget,
            notes: nonEmptyTrimmed(notes)
        )
    }

    private static func nonEmptyTrimmed(_ s: String?) -> String? {
        guard let t = s?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        return t
    }

    /// Pulls a date via `NSDataDetector` and treats the rest of the phrase as the name (plus strips spoken “add …” commands).
    static func parse(_ text: String) -> (name: String?, date: Date?) {
        let f = parseVoiceFields(text)
        return (f.name, f.date)
    }

    private static func stripTrailingBudget(from s: inout String) -> Double? {
        let patterns = [
            #"(?i)\s+gift\s+budget\s+(\d+(?:\.\d+)?)(?:\s*(?:dollars?|bucks?))?$"#,
            #"(?i)\s+budget\s+(\d+(?:\.\d+)?)(?:\s*(?:dollars?|bucks?))?$"#,
        ]
        for pattern in patterns {
            guard let re = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(s.startIndex..., in: s)
            guard let match = re.firstMatch(in: s, range: range),
                  let numRange = Range(match.range(at: 1), in: s),
                  let fullRange = Range(match.range, in: s)
            else { continue }
            let numStr = String(s[numRange])
            guard let value = Double(numStr) else { continue }
            s.removeSubrange(fullRange)
            s = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return value
        }
        return nil
    }

    private static func stripTrailingMatch(
        pattern: String,
        captureGroup: Int,
        from s: inout String
    ) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(s.startIndex..., in: s)
        guard let match = re.firstMatch(in: s, range: range),
              captureGroup < match.numberOfRanges,
              let capRange = Range(match.range(at: captureGroup), in: s),
              let fullRange = Range(match.range, in: s)
        else { return nil }
        let captured = String(s[capRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !captured.isEmpty else { return nil }
        s.removeSubrange(fullRange)
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return captured
    }

    private static func stripLeadingVoiceCommands(from raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        for _ in 0 ..< 8 {
            let lower = s.lowercased()
            guard let prefix = leadingCommandPrefixes.first(where: { lower.hasPrefix($0) }) else { break }
            s = String(s.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return s
    }
}
