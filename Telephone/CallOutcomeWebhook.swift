// CallOutcomeWebhook.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import Foundation

/// Fire-and-forget webhook that POSTs a JSON summary whenever a call ends.
/// Configuration is read from UserDefaults at call time so changes take effect
/// without restarting the app.
@objc final class CallOutcomeWebhook: NSObject {

    @objc static let shared = CallOutcomeWebhook()

    private override init() {}

    /// The URL to POST call outcome events to.
    /// Reads `UserDefaultsKeys.callOutcomeWebhookURL` on every call.
    @objc var webhookURL: String {
        UserDefaults.standard.string(forKey: UserDefaultsKeys.callOutcomeWebhookURL) ?? ""
    }

    /// Whether the webhook is active.
    /// Reads `UserDefaultsKeys.callOutcomeWebhookEnabled` on every call.
    @objc var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKeys.callOutcomeWebhookEnabled)
    }

    /// Called when a call ends. Sends a fire-and-forget POST to the configured URL.
    /// Safe to call from any thread; dispatches the network request asynchronously.
    @objc func reportCallEnded(
        remoteNumber: String,
        direction: String,
        durationSeconds: Int,
        wasAnswered: Bool,
        agentExtension: String
    ) {
        guard isEnabled, !webhookURL.isEmpty else { return }
        guard let url = URL(string: webhookURL) else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let payload: [String: Any] = [
            "event": "call_ended",
            "remote_number": remoteNumber,
            "direction": direction,
            "duration_seconds": durationSeconds,
            "was_answered": wasAnswered,
            "agent_extension": agentExtension,
            "timestamp": timestamp
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url, timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        // Fire-and-forget: ignore result
        let task = URLSession.shared.dataTask(with: request)
        task.resume()
    }
}
