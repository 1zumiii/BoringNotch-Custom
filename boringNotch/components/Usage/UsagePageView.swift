//
//  UsagePageView.swift
//  boringNotch
//
import Defaults
import SwiftUI

/// Claude and Codex usage, side by side: a ring per rate-limit window plus
/// slim bars for anything else measured.
struct UsagePageView: View {
    @ObservedObject private var store = UsageStore.shared

    var body: some View {
        HStack(spacing: 10) {
            ForEach(UsageSource.all) { source in
                UsageCard(source: source, snapshot: store.snapshots[source.id])
            }
        }
        .padding(.bottom, 14)
        .onAppear { store.beginWatching() }
        .onDisappear { store.endWatching() }
    }
}

private struct UsageCard: View {
    let source: UsageSource
    let snapshot: UsageSnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            if let snapshot {
                content(snapshot)
            } else {
                Spacer(minLength: 0)
                Text("No usage data yet")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07)))
    }

    private var header: some View {
        HStack(spacing: 6) {
            if let symbol = snapshot?.symbol {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(source.tint)
            }
            Text(snapshot?.title ?? source.id.capitalized)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
            Spacer(minLength: 0)
            if let model = snapshot?.model {
                Text(model)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    @ViewBuilder
    private func content(_ snapshot: UsageSnapshot) -> some View {
        HStack(spacing: 0) {
            ForEach(snapshot.windows, id: \.title) { metric in
                UsageRing(metric: metric, tint: source.tint)
                    .frame(maxWidth: .infinity)
            }
        }
        ForEach(snapshot.bars, id: \.title) { metric in
            UsageBar(metric: metric, tint: source.tint)
        }
        Spacer(minLength: 0)
        UpdatedLabel(date: snapshot.lastUpdatedDate)
    }
}

/// Green-ish at rest, amber then red as the limit gets close.
private func gaugeColor(used: Double, tint: Color) -> Color {
    switch used {
    case 0.9...: return Color(red: 1.0, green: 0.33, blue: 0.30)
    case 0.7...: return Color(red: 1.0, green: 0.70, blue: 0.20)
    default: return tint
    }
}

private struct UsageRing: View {
    let metric: UsageMetric
    let tint: Color

    private var used: Double { min(max(metric.normalizedValue ?? 0, 0), 1) }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.1), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: max(used, 0.015))
                    .stroke(
                        gaugeColor(used: used, tint: tint),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text(metric.formattedValue)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 52, height: 52)
            .animation(.smooth(duration: 0.6), value: used)

            Text(metric.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

private struct UsageBar: View {
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
                        .fill(gaugeColor(used: used, tint: tint))
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

private struct UpdatedLabel: View {
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
