//
//  GOSUIManager.m
//  ULife3.5
//
//  Created by Goscam on 2018/5/10.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "GOSUIManager.h"


@implementation GOSUIManager


+ (void)showGetOperationResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result!=0) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Get_data_failed")];
        }else{
            [SVProgressHUD dismiss];
        }
    });
}


+ (void)showSetOperationResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result!=0) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
        }else{
            [SVProgressHUD dismiss];
        }
    });
}

+ (void)hideSVProgressHUD{
    dispatch_async_on_main_queue(^{
        if ([SVProgressHUD isVisible]) {
            [SVProgressHUD dismiss];
        }
    });
}


@end
