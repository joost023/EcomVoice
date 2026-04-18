// BlindTransferViewController.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import AppKit

// Shown as a sheet on the call window. User enters extension/number → blind transfer.
@objcMembers
final class BlindTransferViewController: NSViewController {

    var onTransfer: ((String) -> Void)?

    private var titleLabel: NSTextField!
    private var destinationField: NSTextField!
    private var transferButton: NSButton!
    private var cancelButton: NSButton!

    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(destinationField)
    }

    // MARK: - Layout

    private func buildLayout() {
        titleLabel = NSTextField(labelWithString: "Doorverbinden naar")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .labelColor

        let subtitleLabel = NSTextField(labelWithString: "Voer een extensie of telefoonnummer in.")
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = NSFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor

        destinationField = NSTextField()
        destinationField.translatesAutoresizingMaskIntoConstraints = false
        destinationField.placeholderString = "Extensie of nummer (bijv. 102)"
        destinationField.bezelStyle = .roundedBezel
        destinationField.font = NSFont.systemFont(ofSize: 14)
        destinationField.delegate = self

        transferButton = NSButton(title: "Doorverbinden", target: self, action: #selector(performTransfer))
        transferButton.translatesAutoresizingMaskIntoConstraints = false
        transferButton.bezelStyle = .rounded
        transferButton.keyEquivalent = "\r"
        transferButton.isEnabled = false

        cancelButton = NSButton(title: "Annuleren", target: self, action: #selector(cancel))
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"

        let buttonStack = NSStackView(views: [cancelButton, transferButton])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8

        [titleLabel, subtitleLabel, destinationField, buttonStack].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 340),

            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            destinationField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            destinationField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            destinationField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            buttonStack.topAnchor.constraint(equalTo: destinationField.bottomAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            view.bottomAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 20),
        ])
    }

    // MARK: - Actions

    @objc private func performTransfer() {
        let destination = destinationField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !destination.isEmpty else { return }
        dismiss(self)
        onTransfer?(destination)
    }

    @objc private func cancel() {
        dismiss(self)
    }
}

// MARK: - NSTextFieldDelegate

extension BlindTransferViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let text = destinationField.stringValue.trimmingCharacters(in: .whitespaces)
        transferButton.isEnabled = !text.isEmpty
    }
}
