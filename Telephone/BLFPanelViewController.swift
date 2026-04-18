// BLFPanelViewController.swift
// EcomVoice — Powered by Ecommerce-manager.nl

import AppKit

// Delegate om vanuit het BLF-panel een gesprek te starten.
@objc protocol BLFPanelViewControllerDelegate: AnyObject {
    func blfPanel(_ panel: BLFPanelViewController, didRequestCallTo extension: String)
}

@objcMembers
final class BLFPanelViewController: NSViewController {

    weak var delegate: BLFPanelViewControllerDelegate?

    private let subscriptionManager: BLFSubscriptionManager
    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    private var headerLabel: NSTextField!
    private var observations: [NSKeyValueObservation] = []

    init(subscriptionManager: BLFSubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: - View lifecycle

    override func loadView() {
        let root = NSView()
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor(white: 0, alpha: 0.3).cgColor
        self.view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        subscribeToChanges()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(buddyStateChanged),
            name: NSNotification.Name("BLFBuddyStateChangedNotification"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        observations.removeAll()
    }

    // MARK: - Build layout (programmatic, no XIB)

    private func buildLayout() {
        // Header
        headerLabel = NSTextField(labelWithString: "COLLEGA'S")
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
        headerLabel.textColor = EcomVoiceColors.subtleWhite
        headerLabel.isBezeled = false
        headerLabel.isEditable = false
        headerLabel.drawsBackground = false
        view.addSubview(headerLabel)

        // Table
        tableView = NSTableView()
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .sourceList
        tableView.rowHeight = 36
        tableView.headerView = nil
        tableView.intercellSpacing = NSSize(width: 0, height: 2)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.doubleAction = #selector(doubleClickExtension)
        tableView.target = self

        let statusCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("status"))
        statusCol.width = 10
        tableView.addTableColumn(statusCol)

        let nameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameCol.resizingMask = .autoresizingMask
        tableView.addTableColumn(nameCol)

        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),

            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -18),
        ])
    }

    // MARK: - Notifications

    private func subscribeToChanges() {
        subscriptionManager.subscribeToConfiguredExtensions()
        tableView.reloadData()
    }

    @objc private func buddyStateChanged() {
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func doubleClickExtension() {
        let row = tableView.clickedRow
        guard row >= 0, row < subscriptionManager.extensions.count else { return }
        let ext = subscriptionManager.extensions[row] as! BLFExtension
        delegate?.blfPanel(self, didRequestCallTo: ext.extensionNumber)
    }

    // Called from BLF preferences after user saves new extension list
    @objc func reloadExtensions() {
        subscriptionManager.subscribeToConfiguredExtensions()
        tableView.reloadData()
    }
}

// MARK: - NSTableViewDataSource

extension BLFPanelViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        subscriptionManager.extensions.count
    }
}

// MARK: - NSTableViewDelegate

extension BLFPanelViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let ext = subscriptionManager.extensions[row] as! BLFExtension

        if tableColumn?.identifier.rawValue == "status" {
            return makeStatusDot(for: ext)
        } else {
            return makeNameCell(for: ext)
        }
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.isEmphasized = false
        return rowView
    }

    // MARK: - Cell builders

    private func makeStatusDot(for ext: BLFExtension) -> NSView {
        let container = NSView()
        let dot = NSView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.wantsLayer = true
        dot.layer?.cornerRadius = 5
        dot.layer?.backgroundColor = (ext.statusColor as! NSColor).cgColor
        container.addSubview(dot)
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 10),
            dot.heightAnchor.constraint(equalToConstant: 10),
            dot.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            dot.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    private func makeNameCell(for ext: BLFExtension) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 1
        stack.alignment = .leading

        let nameLine = NSTextField(labelWithString: ext.displayName)
        nameLine.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        nameLine.textColor = EcomVoiceColors.white

        let extLine = NSTextField(labelWithString: "\(ext.extensionNumber) · \(ext.statusLabel)")
        extLine.font = NSFont.systemFont(ofSize: 10, weight: .regular)
        extLine.textColor = EcomVoiceColors.subtleWhite

        stack.addArrangedSubview(nameLine)
        stack.addArrangedSubview(extLine)
        return stack
    }
}
