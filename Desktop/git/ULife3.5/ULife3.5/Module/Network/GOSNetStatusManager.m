//
//  GOSNetStatusManager.m
//  ULife3.5
//
//  Created by Goscam on 2018/5/2.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "GOSNetStatusManager.h"
#import "UIAlertController+Window.h"
#import <AFNetworking.h>

@implementation GOSNetStatusManager

+ (void)checkIfUsingCellularData
{
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager ] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case -1:
                NSLog(@"未知网络");
                break;
            case 0:
                NSLog(@"网络不可达");
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
            { NSLog(@"GPRS网络");
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:DPLocalizedString(@"Wifi_4G_Alert") preferredStyle:UIAlertControllerStyleAlert];
                
                // 添加按钮
                [alert addAction:[UIAlertAction actionWithTitle:DPLocalizedString(@"WiFi_sure") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
                }]];
                [alert show];
                break;
            }
            case 2:
                NSLog(@"wifi网络");
                break;
            default:
                break;
        }
    }];
}

+ (void)stopCheckingUsingCellularData{
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
}


@end
