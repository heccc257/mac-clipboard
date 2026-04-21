import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var monitor: ClipboardMonitor
    var onDismiss: () -> Void

    @State private var searchText = ""

    private var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return monitor.history
        }
        return monitor.history.filter { $0.matches(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clipboard history...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(.ultraThinMaterial)

            Divider()

            // History list
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No clipboard history" : "No results")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredItems) { item in
                            ClipboardItemRow(item: item) {
                                pasteItem(item)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            // Bottom bar
            HStack {
                Text("\(monitor.history.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("⌘⇧V")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.5)))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(width: 380, height: 500)
        .background(.ultraThinMaterial)
    }

    private func pasteItem(_ item: ClipboardItem) {
        monitor.copyToClipboard(item: item)
        onDismiss()
        // Simulate paste after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            PasteSimulator.simulatePaste()
        }
    }
}
