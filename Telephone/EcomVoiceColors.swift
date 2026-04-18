// EcomVoiceColors.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import AppKit

enum EcomVoiceColors {
    // Primary palette: dark navy + blue gradient
    static let darkNavy      = NSColor(red: 0.051, green: 0.106, blue: 0.243, alpha: 1.0) // #0D1B3E
    static let primaryBlue   = NSColor(red: 0.106, green: 0.310, blue: 0.847, alpha: 1.0) // #1B4FD8
    static let accentBlue    = NSColor(red: 0.231, green: 0.620, blue: 1.000, alpha: 1.0) // #3B9EFF
    static let lightBlue     = NSColor(red: 0.741, green: 0.871, blue: 1.000, alpha: 1.0) // #BDDEFD
    static let white         = NSColor.white
    static let subtleWhite   = NSColor(white: 1.0, alpha: 0.65)

    // Status indicator colors
    static let statusGreen   = NSColor(red: 0.204, green: 0.780, blue: 0.349, alpha: 1.0) // #34C759
    static let statusRed     = NSColor(red: 1.000, green: 0.231, blue: 0.188, alpha: 1.0) // #FF3B30
    static let statusOrange  = NSColor(red: 1.000, green: 0.584, blue: 0.000, alpha: 1.0) // #FF9500
    static let statusGray    = NSColor(white: 0.55, alpha: 1.0)

    // Gradient for window background (top → bottom)
    static var windowGradient: NSGradient {
        NSGradient(colors: [darkNavy, NSColor(red: 0.071, green: 0.157, blue: 0.341, alpha: 1.0)])!
    }
}
