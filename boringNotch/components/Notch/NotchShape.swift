//
//  NotchShape.swift
//  boringNotch
//
// Created by Kai Azim on 2023-08-24.
// Original source: https://github.com/MrKai77/DynamicNotchKit
// Modified by Alexander on 2025-05-18.

import SwiftUI

struct NotchShape: Shape {
    private var topCornerRadius: CGFloat
    private var bottomCornerRadius: CGFloat

    init(
        topCornerRadius: CGFloat? = nil,
        bottomCornerRadius: CGFloat? = nil
    ) {
        self.topCornerRadius = topCornerRadius ?? 6
        self.bottomCornerRadius = bottomCornerRadius ?? 14
    }

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            .init(
                topCornerRadius,
                bottomCornerRadius
            )
        }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.minX,
                y: rect.minY
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.minY + topCornerRadius
            ),
            control: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.maxY - bottomCornerRadius
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.minX + topCornerRadius + bottomCornerRadius,
                y: rect.maxY
            ),
            control: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - topCornerRadius - bottomCornerRadius,
                y: rect.maxY
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.maxY - bottomCornerRadius
            ),
            control: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.minY + topCornerRadius
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.maxX,
                y: rect.minY
            ),
            control: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX,
                y: rect.minY
            )
        )

        return path
    }
}

extension NotchShape {
    /// Just the side and bottom edges, without the flared corners at the top.
    var sidesOnly: NotchSidesShape {
        NotchSidesShape(topCornerRadius: topCornerRadius, bottomCornerRadius: bottomCornerRadius)
    }
}

struct NotchSidesShape: Shape {
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(topCornerRadius, bottomCornerRadius) }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + topCornerRadius, y: rect.minY + topCornerRadius))
        path.addLine(to: CGPoint(x: rect.minX + topCornerRadius, y: rect.maxY - bottomCornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topCornerRadius + bottomCornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.minX + topCornerRadius, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - topCornerRadius - bottomCornerRadius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - topCornerRadius, y: rect.maxY - bottomCornerRadius),
            control: CGPoint(x: rect.maxX - topCornerRadius, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - topCornerRadius, y: rect.minY + topCornerRadius))
        return path
    }
}

/// The bottom edge only: the two bottom corners and the flat run between them.
struct NotchBottomShape: Shape {
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(topCornerRadius, bottomCornerRadius) }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + topCornerRadius, y: rect.maxY - bottomCornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topCornerRadius + bottomCornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.minX + topCornerRadius, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - topCornerRadius - bottomCornerRadius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - topCornerRadius, y: rect.maxY - bottomCornerRadius),
            control: CGPoint(x: rect.maxX - topCornerRadius, y: rect.maxY)
        )
        return path
    }
}

extension NotchShape {
    var bottomOnly: NotchBottomShape {
        NotchBottomShape(topCornerRadius: topCornerRadius, bottomCornerRadius: bottomCornerRadius)
    }
}

/// The charge as a thin line just under the notch, filling from the left like
/// a progress bar. It sits outside the notch's outline on purpose: the notch is
/// a hole in the display, so a line drawn inside the shape would be hidden
/// wherever the shape lies over the hardware notch. It follows the bottom
/// corners and fades out as they curve up, so it never ends in a hard cut and
/// does not run up the sides.
struct BatteryEdgeLine: View {
    let outline: NotchShape
    let shape: NotchBottomShape
    /// 0...1
    let level: Double
    let charging: Bool

    /// Stroked on the outline's edge; the inner half is cut away, so this
    /// is twice the visible thickness.
    private static let strokeWidth: CGFloat = 3.2
    private static let margin: CGFloat = 8

    private var color: Color {
        if charging { return Color(red: 0.30, green: 0.85, blue: 0.40) }
        if level <= 0.2 { return Color(red: 1.0, green: 0.33, blue: 0.30) }
        return .white.opacity(0.9)
    }

    var body: some View {
        GeometryReader { proxy in
            let height = max(proxy.size.height, 1)
            let radius = max(shape.bottomCornerRadius, 1)
            let total = height + Self.margin * 2
            let width = max(proxy.size.width, 1)
            let totalWidth = width + Self.margin * 4
            let edge = shape.topCornerRadius
            ZStack {
                shape.stroke(Color.white.opacity(0.13), style: StrokeStyle(lineWidth: Self.strokeWidth, lineCap: .round))
                shape.trim(from: 0, to: min(max(level, 0), 1))
                    .stroke(color, style: StrokeStyle(lineWidth: Self.strokeWidth, lineCap: .round))
            }
            // Only the part outside the notch: cut the notch's own area out.
            .mask(
                ZStack {
                    Rectangle().fill(Color.black).padding(-Self.margin * 2)
                    outline.fill(Color.black).blendMode(.destinationOut)
                }
                .compositingGroup()
            )
            // Fade by horizontal position: fully clear on the lines that extend
            // the notch's sides, so the ends never reach past them, and solid
            // once the line is most of the way round each corner.
            .mask(
                Rectangle()
                    .fill(LinearGradient(
                        stops: [
                            .init(color: .clear, location: max(0, (edge + Self.margin * 2) / totalWidth)),
                            .init(color: .black, location: min(1, (edge + radius * 0.75 + Self.margin * 2) / totalWidth)),
                            .init(color: .black, location: max(0, (width - edge - radius * 0.75 + Self.margin * 2) / totalWidth)),
                            .init(color: .clear, location: min(1, (width - edge + Self.margin * 2) / totalWidth))
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: totalWidth, height: total)
            )
        }
        .animation(.easeInOut(duration: 0.4), value: level)
        .allowsHitTesting(false)
    }
}

#Preview {
    NotchShape(topCornerRadius: 6, bottomCornerRadius: 14)
        .frame(width: 200, height: 32)
        .padding(10)
}
