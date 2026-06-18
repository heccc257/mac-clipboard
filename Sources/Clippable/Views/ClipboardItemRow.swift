import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    var searchText: String = ""

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.text")
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.1)))

            VStack(alignment: .leading, spacing: 2) {
                Text(highlightedText)
                    .lineLimit(2)
                    .font(.system(size: 13))

                Text(relativeTime(item.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    /// The preview text with fuzzy-matched characters highlighted in yellow.
    private var highlightedText: AttributedString {
        let preview = item.previewText
        var attr = AttributedString(preview)
        attr.foregroundColor = .primary

        guard !searchText.isEmpty else { return attr }
        let indices = ClipboardItem.matchedIndices(in: preview, query: searchText)
        guard !indices.isEmpty else { return attr }

        for range in indices.rangeView {
            let lower = attr.index(attr.startIndex, offsetByCharacters: range.lowerBound)
            let upper = attr.index(attr.startIndex, offsetByCharacters: range.upperBound)
            attr[lower..<upper].backgroundColor = Color(red: 1.0, green: 0.85, blue: 0.25)
            attr[lower..<upper].foregroundColor = Color.black.opacity(0.9)
            attr[lower..<upper].inlinePresentationIntent = .stronglyEmphasized
        }
        return attr
    }

    private func relativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let min = Int(interval / 60)
            return "\(min)m ago"
        } else if interval < 86400 {
            let hr = Int(interval / 3600)
            return "\(hr)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
