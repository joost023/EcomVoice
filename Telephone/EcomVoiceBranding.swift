// EcomVoiceBranding.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import AppKit

@objc final class EcomVoiceBranding: NSObject {

    // Apply dark navy appearance + branding to the main account window.
    // Call from AccountWindowController.windowDidLoad.
    @objc static func applyToWindow(_ window: NSWindow) {
        // Force dark aqua appearance so system chrome matches the dark palette
        window.appearance = NSAppearance(named: .darkAqua)

        // Unified titlebar + content (removes the border line between bar and content)
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)

        // Dark navy background behind the content view
        window.backgroundColor = EcomVoiceColors.darkNavy

        // Subtle branding strip at the bottom of the window
        addBrandingStrip(to: window)
    }

    // Apply the same dark appearance to call windows (Call.xib windows).
    @objc static func applyToCallWindow(_ window: NSWindow) {
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = EcomVoiceColors.darkNavy
        window.titlebarAppearsTransparent = true
    }

    // MARK: - Private

    private static func addBrandingStrip(to window: NSWindow) {
        guard let contentView = window.contentView else { return }

        // Remove any existing branding strip to avoid duplicates on window reload
        contentView.subviews
            .filter { $0.accessibilityIdentifier() == "EcomVoiceBrandingStrip" }
            .forEach { $0.removeFromSuperview() }

        let strip = NSView()
        strip.translatesAutoresizingMaskIntoConstraints = false
        strip.wantsLayer = true
        strip.layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.25).cgColor
        strip.setAccessibilityIdentifier("EcomVoiceBrandingStrip")
        contentView.addSubview(strip)

        let label = NSTextField(labelWithString: "Powered by Ecommerce-manager.nl")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 9, weight: .regular)
        label.textColor = EcomVoiceColors.subtleWhite
        label.alignment = .center
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        strip.addSubview(label)

        NSLayoutConstraint.activate([
            strip.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            strip.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            strip.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            strip.heightAnchor.constraint(equalToConstant: 18),

            label.centerXAnchor.constraint(equalTo: strip.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: strip.centerYAnchor),
        ])
    }
}
