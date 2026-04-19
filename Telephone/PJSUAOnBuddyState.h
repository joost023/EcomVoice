// PJSUAOnBuddyState.h
// EcomVoice — Powered by Ecommerce-manager.nl

#import <Foundation/Foundation.h>
#import <pjsua-lib/pjsua.h>

void PJSUAOnBuddyState(pjsua_buddy_id buddy_id);

// Notification posted on main queue when a buddy state changes.
// userInfo: { @"buddyId": @(pjsua_buddy_id), @"status": @(BLFStatus raw) }
extern NSString * const BLFBuddyStateChangedNotification;
