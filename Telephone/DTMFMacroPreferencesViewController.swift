// DTMFMacroPreferencesViewController.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import AppKit

/// Preferences tab for managing named DTMF macro sequences.
@objcMembers
final class DTMFMacroPreferencesViewController: NSViewController {

    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    private var addButton: NSButton!
    private var removeButton: NSButton!
    private var saveButton: NSButton!
    private var statusLabel: NSTextField!

    private var macros: [DTMFMacro] = []

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 260))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "DTMF"
        buildLayout()
        reloadMacros()
    }

    // MARK: - Layout

    private func buildLayout() {
        let headerLabel = NSTextField(labelWithString: "DTMF Macro's")
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)

        let hintLabel = NSTextField(labelWithString: "Sla veelgebruikte DTMF-reeksen op (bijv. toetsmenu's). Dubbelklik tijdens een gesprek om te versturen.")
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.font = NSFont.systemFont(ofSize: 11)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.maximumNumberOfLines = 2

        tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsEmptySelection = true
        tableView.allowsMultipleSelection = false
        tableView.delegate = self
        tableView.dataSource = self

        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameColumn.title = "Naam"
        nameColumn.width = 150
        nameColumn.isEditable = true
        tableView.addTableColumn(nameColumn)

        let seqColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("sequence"))
        seqColumn.title = "Reeks (0-9 * # A-D)"
        seqColumn.isEditable = true
        tableView.addTableColumn(seqColumn)

        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.documentView = tableView
        scrollView.borderType = .bezelBorder

        addButton = NSButton(title: "+", target: self, action: #selector(addMacro))
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.bezelStyle = .rounded

        removeButton = NSButton(title: "−", target: self, action: #selector(removeMacro))
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.bezelStyle = .rounded

        saveButton = NSButton(title: "Opslaan", target: self, action: #selector(saveMacros))
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        statusLabel = NSTextField(labelWithString: "")
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor

        let buttonRow = NSStackView(views: [addButton, removeButton])
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 4

        [headerLabel, hintLabel, scrollView, buttonRow, saveButton, statusLabel].forEach {
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            hintLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 4),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalToConstant: 120),

            buttonRow.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 6),
            buttonRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            saveButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 6),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        ])
    }

    // MARK: - Data

    private func reloadMacros() {
        DTMFMacroManager.shared.loadMacros()
        macros = DTMFMacroManager.shared.macros
        tableView.reloadData()
    }

    @objc private func addMacro() {
        let newMacro = DTMFMacro(name: "Nieuw macro", sequence: "123")
        macros.append(newMacro)
        tableView.reloadData()
        tableView.selectRowIndexes(IndexSet(integer: macros.count - 1), byExtendingSelection: false)
    }

    @objc private func removeMacro() {
        let row = tableView.selectedRow
        guard row >= 0 && row < macros.count else { return }
        macros.remove(at: row)
        tableView.reloadData()
    }

    @objc private func saveMacros() {
        DTMFMacroManager.shared.macros = macros
        DTMFMacroManager.shared.saveMacros()
        statusLabel.stringValue = "Macro's opgeslagen."
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.statusLabel.stringValue = ""
        }
    }
}

// MARK: - NSTableViewDataSource

extension DTMFMacroPreferencesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return macros.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let macro = macros[row]
        switch tableColumn?.identifier.rawValue {
        case "name":     return macro.name
        case "sequence": return macro.sequence
        default:         return nil
        }
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard let value = object as? String else { return }
        let old = macros[row]
        switch tableColumn?.identifier.rawValue {
        case "name":
            macros[row] = DTMFMacro(name: value, sequence: old.sequence, delayMs: old.delayMs)
        case "sequence":
            macros[row] = DTMFMacro(name: old.name, sequence: value, delayMs: old.delayMs)
        default: break
        }
    }
}

// MARK: - NSTableViewDelegate

extension DTMFMacroPreferencesViewController: NSTableViewDelegate {}
