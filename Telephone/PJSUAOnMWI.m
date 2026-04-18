// PJSUAOnMWI.m
// EcomVoice — Powered by Ecommerce-manager.nl

#import "PJSUAOnMWI.h"
#import <Foundation/Foundation.h>

NSString * const MWIStatusChangedNotification = @"MWIStatusChangedNotification";

void PJSUAOnMWI(pjsua_acc_id acc_id, const pjsua_mwi_info *mwi_info) {
    if (mwi_info == NULL || mwi_info->body.ptr == NULL || mwi_info->body.slen == 0) {
        return;
    }

    // Convert pj_str_t body to NSString for parsing
    NSString *body = [[NSString alloc] initWithBytes:mwi_info->body.ptr
                                              length:(NSUInteger)mwi_info->body.slen
                                            encoding:NSUTF8StringEncoding];
    if (body == nil) {
        return;
    }

    // Parse "Messages-Waiting: yes/no"
    BOOL messagesWaiting = NO;
    NSRange mwRange = [body rangeOfString:@"Messages-Waiting:" options:NSCaseInsensitiveSearch];
    if (mwRange.location != NSNotFound) {
        NSString *afterMW = [body substringFromIndex:NSMaxRange(mwRange)];
        NSString *firstLine = [[afterMW componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] firstObject];
        NSString *trimmed = [firstLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        messagesWaiting = [trimmed.lowercaseString isEqualToString:@"yes"];
    }

    NSInteger unread = 0;
    NSInteger total = 0;

    if (messagesWaiting) {
        // Parse "Voice-Message: X/Y (A/B)" — X = new, Y = old (A/B = urgent variants)
        NSRange vmRange = [body rangeOfString:@"Voice-Message:" options:NSCaseInsensitiveSearch];
        if (vmRange.location != NSNotFound) {
            NSString *afterVM = [body substringFromIndex:NSMaxRange(vmRange)];
            NSString *firstLine = [[afterVM componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] firstObject];
            NSString *trimmed = [firstLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            // Format: "X/Y" or "X/Y (A/B)"
            // Strip anything after a space or parenthesis to get "X/Y"
            NSArray<NSString *> *parts = [trimmed componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ("]];
            NSString *counts = [parts firstObject];
            NSArray<NSString *> *countParts = [counts componentsSeparatedByString:@"/"];
            if (countParts.count >= 1) {
                unread = [countParts[0] integerValue];
            }
            if (countParts.count >= 2) {
                NSInteger old = [countParts[1] integerValue];
                total = unread + old;
            }
        }
    }

    NSDictionary *userInfo = @{
        @"unread": @(unread),
        @"total":  @(total)
    };

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MWIStatusChangedNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
}
