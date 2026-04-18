// DTMFMacroManager.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import Foundation

/// Manages a persisted list of DTMF macros and sends them to an active call.
@objc final class DTMFMacroManager: NSObject {

    @objc static let shared = DTMFMacroManager()

    /// The current list of macros, loaded from UserDefaults.
    @objc var macros: [DTMFMacro] = []

    private override init() {
        super.init()
        loadMacros()
    }

    // MARK: - Persistence

    /// Loads macros from UserDefaults.
    @objc func loadMacros() {
        let stored = UserDefaults.standard.array(forKey: UserDefaultsKeys.dtmfMacros) as? [[String: Any]] ?? []
        macros = stored.compactMap { DTMFMacro(dictionary: $0) }
    }

    /// Persists macros to UserDefaults.
    @objc func saveMacros() {
        let dicts = macros.map { $0.dictionary }
        UserDefaults.standard.set(dicts, forKey: UserDefaultsKeys.dtmfMacros)
    }

    // MARK: - Sending

    /// Sends all digits of a macro to the given active call with inter-digit delays.
    /// Each character in `macro.sequence` is sent as a separate DTMF digit.
    /// The delay between digits is `macro.delayMs` milliseconds.
    @objc func sendMacro(_ macro: DTMFMacro, to call: AKSIPCall) {
        let digits = Array(macro.sequence)
        let delayUs: useconds_t = useconds_t(macro.delayMs) * 1000

        DispatchQueue.global(qos: .userInitiated).async {
            for digit in digits {
                let digitString = String(digit)
                DispatchQueue.main.async {
                    call.sendDTMFDigits(digitString)
                }
                if delayUs > 0 {
                    usleep(delayUs)
                }
            }
        }
    }
}
