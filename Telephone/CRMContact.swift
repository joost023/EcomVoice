// CRMContact.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import Foundation

/// Model representing a CRM lookup result for an incoming call.
@objc class CRMContact: NSObject {
    @objc let name: String
    @objc let company: String
    @objc let recentOrders: [String]
    @objc let notes: String
    @objc let phoneNumber: String

    @objc init(name: String, company: String, recentOrders: [String], notes: String, phoneNumber: String) {
        self.name = name
        self.company = company
        self.recentOrders = recentOrders
        self.notes = notes
        self.phoneNumber = phoneNumber
    }

    /// Parses a CRM contact from a JSON dictionary.
    /// Expected keys: "name", "company", "orders" (array), "notes"
    @objc convenience init?(json: [String: Any], phoneNumber: String) {
        guard !phoneNumber.isEmpty else { return nil }
        let name = json["name"] as? String ?? ""
        let company = json["company"] as? String ?? ""
        let orders = json["orders"] as? [String] ?? []
        let notes = json["notes"] as? String ?? ""
        self.init(name: name, company: company, recentOrders: Array(orders.prefix(3)), notes: notes, phoneNumber: phoneNumber)
    }
}
