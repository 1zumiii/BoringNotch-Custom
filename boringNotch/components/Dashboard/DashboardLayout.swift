//
//  DashboardLayout.swift
//  boringNotch
//
import Defaults
import Foundation

/// Where one widget sits on the dashboard grid, in whole cells.
struct DashboardPlacement: Codable, Defaults.Serializable, Equatable, Identifiable {
    var id: String
    var enabled: Bool
    var col: Int
    var row: Int
    var width: Int
    var height: Int

    var colEnd: Int { col + width }
    var rowEnd: Int { row + height }

    func overlaps(_ other: DashboardPlacement) -> Bool {
        col < other.colEnd && other.col < colEnd && row < other.rowEnd && other.row < rowEnd
    }
}

enum DashboardGrid {
    static let columns = 6
    static let rows = 2
    static let spacing: CGFloat = 8
}

enum DashboardLayout {
    /// Used until the user changes anything, and by "Reset layout".
    static var defaults: [DashboardPlacement] {
        DashboardWidgets.all.map(\.defaultPlacement)
    }

    /// The stored layout with every registered widget present and every
    /// placement clamped to the grid and to its widget's size limits, so a
    /// layout saved by an older build can never produce an unusable page.
    static func normalized(_ stored: [DashboardPlacement]) -> [DashboardPlacement] {
        DashboardWidgets.all.map { info in
            var placement = stored.first { $0.id == info.id } ?? info.defaultPlacement
            placement.width = min(max(placement.width, info.minWidth), min(info.maxWidth, DashboardGrid.columns))
            placement.height = min(max(placement.height, info.minHeight), min(info.maxHeight, DashboardGrid.rows))
            placement.col = min(max(placement.col, 0), DashboardGrid.columns - placement.width)
            placement.row = min(max(placement.row, 0), DashboardGrid.rows - placement.height)
            return placement
        }
    }

    /// Fits on the grid, respects the widget's size limits, and doesn't sit
    /// on top of another enabled widget.
    static func isValid(_ placement: DashboardPlacement, among all: [DashboardPlacement]) -> Bool {
        guard let info = DashboardWidgets.info(for: placement.id),
              placement.col >= 0, placement.row >= 0,
              placement.colEnd <= DashboardGrid.columns,
              placement.rowEnd <= DashboardGrid.rows,
              (info.minWidth...info.maxWidth).contains(placement.width),
              (info.minHeight...info.maxHeight).contains(placement.height)
        else { return false }
        guard placement.enabled else { return true }
        return !all.contains { $0.id != placement.id && $0.enabled && $0.overlaps(placement) }
    }

    /// First free top-left cell (row by row) where a widget of this size fits.
    static func firstFreeSpot(for placement: DashboardPlacement, among all: [DashboardPlacement]) -> DashboardPlacement? {
        var candidate = placement
        candidate.enabled = true
        for row in 0...(DashboardGrid.rows - placement.height) {
            for col in 0...(DashboardGrid.columns - placement.width) {
                candidate.col = col
                candidate.row = row
                if isValid(candidate, among: all) { return candidate }
            }
        }
        return nil
    }
}
