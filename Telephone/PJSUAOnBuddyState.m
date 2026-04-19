// PJSUAOnBuddyState.m
// EcomVoice — Powered by Ecommerce-manager.nl

#import "PJSUAOnBuddyState.h"
#import "Telephone-Swift.h"

#define THIS_FILE "PJSUAOnBuddyState.m"

NSString * const BLFBuddyStateChangedNotification = @"BLFBuddyStateChangedNotification";

// Map PJSUA buddy info to BLFStatus integer values.
// Must stay in sync with the BLFStatus Swift enum.
static NSInteger blfStatusFromBuddyInfo(const pjsua_buddy_info *info) {
    if (info->sub_state == PJSIP_EVSUB_STATE_NULL ||
        info->sub_state == PJSIP_EVSUB_STATE_TERMINATED) {
        // Subscription not active — treat as offline
        return 4; // BLFStatus.offline
    }

    switch (info->status) {
        case PJSUA_BUDDY_STATUS_ONLINE:
            if (info->rpid.activity == PJRPID_ACTIVITY_BUSY) {
                return 2; // BLFStatus.busy
            }
            return 1; // BLFStatus.available

        case PJSUA_BUDDY_STATUS_OFFLINE:
            return 4; // BLFStatus.offline

        case PJSUA_BUDDY_STATUS_UNKNOWN:
        default:
            return 0; // BLFStatus.unknown
    }
}

void PJSUAOnBuddyState(pjsua_buddy_id buddy_id) {
    pjsua_buddy_info info;
    pj_status_t status = pjsua_buddy_get_info(buddy_id, &info);
    if (status != PJ_SUCCESS) {
        PJ_LOG(3, (THIS_FILE, "Could not get buddy info for id %d", buddy_id));
        return;
    }

    NSInteger blfStatus = blfStatusFromBuddyInfo(&info);
    PJ_LOG(4, (THIS_FILE, "Buddy %d state changed: sub_state=%d pjstatus=%d activity=%d -> BLFStatus=%ld",
               buddy_id, info.sub_state, info.status, info.rpid.activity, (long)blfStatus));

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{
            @"buddyId": @(buddy_id),
            @"status":  @(blfStatus)
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:BLFBuddyStateChangedNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
}
