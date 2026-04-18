// BLFSubscriptionManager.m
// EcomVoice — Powered by Ecommerce-manager.nl

#import "BLFSubscriptionManager.h"
#import "AKNSString+PJSUA.h"
#import "AKSIPUserAgent.h"
#import "PJSUAOnBuddyState.h"
#import "Telephone-Swift.h"

#import <pjsua-lib/pjsua.h>

#define THIS_FILE "BLFSubscriptionManager.m"

@interface BLFSubscriptionManager ()
@property(nonatomic) NSMutableArray *mutableExtensions; // [BLFExtension]
@end

@implementation BLFSubscriptionManager

- (instancetype)init {
    if ((self = [super init])) {
        _mutableExtensions = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(buddyStateChanged:)
                                                     name:BLFBuddyStateChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self unsubscribeAll];
}

- (NSArray *)extensions {
    return [self.mutableExtensions copy];
}

// MARK: - Public API

- (void)subscribeToConfiguredExtensions {
    [self unsubscribeAll];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:UserDefaultsKeys.blfEnabled]) {
        return;
    }

    NSArray *stored = [defaults arrayForKey:UserDefaultsKeys.blfExtensions];
    if (!stored || stored.count == 0) {
        return;
    }

    // Determine SIP host from first active account registration.
    NSString *sipHost = [self resolvedSIPHost];
    if (!sipHost) {
        PJ_LOG(3, (THIS_FILE, "BLF: no active SIP account, cannot subscribe"));
        return;
    }

    for (NSDictionary *dict in stored) {
        if (![dict isKindOfClass:[NSDictionary class]]) { continue; }
        BLFExtension *ext = [[BLFExtension alloc] initWithDictionary:dict];
        if (!ext) { continue; }
        if (ext.sipHost.length == 0) {
            ext.sipHost = sipHost;
        }
        [self subscribeToExtension:ext];
    }
}

- (void)unsubscribeAll {
    for (BLFExtension *ext in self.mutableExtensions) {
        [self removeBuddy:ext];
    }
    [self.mutableExtensions removeAllObjects];
}

- (void)subscribeToExtension:(BLFExtension *)extension {
    if (![AKSIPUserAgent sharedUserAgent].isStarted) {
        PJ_LOG(3, (THIS_FILE, "BLF: user agent not started, skipping subscription for %s",
                   [extension.extensionNumber UTF8String]));
        return;
    }

    pjsua_buddy_config cfg;
    pjsua_buddy_config_default(&cfg);

    NSString *uri = extension.sipURI;
    pj_str_t pjURI = [uri pjString];
    cfg.uri = pjURI;
    cfg.subscribe = PJ_TRUE;

    pjsua_buddy_id buddyId = PJSUA_INVALID_ID;
    pj_status_t status = pjsua_buddy_add(&cfg, &buddyId);
    if (status != PJ_SUCCESS) {
        PJ_LOG(3, (THIS_FILE, "BLF: failed to add buddy for %s", [uri UTF8String]));
        return;
    }

    extension.buddyId = (int32_t)buddyId;
    [self.mutableExtensions addObject:extension];

    PJ_LOG(4, (THIS_FILE, "BLF: subscribed to %s (buddy_id=%d)", [uri UTF8String], buddyId));
}

- (void)unsubscribeFromExtension:(BLFExtension *)extension {
    [self removeBuddy:extension];
    [self.mutableExtensions removeObject:extension];
}

// MARK: - Private

- (void)removeBuddy:(BLFExtension *)extension {
    if (extension.buddyId == -1) { return; }
    pjsua_buddy_id bid = (pjsua_buddy_id)extension.buddyId;
    if (pjsua_buddy_is_valid(bid)) {
        pjsua_buddy_del(bid);
    }
    extension.buddyId = -1;
    extension.status = BLFStatusUnknown;
}

- (nullable NSString *)resolvedSIPHost {
    AKSIPUserAgent *agent = [AKSIPUserAgent sharedUserAgent];
    for (id account in agent.accounts) {
        // AKSIPAccount has a registrationURI / proxyHost property
        NSString *host = [account valueForKey:@"proxyHost"];
        if (host.length > 0) { return host; }
        // Fall back to domain extracted from SIP address
        NSString *sipAddr = [account valueForKey:@"SIPAddress"];
        if (sipAddr.length > 0) {
            NSArray *parts = [sipAddr componentsSeparatedByString:@"@"];
            if (parts.count == 2) { return parts[1]; }
        }
    }
    return nil;
}

- (void)buddyStateChanged:(NSNotification *)notification {
    NSNumber *buddyIdNum = notification.userInfo[@"buddyId"];
    NSNumber *statusNum  = notification.userInfo[@"status"];
    if (!buddyIdNum || !statusNum) { return; }

    int32_t buddyId = buddyIdNum.intValue;
    BLFStatus newStatus = (BLFStatus)statusNum.integerValue;

    for (BLFExtension *ext in self.mutableExtensions) {
        if (ext.buddyId == buddyId) {
            ext.status = newStatus;
            break;
        }
    }
}

@end
