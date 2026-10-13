//
//  UsagePager.swift
//  boringNotch
//
import Defaults
import SwiftUI

/// Gives the home screen's left side a second page. Wraps the existing
/// content untouched, so the only change to upstream views is where this is
/// used. Navigation is by the page dots: horizontal swipes already belong to
/// the music controls.
struct UsagePager<Home: View>: View {
    @Default(.showUsagePage) private var showUsagePage
    @State private var page = 0
    @ViewBuilder let home: () -> Home

    var body: some View {
        if showUsagePage {
            ZStack {
                home()
                    .opacity(page == 0 ? 1 : 0)
                    .offset(x: page == 0 ? 0 : -24)
                    .allowsHitTesting(page == 0)
                if page == 1 {
                    UsagePageView()
                        .transition(.opacity.combined(with: .offset(x: 24)))
                }
            }
            .overlay(alignment: .top) { dots }
            .animation(.smooth(duration: 0.28), value: page)
        } else {
            home()
        }
    }

    /// Real Buttons rather than tap gestures: the notch carries drag gestures
    /// with no minimum distance that would otherwise swallow the click.
    private var dots: some View {
        HStack(spacing: 2) {
            ForEach(0..<2, id: \.self) { index in
                Button {
                    page = index
                } label: {
                    Capsule()
                        .fill(Color.white.opacity(page == index ? 0.85 : 0.25))
                        .frame(width: page == index ? 16 : 6, height: 6)
                        .frame(width: 26, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.smooth(duration: 0.2), value: page)
    }
}

struct UsageSettingsSection: View {
    var body: some View {
        Section {
            Defaults.Toggle(key: .showUsagePage) {
                Text("Show usage page")
            }
        } header: {
            Text("Usage")
        } footer: {
            Text("A second page beside the player with Claude and Codex usage, read from the files RunCat's integration scripts write.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
