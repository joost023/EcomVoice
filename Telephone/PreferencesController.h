//
//  PreferencesController.h
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

#import <Cocoa/Cocoa.h>

#import "PreferencesControllerDelegate.h"
#import "PreferencesControllerNotifications.h"
#import "SoundIOPreferences.h"

@class SoundPreferencesViewEventTarget;

NS_ASSUME_NONNULL_BEGIN

@class AKSIPUserAgent;
@class GeneralPreferencesViewController, AccountPreferencesViewController;
@class SoundPreferencesViewController, NetworkPreferencesViewController;
@class BLFPreferencesViewController;
@class CRMPreferencesViewController;
@class DTMFMacroPreferencesViewController;

// A preferences controller.
@interface PreferencesController : NSWindowController <SoundIOPreferences>

@property(nonatomic, readonly, weak) id<PreferencesControllerDelegate> delegate;
@property(nonatomic, readonly) AKSIPUserAgent *userAgent;
@property(nonatomic, readonly) SoundPreferencesViewEventTarget *soundPreferencesViewEventTarget;

// General preferences view controller.
@property(nonatomic, readonly) GeneralPreferencesViewController *generalPreferencesViewController;

// Account preferences view controller.
@property(nonatomic, readonly) AccountPreferencesViewController *accountPreferencesViewController;

// Sound preferences view controller.
@property(nonatomic, readonly) SoundPreferencesViewController *soundPreferencesViewController;

// Network preferences view controller.
@property(nonatomic, readonly) NetworkPreferencesViewController *networkPreferencesViewController;

// BLF preferences view controller (EcomVoice).
@property(nonatomic, readonly) BLFPreferencesViewController *blfPreferencesViewController;

// CRM caller ID preferences view controller (EcomVoice).
@property(nonatomic, readonly) CRMPreferencesViewController *crmPreferencesViewController;

// DTMF macro preferences view controller (EcomVoice).
@property(nonatomic, readonly) DTMFMacroPreferencesViewController *dtmfPreferencesViewController;

// Outlets.
//
@property(nonatomic, weak) IBOutlet NSToolbar *toolbar;
@property(nonatomic, weak) IBOutlet NSToolbarItem *generalToolbarItem;
@property(nonatomic, weak) IBOutlet NSToolbarItem *accountsToolbarItem;
@property(nonatomic, weak) IBOutlet NSToolbarItem *soundToolbarItem;
@property(nonatomic, weak) IBOutlet NSToolbarItem *networkToolbarItem;
// EcomVoice tabs (added programmatically)
@property(nonatomic) NSToolbarItem *blfToolbarItem;
@property(nonatomic) NSToolbarItem *crmToolbarItem;
@property(nonatomic) NSToolbarItem *dtmfToolbarItem;

- (instancetype)initWithDelegate:(id<PreferencesControllerDelegate>)delegate
                       userAgent:(AKSIPUserAgent *)userAgent
 soundPreferencesViewEventTarget:(SoundPreferencesViewEventTarget *)soundPreferencesViewEventTarget;

// Changes window's content view.
- (IBAction)changeView:(id)sender;

- (void)showWindowCentered;
- (void)showAccounts;

@end

NS_ASSUME_NONNULL_END
