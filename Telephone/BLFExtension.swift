// BLFExtension.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import Foundation

@objc enum BLFStatus: Int {
    case unknown    // Subscription nog niet actief
    case available  // Online, niet in gesprek
    case busy       // In gesprek
    case ringing    // Telefoon gaat over
    case offline    // Niet geregistreerd / onbereikbaar
}

@objcMembers
final class BLFExtension: NSObject {
    let extensionNumber: String
    let displayName: String
    var sipHost: String
    @objc dynamic var status: BLFStatus
    var buddyId: Int32  // pjsua_buddy_id, -1 als niet geabonneerd

    init(extensionNumber: String, displayName: String, sipHost: String) {
        self.extensionNumber = extensionNumber
        self.displayName = displayName.isEmpty ? extensionNumber : displayName
        self.sipHost = sipHost
        self.status = .unknown
        self.buddyId = -1
    }

    var sipURI: String {
        "sip:\(extensionNumber)@\(sipHost)"
    }

    var statusColor: Any {
        switch status {
        case .available:  return EcomVoiceColors.statusGreen
        case .busy:       return EcomVoiceColors.statusRed
        case .ringing:    return EcomVoiceColors.statusOrange
        case .offline:    return EcomVoiceColors.statusGray
        case .unknown:    return EcomVoiceColors.statusGray
        @unknown default: return EcomVoiceColors.statusGray
        }
    }

    var statusLabel: String {
        switch status {
        case .available:  return "Beschikbaar"
        case .busy:       return "In gesprek"
        case .ringing:    return "Rinkelt"
        case .offline:    return "Offline"
        case .unknown:    return "Onbekend"
        @unknown default: return "Onbekend"
        }
    }
}

// MARK: - Persistence helpers

extension BLFExtension {
    convenience init?(dictionary: [String: String]) {
        guard let ext = dictionary["extension"], !ext.isEmpty,
              let host = dictionary["host"], !host.isEmpty else { return nil }
        let name = dictionary["displayName"] ?? ext
        self.init(extensionNumber: ext, displayName: name, sipHost: host)
    }

    var dictionary: [String: String] {
        ["extension": extensionNumber, "displayName": displayName, "host": sipHost]
    }
}
