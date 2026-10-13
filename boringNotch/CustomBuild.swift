//
//  CustomBuild.swift
//  boringNotch
//

/// This is a customised build of Boring Notch. An official release installed
/// over it would silently remove the changes, so the updater is switched off:
/// it is never started, and every update control is disabled.
/// To pick up upstream changes, merge them into the fork and rebuild.
enum CustomBuild {
    static let updatesDisabled = true
}
