import SwiftUI
import AppKit
import Carbon

struct ClipboardHistoryView: View {
    @ObservedObject var monitor: ClipboardMonitor
    var onDismiss: () -> Void

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private static let topAnchorID = "top"

    private var filteredItems: [ClipboardItem] {
        let textItems = monitor.history.filter { $0.type == .text }
        if searchText.isEmpty {
            return textItems
        }
        // Fuzzy filter + rank by match score (best matches first).
        return textItems
            .compactMap { item -> (item: ClipboardItem, score: Int)? in
                guard let score = item.fuzzyScore(searchText) else { return nil }
                return (item, score)
            }
            .sorted { $0.score > $1.score }
            .map { $0.item }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clipboard history...", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                if !searchText.isEmpty {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { searchText = "" }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial)

            Divider()

            // History list (text only)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 1) {
                        // Invisible top anchor used to jump back to the newest
                        // item when the panel is reopened.
                        Color.clear.frame(height: 0).id(Self.topAnchorID)
                        ForEach(filteredItems) { item in
                            ClipboardItemRow(item: item, searchText: searchText)
                                .onTapGesture { pasteItem(item) }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .overlay {
                    if filteredItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clipboard")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text(searchText.isEmpty ? "No text history" : "No results")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .clipboardPanelDidShow)) { _ in
                    searchText = ""
                    proxy.scrollTo(Self.topAnchorID, anchor: .top)
                    // Defer focus until the panel has become key so the cursor
                    // reliably lands in the search field (typing works at once).
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isSearchFocused = true
                    }
                }
            }

            Divider()

            // Bottom bar
            HStack {
                Text("\(filteredItems.count) items")
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isSearchFocused = true
            }
        }
    }

    private func pasteItem(_ item: ClipboardItem) {
        monitor.copyToClipboard(item: item)
        onDismiss()
        // Fixed delay long enough for the previous app to regain key focus.
        // (Polling for frontmostApplication can fire too early — the app
        // becomes frontmost before its key window is ready to receive input.)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if IsSecureEventInputEnabled() {
                debugLog("paste: Secure Event Input is enabled — Cmd+V will be dropped by the system")
            }
            PasteSimulator.simulatePaste()
        }
    }
}
