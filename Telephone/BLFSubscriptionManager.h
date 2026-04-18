// BLFSubscriptionManager.h
// EcomVoice — Powered by Ecommerce-manager.nl

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Manages SIP presence subscriptions (SUBSCRIBE/NOTIFY) for BLF extensions.
// Uses PJSUA buddy API. Must be called after pjsua_init().
@interface BLFSubscriptionManager : NSObject

// Current list of monitored extensions (BLFExtension objects).
@property(nonatomic, readonly) NSArray *extensions;

// Subscribe to all extensions stored in UserDefaults (BLFExtensions key).
// Reads host from the first active SIP account. Safe to call multiple times.
- (void)subscribeToConfiguredExtensions;

// Remove all subscriptions.
- (void)unsubscribeAll;

// Add a single extension to monitor.
- (void)subscribeToExtension:(id)extension; // BLFExtension *

// Remove subscription for an extension.
- (void)unsubscribeFromExtension:(id)extension; // BLFExtension *

@end

NS_ASSUME_NONNULL_END
