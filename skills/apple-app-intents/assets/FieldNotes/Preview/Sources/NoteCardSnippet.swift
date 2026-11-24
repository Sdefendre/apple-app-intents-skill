// Siri AI Developer Preview (OS 27.3). Compiled only with SIRI_AI_PREVIEW.
// Not yet compiled by this repository; see ObservationTool.swift.
#if SIRI_AI_PREVIEW
import AppIntents
import SwiftUI

/// Siri pre-renders this card into a static archive that can appear while the
/// app is not running, so everything it shows is computed synchronously here.
@available(iOS 27.3, macOS 27.3, *)
extension NoteEntity: SnippetRepresentableEntity {
    static var snippet: some EntitySnippetContent<NoteEntity> {
        CardSnippet(supportedFamilies: [.standard]) { note, _ in
            NoteCard(
                title: String(note.name.characters),
                recentLines: NoteCard.recentLines(note.content.map { String($0.characters) } ?? ""),
                isPinned: note.isPinned
            )
        }
    }
}

@available(iOS 27.3, macOS 27.3, *)
struct NoteCard: View {
    let title: String
    let recentLines: [String]
    let isPinned: Bool

    static func recentLines(_ content: String) -> [String] {
        Array(content.split(whereSeparator: \.isNewline).suffix(3).map(String.init))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: isPinned ? "pin.fill" : "note.text").font(.headline)
            if recentLines.isEmpty {
                Text("No entries yet").foregroundStyle(.secondary)
            } else {
                ForEach(recentLines, id: \.self) { Text($0).lineLimit(1) }
            }
        }
        .padding()
    }
}
#endif
