// BLFPreferencesViewController.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import AppKit

@objcMembers
final class BLFPreferencesViewController: NSViewController {

    private var enabledCheckbox: NSButton!
    private var tableView: NSTableView!
    private var addButton: NSButton!
    private var removeButton: NSButton!
    private var sipHostField: NSTextField!
    private var extensions: [[String: String]] = []

    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSavedExtensions()
        buildLayout()
    }

    // MARK: - Layout

    private func buildLayout() {
        let defaults = UserDefaults.standard

        // --- Enable BLF checkbox ---
        enabledCheckbox = NSButton(checkboxWithTitle: "BLF inschakelen (collega-status zichtbaar)", target: self, action: #selector(toggleEnabled))
        enabledCheckbox.translatesAutoresizingMaskIntoConstraints = false
        enabledCheckbox.state = defaults.bool(forKey: UserDefaultsKeys.blfEnabled) ? .on : .off
        enabledCheckbox.contentTintColor = EcomVoiceColors.accentBlue
        view.addSubview(enabledCheckbox)

        // --- SIP Host ---
        let hostLabel = makeLabel("Asterisk host (override per extensie leeg laten):")
        sipHostField = NSTextField()
        sipHostField.translatesAutoresizingMaskIntoConstraints = false
        sipHostField.placeholderString = "bijv. 192.168.1.x of pbx.jouwdomein.nl"
        sipHostField.stringValue = defaults.string(forKey: "BLFDefaultHost") ?? ""
        sipHostField.bezelStyle = .roundedBezel
        view.addSubview(hostLabel)
        view.addSubview(sipHostField)

        // --- Extensions table ---
        let tableLabel = makeLabel("Extensies om te monitoren:")
        view.addSubview(tableLabel)

        tableView = NSTableView()
        tableView.addTableColumn(makeColumn(id: "extension", title: "Extensie", width: 80))
        tableView.addTableColumn(makeColumn(id: "displayName", title: "Naam", width: 160))
        tableView.addTableColumn(makeColumn(id: "host", title: "Host (optioneel)", width: 180))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 22
        tableView.usesAlternatingRowBackgroundColors = true

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        view.addSubview(scrollView)

        // --- Buttons ---
        addButton = NSButton(title: "+", target: self, action: #selector(addExtension))
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.bezelStyle = .roundRect

        removeButton = NSButton(title: "−", target: self, action: #selector(removeExtension))
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.bezelStyle = .roundRect

        let saveButton = NSButton(title: "Opslaan", target: self, action: #selector(savePreferences))
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        view.addSubview(addButton)
        view.addSubview(removeButton)
        view.addSubview(saveButton)

        // --- Constraints ---
        NSLayoutConstraint.activate([
            enabledCheckbox.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            enabledCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            hostLabel.topAnchor.constraint(equalTo: enabledCheckbox.bottomAnchor, constant: 16),
            hostLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            sipHostField.topAnchor.constraint(equalTo: hostLabel.bottomAnchor, constant: 4),
            sipHostField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sipHostField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tableLabel.topAnchor.constraint(equalTo: sipHostField.bottomAnchor, constant: 16),
            tableLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            scrollView.topAnchor.constraint(equalTo: tableLabel.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalToConstant: 160),

            addButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 6),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.widthAnchor.constraint(equalToConstant: 28),

            removeButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 6),
            removeButton.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 4),
            removeButton.widthAnchor.constraint(equalToConstant: 28),

            saveButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 6),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            view.bottomAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 20),
        ])
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        // Preview only — persisted on save
    }

    @objc private func addExtension() {
        extensions.append(["extension": "1XX", "displayName": "", "host": ""])
        tableView.reloadData()
        let newRow = extensions.count - 1
        tableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
        tableView.editColumn(0, row: newRow, with: nil, select: true)
    }

    @objc private func removeExtension() {
        let selected = tableView.selectedRow
        guard selected >= 0, selected < extensions.count else { return }
        extensions.remove(at: selected)
        tableView.reloadData()
    }

    @objc private func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(enabledCheckbox.state == .on, forKey: UserDefaultsKeys.blfEnabled)
        defaults.set(sipHostField.stringValue, forKey: "BLFDefaultHost")
        defaults.set(extensions, forKey: UserDefaultsKeys.blfExtensions)

        // Notify all account windows to reload BLF
        NotificationCenter.default.post(name: Notification.Name("BLFPreferencesDidChange"), object: nil)
    }

    // MARK: - Helpers

    private func loadSavedExtensions() {
        let stored = UserDefaults.standard.array(forKey: UserDefaultsKeys.blfExtensions) as? [[String: String]]
        extensions = stored ?? []
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

extension BLFPreferencesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int { extensions.count }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        extensions[row][tableColumn?.identifier.rawValue ?? ""] ?? ""
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard let key = tableColumn?.identifier.rawValue, let value = object as? String else { return }
        extensions[row][key] = value
    }
}

// MARK: - NSTableViewDelegate

extension BLFPreferencesViewController: NSTableViewDelegate {}
