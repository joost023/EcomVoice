// CRMPreferencesViewController.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import AppKit

/// Preferences tab for CRM caller ID lookup, call outcome webhook, and DTMF macros.
/// Programmatic NSViewController (no XIB).
@objcMembers
final class CRMPreferencesViewController: NSViewController {

    // MARK: - Subviews

    private var crmEnabledCheckbox: NSButton!
    private var crmWebhookField: NSTextField!
    private var crmTestButton: NSButton!

    private var webhookEnabledCheckbox: NSButton!
    private var webhookURLField: NSTextField!

    private var macrosTableView: NSTableView!
    private var macroAddButton: NSButton!
    private var macroRemoveButton: NSButton!

    private var macros: [DTMFMacro] = []

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "CRM"
        macros = DTMFMacroManager.shared.macros
        buildLayout()
    }

    // MARK: - Layout

    private func buildLayout() {
        let defaults = UserDefaults.standard

        // ---- Section: CRM Caller ID ----
        let crmSectionLabel = makeSectionLabel("CRM Caller ID")
        view.addSubview(crmSectionLabel)

        crmEnabledCheckbox = NSButton(
            checkboxWithTitle: "CRM caller ID opzoeken bij inkomende gesprekken",
            target: self,
            action: #selector(toggleCRMEnabled)
        )
        crmEnabledCheckbox.translatesAutoresizingMaskIntoConstraints = false
        crmEnabledCheckbox.state = defaults.bool(forKey: UserDefaultsKeys.crmEnabled) ? .on : .off
        crmEnabledCheckbox.contentTintColor = EcomVoiceColors.accentBlue
        view.addSubview(crmEnabledCheckbox)

        let crmURLLabel = makeLabel("Webhook URL voor CRM lookup (GET ?phone=…):")
        view.addSubview(crmURLLabel)

        crmWebhookField = NSTextField()
        crmWebhookField.translatesAutoresizingMaskIntoConstraints = false
        crmWebhookField.placeholderString = "https://api.yourapp.com/crm/lookup"
        crmWebhookField.stringValue = defaults.string(forKey: UserDefaultsKeys.crmWebhookURL) ?? ""
        crmWebhookField.bezelStyle = .roundedBezel
        view.addSubview(crmWebhookField)

        crmTestButton = NSButton(title: "Testen", target: self, action: #selector(testCRMLookup))
        crmTestButton.translatesAutoresizingMaskIntoConstraints = false
        crmTestButton.bezelStyle = .rounded
        view.addSubview(crmTestButton)

        // ---- Section: Call Outcome Webhook ----
        let webhookSectionLabel = makeSectionLabel("Gespreksresultaat Webhook")
        view.addSubview(webhookSectionLabel)

        webhookEnabledCheckbox = NSButton(
            checkboxWithTitle: "Gespreksresultaat versturen na elk gesprek",
            target: self,
            action: #selector(toggleWebhookEnabled)
        )
        webhookEnabledCheckbox.translatesAutoresizingMaskIntoConstraints = false
        webhookEnabledCheckbox.state = defaults.bool(forKey: UserDefaultsKeys.callOutcomeWebhookEnabled) ? .on : .off
        webhookEnabledCheckbox.contentTintColor = EcomVoiceColors.accentBlue
        view.addSubview(webhookEnabledCheckbox)

        let webhookURLLabel = makeLabel("Webhook URL voor gespreksresultaat (POST JSON):")
        view.addSubview(webhookURLLabel)

        webhookURLField = NSTextField()
        webhookURLField.translatesAutoresizingMaskIntoConstraints = false
        webhookURLField.placeholderString = "https://api.yourapp.com/webhooks/call-ended"
        webhookURLField.stringValue = defaults.string(forKey: UserDefaultsKeys.callOutcomeWebhookURL) ?? ""
        webhookURLField.bezelStyle = .roundedBezel
        view.addSubview(webhookURLField)

        // ---- Section: DTMF Macros ----
        let macrosSectionLabel = makeSectionLabel("DTMF Macro's")
        view.addSubview(macrosSectionLabel)

        let macrosLabel = makeLabel("Klik op DTMF in een actief gesprek om een macro te verzenden:")
        view.addSubview(macrosLabel)

        macrosTableView = NSTableView()
        macrosTableView.addTableColumn(makeColumn(id: "name", title: "Naam", width: 140))
        macrosTableView.addTableColumn(makeColumn(id: "sequence", title: "Reeks", width: 130))
        macrosTableView.addTableColumn(makeColumn(id: "delayMs", title: "Delay (ms)", width: 80))
        macrosTableView.dataSource = self
        macrosTableView.delegate = self
        macrosTableView.rowHeight = 22
        macrosTableView.usesAlternatingRowBackgroundColors = true

        let macrosScrollView = NSScrollView()
        macrosScrollView.translatesAutoresizingMaskIntoConstraints = false
        macrosScrollView.documentView = macrosTableView
        macrosScrollView.hasVerticalScroller = true
        macrosScrollView.borderType = .bezelBorder
        view.addSubview(macrosScrollView)

        macroAddButton = NSButton(title: "+", target: self, action: #selector(addMacro))
        macroAddButton.translatesAutoresizingMaskIntoConstraints = false
        macroAddButton.bezelStyle = .roundRect

        macroRemoveButton = NSButton(title: "−", target: self, action: #selector(removeMacro))
        macroRemoveButton.translatesAutoresizingMaskIntoConstraints = false
        macroRemoveButton.bezelStyle = .roundRect

        view.addSubview(macroAddButton)
        view.addSubview(macroRemoveButton)

        // ---- Save button ----
        let saveButton = NSButton(title: "Opslaan", target: self, action: #selector(savePreferences))
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        view.addSubview(saveButton)

        // ---- Constraints ----
        NSLayoutConstraint.activate([
            // CRM section
            crmSectionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            crmSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            crmEnabledCheckbox.topAnchor.constraint(equalTo: crmSectionLabel.bottomAnchor, constant: 8),
            crmEnabledCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            crmURLLabel.topAnchor.constraint(equalTo: crmEnabledCheckbox.bottomAnchor, constant: 10),
            crmURLLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            crmWebhookField.topAnchor.constraint(equalTo: crmURLLabel.bottomAnchor, constant: 4),
            crmWebhookField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            crmWebhookField.trailingAnchor.constraint(equalTo: crmTestButton.leadingAnchor, constant: -8),

            crmTestButton.centerYAnchor.constraint(equalTo: crmWebhookField.centerYAnchor),
            crmTestButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            crmTestButton.widthAnchor.constraint(equalToConstant: 80),

            // Webhook section
            webhookSectionLabel.topAnchor.constraint(equalTo: crmWebhookField.bottomAnchor, constant: 20),
            webhookSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            webhookEnabledCheckbox.topAnchor.constraint(equalTo: webhookSectionLabel.bottomAnchor, constant: 8),
            webhookEnabledCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            webhookURLLabel.topAnchor.constraint(equalTo: webhookEnabledCheckbox.bottomAnchor, constant: 10),
            webhookURLLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            webhookURLField.topAnchor.constraint(equalTo: webhookURLLabel.bottomAnchor, constant: 4),
            webhookURLField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            webhookURLField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // DTMF Macros section
            macrosSectionLabel.topAnchor.constraint(equalTo: webhookURLField.bottomAnchor, constant: 20),
            macrosSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            macrosLabel.topAnchor.constraint(equalTo: macrosSectionLabel.bottomAnchor, constant: 6),
            macrosLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            macrosScrollView.topAnchor.constraint(equalTo: macrosLabel.bottomAnchor, constant: 4),
            macrosScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            macrosScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            macrosScrollView.heightAnchor.constraint(equalToConstant: 120),

            macroAddButton.topAnchor.constraint(equalTo: macrosScrollView.bottomAnchor, constant: 6),
            macroAddButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            macroAddButton.widthAnchor.constraint(equalToConstant: 28),

            macroRemoveButton.topAnchor.constraint(equalTo: macrosScrollView.bottomAnchor, constant: 6),
            macroRemoveButton.leadingAnchor.constraint(equalTo: macroAddButton.trailingAnchor, constant: 4),
            macroRemoveButton.widthAnchor.constraint(equalToConstant: 28),

            saveButton.topAnchor.constraint(equalTo: macroAddButton.bottomAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            view.bottomAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 20),
            view.widthAnchor.constraint(greaterThanOrEqualToConstant: 480),
        ])
    }

    // MARK: - Actions

    @objc private func toggleCRMEnabled() {}
    @objc private func toggleWebhookEnabled() {}

    @objc private func testCRMLookup() {
        let urlString = crmWebhookField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !urlString.isEmpty else {
            showAlert(message: "Voer eerst een webhook URL in.", style: .warning)
            return
        }

        let savedURL = UserDefaults.standard.string(forKey: UserDefaultsKeys.crmWebhookURL)
        let savedEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.crmEnabled)
        UserDefaults.standard.set(urlString, forKey: UserDefaultsKeys.crmWebhookURL)
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.crmEnabled)

        CRMLookupService.shared.lookup(phoneNumber: "0612345678") { [weak self] contact in
            UserDefaults.standard.set(savedURL, forKey: UserDefaultsKeys.crmWebhookURL)
            UserDefaults.standard.set(savedEnabled, forKey: UserDefaultsKeys.crmEnabled)

            if let contact = contact {
                self?.showAlert(
                    message: "CRM test geslaagd!\n\nNaam: \(contact.name)\nBedrijf: \(contact.company)",
                    style: .informational
                )
            } else {
                self?.showAlert(
                    message: "Geen resultaat ontvangen. Controleer de URL en of de service beschikbaar is.",
                    style: .warning
                )
            }
        }
    }

    @objc private func addMacro() {
        macros.append(DTMFMacro(name: "Nieuw macro", sequence: "0", delayMs: 100))
        macrosTableView.reloadData()
        let newRow = macros.count - 1
        macrosTableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
        macrosTableView.editColumn(0, row: newRow, with: nil, select: true)
    }

    @objc private func removeMacro() {
        let selected = macrosTableView.selectedRow
        guard selected >= 0, selected < macros.count else { return }
        macros.remove(at: selected)
        macrosTableView.reloadData()
    }

    @objc private func savePreferences() {
        let defaults = UserDefaults.standard

        defaults.set(crmEnabledCheckbox.state == .on, forKey: UserDefaultsKeys.crmEnabled)
        defaults.set(crmWebhookField.stringValue.trimmingCharacters(in: .whitespaces), forKey: UserDefaultsKeys.crmWebhookURL)

        defaults.set(webhookEnabledCheckbox.state == .on, forKey: UserDefaultsKeys.callOutcomeWebhookEnabled)
        defaults.set(webhookURLField.stringValue.trimmingCharacters(in: .whitespaces), forKey: UserDefaultsKeys.callOutcomeWebhookURL)

        DTMFMacroManager.shared.macros = macros
        DTMFMacroManager.shared.saveMacros()

        showAlert(message: "CRM-instellingen opgeslagen.", style: .informational)
    }

    // MARK: - Helpers

    private func showAlert(message: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        if let window = view.window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }

    private func makeSectionLabel(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.font = NSFont.boldSystemFont(ofSize: 12)
        return field
    }

    private func makeLabel(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.font = NSFont.systemFont(ofSize: 12)
        return field
    }

    private func makeColumn(id: String, title: String, width: CGFloat) -> NSTableColumn {
        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
        col.title = title
        col.width = width
        col.isEditable = true
        return col
    }
}

// MARK: - NSTableViewDataSource

extension CRMPreferencesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int { macros.count }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let macro = macros[row]
        switch tableColumn?.identifier.rawValue {
        case "name":     return macro.name
        case "sequence": return macro.sequence
        case "delayMs":  return "\(macro.delayMs)"
        default:         return nil
        }
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard let value = object as? String else { return }
        let existing = macros[row]
        switch tableColumn?.identifier.rawValue {
        case "name":
            macros[row] = DTMFMacro(name: value, sequence: existing.sequence, delayMs: existing.delayMs)
        case "sequence":
            macros[row] = DTMFMacro(name: existing.name, sequence: value, delayMs: existing.delayMs)
        case "delayMs":
            let delay = Int(value) ?? 100
            macros[row] = DTMFMacro(name: existing.name, sequence: existing.sequence, delayMs: delay)
        default:
            break
        }
    }
}

// MARK: - NSTableViewDelegate

extension CRMPreferencesViewController: NSTableViewDelegate {}
