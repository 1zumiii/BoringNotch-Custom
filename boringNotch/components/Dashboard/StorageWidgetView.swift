//
//  StorageWidgetView.swift
//  boringNotch
//
import SwiftUI

/// Free space on the startup volume, read straight from the system.
struct StorageWidgetView: View {
    static let tint = Color(red: 0.30, green: 0.78, blue: 0.62)

    let size: CGSize

    private struct Capacity {
        let total: Int64
        let free: Int64
        var used: Int64 { max(total - free, 0) }
        var usedFraction: Double { total > 0 ? Double(used) / Double(total) : 0 }
    }

    private var showsRing: Bool { size.height >= 110 }

    private static func readCapacity() -> Capacity? {
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: keys),
              let total = values.volumeTotalCapacity,
              let free = values.volumeAvailableCapacityForImportantUsage
        else { return nil }
        return Capacity(total: Int64(total), free: free)
    }

    private static func bytes(_ value: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            let capacity = Self.readCapacity()
            DashboardCard(icon: "internaldrive.fill", tint: Self.tint, title: String(localized: "Storage")) {
                if let capacity {
                    Text(verbatim: "\(Int((capacity.usedFraction * 100).rounded()))%")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            } content: {
                if let capacity {
                    if showsRing {
                        ring(capacity)
                    } else {
                        compact(capacity)
                    }
                } else {
                    Text("No usage data yet")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private func ring(_ capacity: Capacity) -> some View {
        let diameter = min(max(size.height - 20 - 22 - 20 - 8, 34), 66)
        HStack(spacing: 12) {
            GaugeRing(
                fraction: capacity.usedFraction,
                valueText: "\(Int((capacity.usedFraction * 100).rounded()))%",
                label: String(localized: "Used"),
                tint: Self.tint,
                diameter: diameter
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.bytes(capacity.free))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("Free")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(verbatim: String(localized: "of") + " " + Self.bytes(capacity.total))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        Spacer(minLength: 0)
    }

    @ViewBuilder
    private func compact(_ capacity: Capacity) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            GaugeBar(
                fraction: capacity.usedFraction,
                valueText: "\(Int((capacity.usedFraction * 100).rounded()))%",
                label: String(localized: "Used"),
                tint: Self.tint
            )
            Text(verbatim: Self.bytes(capacity.free) + " " + String(localized: "Free").lowercased())
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        Spacer(minLength: 0)
    }
}
