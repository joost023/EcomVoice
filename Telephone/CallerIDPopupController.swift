// CallerIDPopupController.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import AppKit

/// Floating popup window that appears in the top-right corner of the screen
/// when an incoming call arrives and a CRM contact is found.
/// Auto-dismisses after 12 seconds or when the user clicks Dismiss.
@objc class CallerIDPopupController: NSWindowController {

    private static let autoDismissInterval: TimeInterval = 12.0
    private var dismissTimer: Timer?

    // MARK: - Factory

    /// Shows a popup for the given CRM contact and returns the controller.
    @objc @discardableResult
    static func show(for contact: CRMContact) -> CallerIDPopupController {
        let controller = CallerIDPopupController(contact: contact)
        controller.showWindow(nil)
        return controller
    }

    // MARK: - Init

    private init(contact: CRMContact) {
        let window = CallerIDPopupController.makeWindow()
        super.init(window: window)
        buildContentView(in: window, contact: contact)
        positionWindowTopRight(window)
        scheduleDismiss()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Public

    @objc func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        window?.orderOut(nil)
    }

    // MARK: - Window construction

    private static func makeWindow() -> NSWindow {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 160),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.appearance = NSAppearance(named: .darkAqua)
        return window
    }

    private func buildContentView(in window: NSWindow, contact: CRMContact) {
        guard let contentView = window.contentView else { return }

        // Rounded dark navy background
        let background = NSView()
        background.translatesAutoresizingMaskIntoConstraints = false
        background.wantsLayer = true
        background.layer?.backgroundColor = EcomVoiceColors.darkNavy.cgColor
        background.layer?.cornerRadius = 12
        background.layer?.borderWidth = 1
        background.layer?.borderColor = EcomVoiceColors.primaryBlue.withAlphaComponent(0.5).cgColor
        contentView.addSubview(background)

        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            background.topAnchor.constraint(equalTo: contentView.topAnchor),
            background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        // Accent bar at top
        let accentBar = NSView()
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        accentBar.wantsLayer = true
        accentBar.layer?.backgroundColor = EcomVoiceColors.primaryBlue.cgColor
        accentBar.layer?.cornerRadius = 2
        background.addSubview(accentBar)

        // Name label
        let nameLabel = makeLabel(text: contact.name.isEmpty ? contact.phoneNumber : contact.name,
                                  fontSize: 15, weight: .semibold, color: EcomVoiceColors.white)

        // Company label
        let companyLabel = makeLabel(text: contact.company,
                                     fontSize: 12, weight: .regular, color: EcomVoiceColors.accentBlue)
        companyLabel.isHidden = contact.company.isEmpty

        // Orders label
        let ordersText = contact.recentOrders.isEmpty ? "" : "Orders: " + contact.recentOrders.joined(separator: ", ")
        let ordersLabel = makeLabel(text: ordersText,
                                    fontSize: 11, weight: .regular, color: EcomVoiceColors.subtleWhite)
        ordersLabel.isHidden = contact.recentOrders.isEmpty

        // Notes label
        let notesLabel = makeLabel(text: contact.notes,
                                   fontSize: 11, weight: .regular, color: EcomVoiceColors.subtleWhite)
        notesLabel.isHidden = contact.notes.isEmpty
        notesLabel.maximumNumberOfLines = 2

        // Dismiss button
        let dismissButton = NSButton(title: "Dismiss", target: self, action: #selector(onDismissButton))
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.bezelStyle = .rounded
        dismissButton.isBordered = false
        dismissButton.wantsLayer = true
        dismissButton.layer?.backgroundColor = EcomVoiceColors.primaryBlue.withAlphaComponent(0.3).cgColor
        dismissButton.layer?.cornerRadius = 4
        dismissButton.contentTintColor = EcomVoiceColors.accentBlue
        dismissButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)

        // Stack view for content
        let stack = NSStackView(views: [nameLabel, companyLabel, ordersLabel, notesLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        background.addSubview(stack)
        background.addSubview(dismissButton)

        NSLayoutConstraint.activate([
            accentBar.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 12),
            accentBar.topAnchor.constraint(equalTo: background.topAnchor, constant: 12),
            accentBar.widthAnchor.constraint(equalToConstant: 3),
            accentBar.bottomAnchor.constraint(equalTo: dismissButton.topAnchor, constant: -12),

            stack.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: background.topAnchor, constant: 14),

            dismissButton.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -12),
            dismissButton.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -10),
            dismissButton.heightAnchor.constraint(equalToConstant: 22),
            dismissButton.widthAnchor.constraint(equalToConstant: 68),
        ])
    }

    // MARK: - Helpers

    private func makeLabel(text: String, fontSize: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        label.textColor = color
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        return label
    }

    private func positionWindowTopRight(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let windowSize = window.frame.size
        let margin: CGFloat = 16
        let origin = NSPoint(
            x: screenRect.maxX - windowSize.width - margin,
            y: screenRect.maxY - windowSize.height - margin
        )
        window.setFrameOrigin(origin)
    }

    private func scheduleDismiss() {
        dismissTimer = Timer.scheduledTimer(withTimeInterval: CallerIDPopupController.autoDismissInterval,
                                            repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    @objc private func onDismissButton() {
        dismiss()
    }
}
