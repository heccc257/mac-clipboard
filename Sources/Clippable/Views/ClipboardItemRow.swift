import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Type icon
                typeIcon
                    .frame(width: 32, height: 32)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.1)))

                // Content preview
                VStack(alignment: .leading, spacing: 2) {
                    contentPreview
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
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    @ViewBuilder
    private var typeIcon: some View {
        switch item.type {
        case .text:
            Image(systemName: "doc.text")
                .foregroundColor(.blue)
        case .image:
            if let fileName = item.imageFileName,
               let data = StorageManager.shared.loadImageData(fileName: fileName),
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.green)
            }
        case .filePaths:
            Image(systemName: "folder")
                .foregroundColor(.orange)
        }
    }

    @ViewBuilder
    private var contentPreview: some View {
        switch item.type {
        case .text:
            Text(item.previewText)
                .foregroundColor(.primary)
        case .image:
            Text("Image")
                .foregroundColor(.primary)
        case .filePaths:
            Text(item.previewText)
                .foregroundColor(.primary)
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
