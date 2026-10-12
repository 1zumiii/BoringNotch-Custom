//
//  ClipboardShelfView.swift
//  boringNotch
//
import SwiftUI

/// Temporary clipboard area, styled after the file shelf panel.
struct ClipboardShelfView: View {
    let animation: Animation?
    @ObservedObject private var clipboard = ClipboardManager.shared

    private let spacing: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                Color.white.opacity(0.1),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10])
            )
            .overlay {
                VStack(spacing: 8) {
                    header
                    content
                }
                .padding()
            }
            .transaction { transaction in
                transaction.animation = animation
            }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.on.clipboard")
                .foregroundStyle(.gray)
            Text("Clipboard")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(.gray)
            Spacer()
            Button {
                clipboard.clear()
            } label: {
                Label("Clear", systemImage: "trash")
                    .font(.system(.caption, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(.plain)
            .foregroundStyle(clipboard.entries.isEmpty ? .gray.opacity(0.5) : .white)
            .disabled(clipboard.entries.isEmpty)
        }
    }

    @ViewBuilder
    private var content: some View {
        if clipboard.entries.isEmpty {
            Text("Copied text shows up here")
                .foregroundStyle(.gray)
                .font(.system(.callout, design: .rounded))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: spacing) {
                    ForEach(clipboard.entries) { entry in
                        ClipboardEntryCard(entry: entry)
                    }
                }
            }
            .scrollIndicators(.never)
        }
    }
}

private struct ClipboardEntryCard: View {
    let entry: ClipboardEntry
    @State private var justCopied = false

    var body: some View {
        Button {
            ClipboardManager.shared.copy(entry)
            justCopied = true
            Task {
                try? await Task.sleep(for: .seconds(1))
                justCopied = false
            }
        } label: {
            Text(entry.text)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .lineLimit(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(8)
                .frame(width: 112)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                .overlay {
                    if justCopied {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.6))
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                        }
                    }
                }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Remove") { ClipboardManager.shared.remove(entry) }
        }
        .help("Click to copy again")
    }
}
