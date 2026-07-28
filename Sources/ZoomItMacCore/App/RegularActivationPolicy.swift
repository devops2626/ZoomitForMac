import AppKit

/// ZoomIt normally runs as an accessory app (no Dock icon, not part of
/// Cmd-Tab) since it's a menu-bar utility. Some of its windows (Settings, the
/// video trim editor) are meant to be used like a regular app window, so they
/// need to show up in the Dock and the Cmd-Tab switcher while open.
///
/// Multiple such windows can be open at once, so this reference-counts the
/// requests for `.regular` activation policy: the app switches to `.regular`
/// when the first owner asks and back to `.accessory` only once every owner
/// has released it.
@MainActor
enum RegularActivationPolicy {
    private static var owners: Set<ObjectIdentifier> = []

    static func acquire(for owner: AnyObject) {
        let id = ObjectIdentifier(owner)
        guard owners.insert(id).inserted else { return }
        // Switching from .accessory needs a runloop hop to make the Dock tile
        // appear reliably.
        DispatchQueue.main.async {
            ZoomItAppIcon.apply()
            NSApp.setActivationPolicy(.regular)
            ZoomItAppIcon.apply()
        }
    }

    static func release(for owner: AnyObject) {
        owners.remove(ObjectIdentifier(owner))
        guard owners.isEmpty else { return }
        NSApp.setActivationPolicy(.accessory)
    }
}
