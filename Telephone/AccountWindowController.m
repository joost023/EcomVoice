//
//  AccountWindowController.m
//  Telephone
//
//  Copyright © 2008-2016 Alexey Kuznetsov
//  Copyright © 2016-2022 64 Characters
//
//  Telephone is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Telephone is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

#import "AccountWindowController.h"

#import "AccountViewController.h"

#import "Telephone-Swift.h"

@interface AccountWindowController () <BLFPanelViewControllerDelegate>

@property(nonatomic, readonly) NSString *accountDescription;
@property(nonatomic, readonly) NSString *SIPAddress;
@property(nonatomic, readonly) AccountViewController *accountViewController;
@property(nonatomic, readonly, weak) id<AccountWindowControllerDelegate> delegate;

@property(nonatomic, weak) IBOutlet NSImageView *accountStateImageView;
@property(nonatomic, weak) IBOutlet NSPopUpButton *accountStatePopUp;
@property(nonatomic, weak) IBOutlet NSMenuItem *availableStateItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *unavailableStateItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *offlineStateItem;

// EcomVoice BLF
@property(nonatomic) BLFSubscriptionManager *blfManager;
@property(nonatomic) BLFPanelViewController *blfPanelViewController;

// EcomVoice MWI voicemail badge
@property(nonatomic) NSButton *mwiBadgeButton;

@end

@implementation AccountWindowController

- (BOOL)allowsCallDestinationInput {
    return self.accountViewController.allowsCallDestinationInput;
}

- (instancetype)initWithAccountDescription:(NSString *)accountDescription
                                SIPAddress:(NSString *)SIPAddress
                     accountViewController:(AccountViewController *)accountViewController
                                  delegate:(id<AccountWindowControllerDelegate>)delegate {

    NSParameterAssert(accountDescription);
    NSParameterAssert(SIPAddress);
    NSParameterAssert(accountViewController);
    NSParameterAssert(delegate);
    if ((self = [super initWithWindowNibName:@"Account"])) {
        _accountDescription = [accountDescription copy];
        _SIPAddress = [SIPAddress copy];
        _accountViewController = accountViewController;
        _delegate = delegate;
    }
    return self;
}

- (void)awakeFromNib {
    self.shouldCascadeWindows = NO;
}

- (void)windowDidLoad {
    self.window.title = self.accountDescription;
    self.window.frameAutosaveName = self.SIPAddress;
    self.window.excludedFromWindowsMenu = YES;

    [EcomVoiceBranding applyToWindow:self.window];

    BOOL blfEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsKeys.blfEnabled];
    if (blfEnabled) {
        [self setupBLFSidebar];
    } else {
        // Original full-width layout
        [self.window.contentView addSubview:self.accountViewController.view];
        self.accountViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = @{@"view": self.accountViewController.view};
        [self.window.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views]];
        [self.window.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views]];
    }

    [self showOfflineStateAnimated:NO];
    [self setupMWIBadge];
}

- (void)setupMWIBadge {
    // Create a small badge button for MWI voicemail indicator
    self.mwiBadgeButton = [NSButton buttonWithTitle:@""
                                             target:self
                                             action:@selector(mwiBadgeTapped:)];
    self.mwiBadgeButton.bezelStyle = NSBezelStyleRounded;
    self.mwiBadgeButton.hidden = YES;
    self.mwiBadgeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.mwiBadgeButton.wantsLayer = YES;
    self.mwiBadgeButton.layer.cornerRadius = 6.0;
    [self.window.contentView addSubview:self.mwiBadgeButton positioned:NSWindowAbove relativeTo:nil];

    NSLayoutConstraint *top = [self.mwiBadgeButton.topAnchor constraintEqualToAnchor:self.window.contentView.topAnchor constant:6.0];
    NSLayoutConstraint *trailing = [self.mwiBadgeButton.trailingAnchor constraintEqualToAnchor:self.window.contentView.trailingAnchor constant:-6.0];
    [NSLayoutConstraint activateConstraints:@[top, trailing]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mwiStatusChanged:)
                                                 name:@"MWIStatusChangedNotification"
                                               object:nil];
}

- (void)mwiStatusChanged:(NSNotification *)notification {
    NSInteger unread = [notification.userInfo[@"unread"] integerValue];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (unread > 0) {
            NSString *label = [NSString stringWithFormat:@"Voicemail: %ld", (long)unread];
            [self.mwiBadgeButton setTitle:label];
            self.mwiBadgeButton.hidden = NO;
        } else {
            self.mwiBadgeButton.hidden = YES;
        }
    });
}

- (IBAction)mwiBadgeTapped:(id)sender {
    [MWIManager.shared dialVoicemail];
}

- (void)setupBLFSidebar {
    NSView *contentView = self.window.contentView;

    // Main account view (left, existing width)
    NSView *accountView = self.accountViewController.view;
    accountView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:accountView];

    // BLF sidebar (right, fixed 160pt)
    self.blfManager = [[BLFSubscriptionManager alloc] init];
    self.blfPanelViewController = [[BLFPanelViewController alloc] initWithSubscriptionManager:self.blfManager];
    self.blfPanelViewController.delegate = self;
    [self addChildViewController:self.blfPanelViewController];

    NSView *blfView = self.blfPanelViewController.view;
    blfView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:blfView];

    // Thin vertical separator
    NSView *separator = [[NSView alloc] init];
    separator.translatesAutoresizingMaskIntoConstraints = false;
    separator.wantsLayer = YES;
    separator.layer.backgroundColor = [NSColor colorWithWhite:1.0 alpha:0.1].CGColor;
    [contentView addSubview:separator];

    NSDictionary *metrics = @{@"blfWidth": @160};
    NSDictionary *views = @{@"account": accountView, @"blf": blfView, @"sep": separator};

    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[account][sep(1)][blf(==blfWidth)]|"
                                                                        options:0 metrics:metrics views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[account]|"
                                                                        options:0 metrics:nil views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sep]|"
                                                                        options:0 metrics:nil views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[blf]|"
                                                                        options:0 metrics:nil views:views]];

    // Expand window width to accommodate sidebar
    NSRect frame = self.window.frame;
    frame.size.width += 161;
    [self.window setFrame:frame display:NO];
}

#pragma mark - BLFPanelViewControllerDelegate

- (void)blfPanel:(BLFPanelViewController *)panel didRequestCallToExtension:(NSString *)extension {
    [self makeCallToDestination:extension];
}

#pragma mark -

- (void)showAvailableState {
    self.accountStatePopUp.title = NSLocalizedString(@"Available", @"Account registration Available menu item.");
    self.accountStateImageView.image = [NSImage imageNamed:@"available-state"];

    self.availableStateItem.state = NSControlStateValueOn;
    self.unavailableStateItem.state = NSControlStateValueOff;

    [self.accountViewController showActiveState];
}

- (void)showUnavailableState {
    self.accountStatePopUp.title = NSLocalizedString(@"Unavailable", @"Account registration Unavailable menu item.");
    self.accountStateImageView.image = [NSImage imageNamed:@"unavailable-state"];

    self.availableStateItem.state = NSControlStateValueOff;
    self.unavailableStateItem.state = NSControlStateValueOn;

    [self.accountViewController showActiveState];
}

- (void)showOfflineStateAnimated:(BOOL)animated {
    self.accountStatePopUp.title = NSLocalizedString(@"Offline", @"Account registration Offline menu item.");
    self.accountStateImageView.image = [NSImage imageNamed:@"offline-state"];

    self.availableStateItem.state = NSControlStateValueOff;
    self.unavailableStateItem.state = NSControlStateValueOff;

    [self.accountViewController showInactiveStateAnimated:animated];
}

- (void)showOfflineState {
    [self showOfflineStateAnimated:YES];
}

- (void)showConnectingState {
    [[self accountStatePopUp] setTitle:
     NSLocalizedString(@"Connecting...", @"Account registration Connecting... menu item.")];
}

- (void)makeCallToDestination:(NSString *)destination {
    [self.accountViewController makeCallToDestination:destination];
}

- (IBAction)changeAccountState:(NSPopUpButton *)sender {
    if ([sender.selectedItem isEqual:self.offlineStateItem]) {
        [self.delegate accountWindowController:self didChangeAccountState:AccountWindowControllerAccountStateOffline];
    } else if ([sender.selectedItem isEqual:self.availableStateItem]) {
        [self.delegate accountWindowController:self didChangeAccountState:AccountWindowControllerAccountStateAvailable];
    } else if ([sender.selectedItem isEqual:self.unavailableStateItem]) {
        [self.delegate accountWindowController:self didChangeAccountState:AccountWindowControllerAccountStateUnavailable];
    }
}

- (void)showAlert:(NSAlert *)alert {
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}

- (void)beginSheet:(NSWindow *)sheet {
    [self.window beginSheet:sheet completionHandler:nil];
}

- (void)showWindowWithoutMakingKey {
    [self.window orderFront:self];
}

- (void)hideWindow {
    [self.window orderOut:self];
}

- (BOOL)isWindowKey {
    return self.window.isKeyWindow;
}

- (void)orderWindow:(NSWindowOrderingMode)place relativeTo:(NSInteger)otherWindow {
    [self.window orderWindow:place relativeTo:otherWindow];
}

- (NSInteger)windowNumber {
    return self.window.windowNumber;
}

#pragma mark - NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender {
    [self.window orderOut:self];
    return NO;
}

@end
