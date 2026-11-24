import Foundation

/// Formats one field observation as a single note line.
///
/// Siri AI can fill these values from conversation, so treat them as untrusted
/// input: reject empty subjects and implausible counts before any mutation, and
/// collapse line breaks so one observation cannot add several lines.
public enum FieldObservationLine {
    public static let maximumCount = 10_000

    public static func make(subject: String, count: Int, place: String) throws -> String {
        let cleanSubject = singleLine(subject)
        guard !cleanSubject.isEmpty, (1...maximumCount).contains(count) else { throw NoteError.unsupportedInput }
        let cleanPlace = singleLine(place)
        let line = "\(count) × \(cleanSubject)"
        return cleanPlace.isEmpty ? line : "\(line) — \(cleanPlace)"
    }

    private static func singleLine(_ value: String) -> String {
        value.split(whereSeparator: \.isNewline).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
