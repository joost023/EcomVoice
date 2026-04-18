// MWIManager.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import Foundation
import AppKit

/// Notification posted when dialVoicemail() is called.
/// AppController or AccountController should observe this to initiate the call.
let MWIDialVoicemailNotificationName = Notification.Name("MWIDialVoicemailNotification")

/// Singleton that tracks Message Waiting Indicator (MWI / voicemail) state.
/// Receives `MWIStatusChangedNotification` posted by the PJSIP MWI callback
/// and exposes KVO-observable properties for the UI to bind.
@objc final class MWIManager: NSObject {

    @objc static let shared = MWIManager()

    /// Number of unread (new) voicemail messages.
    @objc dynamic var unreadMessages: Int = 0

    /// Total voicemail messages (new + old).
    @objc dynamic var totalMessages: Int = 0

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMWIStatusChanged(_:)),
            name: Notification.Name("MWIStatusChangedNotification"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Notification handling

    @objc private func handleMWIStatusChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let unread = (userInfo["unread"] as? NSNumber)?.intValue ?? 0
        let total  = (userInfo["total"]  as? NSNumber)?.intValue ?? 0
        unreadMessages = unread
        totalMessages  = total
    }

    // MARK: - Actions

    /// Initiate a call to *97 (Asterisk standard voicemail access code).
    /// Posts `MWIDialVoicemailNotification` on the main queue; the app's
    /// AccountController picks it up and places the actual call.
    @objc func dialVoicemail() {
        NotificationCenter.default.post(
            name: MWIDialVoicemailNotificationName,
            object: self,
            userInfo: ["destination": "*97"]
        )
    }
}
