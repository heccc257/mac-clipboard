import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.text")
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.1)))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.previewText)
                    .lineLimit(2)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)

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
