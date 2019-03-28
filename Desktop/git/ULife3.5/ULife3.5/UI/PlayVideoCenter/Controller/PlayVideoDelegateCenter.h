//
//  PlayVideoDelegateCenter.h
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/27.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayVideoViewController.h"


@interface PlayVideoDelegateCenter : NSObject <PlayVideoDelegate>

/**
 *  设备ID
 */
@property (nonatomic, copy) NSString *deviceId;

/**
 *  所在的 ViewController
 */
@property (nonatomic, weak) UIViewController *viewController;


@end
