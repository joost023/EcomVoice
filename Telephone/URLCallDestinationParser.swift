// URLCallDestinationParser.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import Foundation

/// Parses various URL formats to extract a clean call destination
/// (phone number or SIP address).
///
/// Supported formats:
///   tel:+31612345678       -> +31612345678
///   tel:0612345678         -> 0612345678
///   sip:101@pbx.local      -> 101@pbx.local  (returned as-is)
///   ecomvoice:0612345678   -> 0612345678
///   ecomvoice://0612345678 -> 0612345678
@objc class URLCallDestinationParser: NSObject {

    /// Returns a clean destination string extracted from the given URL string,
    /// or nil if the URL cannot be parsed.
    @objc static func destination(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() {
            switch scheme {
            case "tel":
                return extractTelDestination(from: trimmed)
            case "sip":
                return extractSIPDestination(from: trimmed)
            case "ecomvoice":
                return extractEcomVoiceDestination(from: trimmed)
            default:
                break
            }
        }

        return nil
    }

    // MARK: - Private extractors

    private static func extractTelDestination(from urlString: String) -> String? {
        // tel:+31612345678 or tel:0612345678
        let withoutScheme = urlString.replacingOccurrences(of: "tel:", with: "", options: .caseInsensitive)
        let cleaned = withoutScheme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        // Allow leading + for E.164 format, strip everything else
        if cleaned.hasPrefix("+") {
            let digits = String(cleaned.dropFirst()).filter(\.isNumber)
            return digits.isEmpty ? nil : "+" + digits
        }
        let digits = cleaned.filter(\.isNumber)
        return digits.isEmpty ? nil : digits
    }

    private static func extractSIPDestination(from urlString: String) -> String? {
        // sip:user@host — return the part after "sip:"
        let withoutScheme = urlString.replacingOccurrences(of: "sip:", with: "", options: .caseInsensitive)
        let cleaned = withoutScheme.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func extractEcomVoiceDestination(from urlString: String) -> String? {
        // Strip ecomvoice:// or ecomvoice:
        var rest = urlString.replacingOccurrences(of: "ecomvoice://", with: "", options: .caseInsensitive)
        rest = rest.replacingOccurrences(of: "ecomvoice:", with: "", options: .caseInsensitive)
        let cleaned = rest.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("+") {
            let digits = String(cleaned.dropFirst()).filter(\.isNumber)
            return digits.isEmpty ? nil : "+" + digits
        }
        let digits = cleaned.filter(\.isNumber)
        return digits.isEmpty ? nil : digits
    }
}
