// DTMFMacro.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import Foundation

/// A named DTMF sequence that can be sent to an active call with a single click.
@objc final class DTMFMacro: NSObject {

    /// Human-readable label shown in the macro menu, e.g. "Voicemail PIN".
    @objc let name: String

    /// DTMF digit sequence to send, e.g. "*98#1234".
    /// Valid characters: 0-9, *, #, A-D.
    @objc let sequence: String

    /// Delay in milliseconds between individual digits. Default: 100 ms.
    @objc let delayMs: Int

    @objc init(name: String, sequence: String, delayMs: Int = 100) {
        self.name     = name
        self.sequence = sequence
        self.delayMs  = delayMs
        super.init()
    }

    /// Convenience initializer from a dictionary (e.g. from UserDefaults).
    @objc convenience init?(dictionary: [String: Any]) {
        guard
            let name     = dictionary["name"]     as? String, !name.isEmpty,
            let sequence = dictionary["sequence"] as? String, !sequence.isEmpty
        else { return nil }
        let delayMs = (dictionary["delayMs"] as? Int) ?? 100
        self.init(name: name, sequence: sequence, delayMs: delayMs)
    }

    /// Serialises the macro to a dictionary for UserDefaults storage.
    @objc var dictionary: [String: Any] {
        ["name": name, "sequence": sequence, "delayMs": delayMs]
    }
}
