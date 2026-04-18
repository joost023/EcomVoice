// PJSUAOnMWI.h
// EcomVoice — Powered by Ecommerce-manager.nl

#import <pjsua-lib/pjsua.h>

/// PJSIP MWI (Message Waiting Indicator) callback.
/// Parses the voicemail body and posts MWIStatusChangedNotification on the main queue.
void PJSUAOnMWI(pjsua_acc_id acc_id, const pjsua_mwi_info *mwi_info);

/// Notification name posted when MWI status changes.
/// userInfo keys: @"unread" (NSNumber), @"total" (NSNumber)
extern NSString * const MWIStatusChangedNotification;
