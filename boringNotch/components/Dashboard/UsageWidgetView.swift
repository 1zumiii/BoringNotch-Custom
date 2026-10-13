//
//  UsageWidgetView.swift
//  boringNotch
//
import SwiftUI

/// A Claude or Codex usage card that adapts to the cells it is given: tall
/// cards draw a ring per rate-limit window, short ones fall back to bars.
struct UsageWidgetView: View {
    let source: UsageSource
    let size: CGSize

    @ObservedObject private var store = UsageStore.shared

    private var snapshot: UsageSnapshot? { store.snapshots[source.id] }
    private var showsRings: Bool { size.height >= 110 }

    var body: some View {
        DashboardCard(
            icon: snapshot?.symbol ?? source.icon,
            tint: source.tint,
            title: snapshot?.title ?? source.displayName,
            subtitle: snapshot?.model
        ) {
            FreshnessPill(date: snapshot?.lastUpdatedDate)
        } content: {
            if let snapshot {
                if showsRings {
                    rings(snapshot)
                } else {
                    bars(snapshot)
                }
            } else {
                Text("No usage data yet")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: size.width, height: size.height)
        .onAppear { store.beginWatching() }
        .onDisappear { store.endWatching() }
    }

    @ViewBuilder
    private func rings(_ snapshot: UsageSnapshot) -> some View {
        let windows = snapshot.windows
        let bars = snapshot.bars
        let headerHeight: CGFloat = snapshot.model == nil ? 22 : 26
        // Card padding, header, chip under the ring, bar rows and the gaps.
        let reserved: CGFloat = 20 + headerHeight + 20 + CGFloat(bars.count) * 22 + 8 * CGFloat(1 + bars.count)
        let byHeight = size.height - reserved
        let byWidth = (size.width - 20) / CGFloat(max(windows.count, 1)) - 6
        let diameter = min(max(min(byHeight, byWidth), 34), 66)

        HStack(spacing: 0) {
            ForEach(windows, id: \.title) { metric in
                GaugeRing(
                    fraction: metric.normalizedValue ?? 0,
                    valueText: metric.formattedValue,
                    label: metric.title,
                    tint: source.tint,
                    diameter: diameter
                )
                .frame(maxWidth: .infinity)
            }
        }
        ForEach(bars, id: \.title) { metric in
            GaugeBar(
                fraction: metric.normalizedValue ?? 0,
                valueText: metric.formattedValue,
                label: metric.title,
                tint: source.tint
            )
        }
        Spacer(minLength: 0)
    }

    @ViewBuilder
    private func bars(_ snapshot: UsageSnapshot) -> some View {
        VStack(spacing: 7) {
            ForEach(snapshot.windows + snapshot.bars, id: \.title) { metric in
                GaugeBar(
                    fraction: metric.normalizedValue ?? 0,
                    valueText: metric.formattedValue,
                    label: metric.title,
                    tint: source.tint
                )
            }
        }
        Spacer(minLength: 0)
    }
}
