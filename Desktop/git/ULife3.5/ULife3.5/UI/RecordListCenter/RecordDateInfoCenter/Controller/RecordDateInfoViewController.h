//
//  RecordDateInfoViewController.h
//  goscamapp
//
//  Created by shenyuanluo on 2017/4/28.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecordDateInfoViewController : UIViewController

/**
 *  设备ID
 */
@property (nonatomic, copy) NSString *deviceId;

/**
 *  录像日期
 */
@property (nonatomic, copy) NSString *recordDateStr;


@end
