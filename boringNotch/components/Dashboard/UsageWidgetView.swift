//
//  UsageWidgetView.swift
//  boringNotch
//
import SwiftUI

/// A Claude or Codex usage card that adapts to the cells it is given:
/// tall cards draw a ring per rate-limit window, short ones fall back to
/// compact bars so everything still fits.
struct UsageWidgetView: View {
    let source: UsageSource
    let size: CGSize

    @ObservedObject private var store = UsageStore.shared

    private var snapshot: UsageSnapshot? { store.snapshots[source.id] }
    private var showsRings: Bool { size.height >= 110 }
    private var isNarrow: Bool { size.width < 170 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
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
        .padding(10)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07)))
        .onAppear { store.beginWatching() }
        .onDisappear { store.endWatching() }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: snapshot?.symbol ?? source.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(source.tint)
            Text(snapshot?.title ?? source.displayName)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
            Spacer(minLength: 0)
            if !isNarrow, let model = snapshot?.model {
                Text(model)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if !isNarrow {
                UsageUpdatedLabel(date: snapshot?.lastUpdatedDate)
            }
        }
    }

    // MARK: Tall layout

    @ViewBuilder
    private func rings(_ snapshot: UsageSnapshot) -> some View {
        let windows = snapshot.windows
        let bars = snapshot.bars
        // What the rest of the card needs (padding, header, ring label, bars
        // and the gaps between them), so the rings take what is left.
        let reserved: CGFloat = 20 + 16 + 13 + CGFloat(bars.count) * 20 + 12
        let byHeight = size.height - reserved
        let byWidth = (size.width - 20) / CGFloat(max(windows.count, 1)) - 8
        let diameter = min(max(min(byHeight, byWidth), 30), 60)

        HStack(spacing: 0) {
            ForEach(windows, id: \.title) { metric in
                UsageRing(metric: metric, tint: source.tint, diameter: diameter)
                    .frame(maxWidth: .infinity)
            }
        }
        ForEach(bars, id: \.title) { metric in
            UsageBarRow(metric: metric, tint: source.tint)
        }
        Spacer(minLength: 0)
        if isNarrow {
            UsageUpdatedLabel(date: snapshot.lastUpdatedDate)
        }
    }

    // MARK: Short layout

    @ViewBuilder
    private func bars(_ snapshot: UsageSnapshot) -> some View {
        let rows = snapshot.windows + snapshot.bars
        VStack(spacing: 5) {
            ForEach(rows, id: \.title) { metric in
                UsageBarRow(metric: metric, tint: source.tint)
            }
        }
        Spacer(minLength: 0)
    }
}

/// Green-ish at rest, amber then red as the limit gets close.
func usageGaugeColor(used: Double, tint: Color) -> Color {
    switch used {
    case 0.9...: return Color(red: 1.0, green: 0.33, blue: 0.30)
    case 0.7...: return Color(red: 1.0, green: 0.70, blue: 0.20)
    default: return tint
    }
}

private struct UsageRing: View {
    let metric: UsageMetric
    let tint: Color
    let diameter: CGFloat

    private var used: Double { min(max(metric.normalizedValue ?? 0, 0), 1) }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.1), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: max(used, 0.015))
                    .stroke(
                        usageGaugeColor(used: used, tint: tint),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text(metric.formattedValue)
                    .font(.system(size: diameter > 44 ? 12 : 10, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
            }
            .frame(width: diameter, height: diameter)
            .animation(.smooth(duration: 0.6), value: used)

            Text(metric.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

private struct UsageBarRow: View {
    let metric: UsageMetric
    let tint: Color

    private var used: Double { min(max(metric.normalizedValue ?? 0, 0), 1) }

    var body: some View {
        HStack(spacing: 6) {
            Text(metric.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
                .lineLimit(1)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(usageGaugeColor(used: used, tint: tint))
                        .frame(width: max(proxy.size.width * used, 4))
                }
            }
            .frame(height: 5)
            Text(metric.formattedValue)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
                .frame(width: 34, alignment: .trailing)
        }
    }
}

private struct UsageUpdatedLabel: View {
    let date: Date?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text(text(at: context.date))
            }
            .font(.system(size: 9))
            .foregroundStyle(isStale(at: context.date) ? Color.orange.opacity(0.9) : .secondary)
        }
    }

    private func isStale(at now: Date) -> Bool {
        guard let date else { return true }
        return now.timeIntervalSince(date) > 6 * 3600
    }

    private func text(at now: Date) -> String {
        guard let date else { return "—" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
