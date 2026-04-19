// PJSUAOnMWI.m
// EcomVoice — Powered by Ecommerce-manager.nl

#import "PJSUAOnMWI.h"
#import <Foundation/Foundation.h>
#import <pjsip.h>

NSString * const MWIStatusChangedNotification = @"MWIStatusChangedNotification";

void PJSUAOnMWI(pjsua_acc_id acc_id, pjsua_mwi_info *mwi_info) {
    if (mwi_info == NULL || mwi_info->rdata == NULL) {
        return;
    }

    // Extract body text from the received NOTIFY
    pjsip_msg *msg = mwi_info->rdata->msg_info.msg;
    if (msg == NULL || msg->body == NULL || msg->body->data == NULL || msg->body->len == 0) {
        return;
    }

    NSString *body = [[NSString alloc] initWithBytes:msg->body->data
                                              length:(NSUInteger)msg->body->len
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
        // Parse "Voice-Message: X/Y" — X = new, Y = old
        NSRange vmRange = [body rangeOfString:@"Voice-Message:" options:NSCaseInsensitiveSearch];
        if (vmRange.location != NSNotFound) {
            NSString *afterVM = [body substringFromIndex:NSMaxRange(vmRange)];
            NSString *firstLine = [[afterVM componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] firstObject];
            NSString *trimmed = [firstLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            // Strip anything after space or paren: "X/Y (A/B)" → "X/Y"
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
