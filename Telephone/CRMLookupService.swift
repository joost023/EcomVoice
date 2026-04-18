// CRMLookupService.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import Foundation

/// Asynchronous HTTP lookup service for CRM caller ID data.
/// Reads configuration from UserDefaults and calls back on the main queue.
@objc class CRMLookupService: NSObject {

    @objc static let shared = CRMLookupService()

    private override init() {}

    /// The webhook URL used for lookups. Reads from UserDefaults key "CRMWebhookURL".
    @objc var webhookURL: String {
        UserDefaults.standard.string(forKey: UserDefaultsKeys.crmWebhookURL) ?? ""
    }

    /// Whether CRM lookup is active. Reads from UserDefaults key "CRMEnabled".
    @objc var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKeys.crmEnabled)
    }

    /// Perform a CRM lookup for the given phone number.
    /// The completion closure is always called on the main queue.
    /// Returns nil silently when the service is disabled, unconfigured, or encounters an error.
    @objc func lookup(phoneNumber: String, completion: @escaping (CRMContact?) -> Void) {
        guard isEnabled, !webhookURL.isEmpty else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        let sanitized = sanitize(phoneNumber)
        guard !sanitized.isEmpty else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        guard var components = URLComponents(string: webhookURL) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "phone", value: sanitized))
        components.queryItems = queryItems

        guard let url = components.url else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        var request = URLRequest(url: url, timeoutInterval: 3.0)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let contact = CRMContact(json: json, phoneNumber: sanitized)
            else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            DispatchQueue.main.async { completion(contact) }
        }
        task.resume()
    }

    // MARK: - Private

    private func sanitize(_ phoneNumber: String) -> String {
        phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
}
