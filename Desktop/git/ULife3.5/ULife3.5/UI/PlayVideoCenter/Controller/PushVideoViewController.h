//
//  PushVideoViewController.h
//  ULife3.5
//
//  Created by goscam_sz on 2017/7/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"
#import "PushMessageModel.h"

typedef void(^playBlock)(NSString *);

@interface PushVideoViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIImageView *pushImageView;

@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@property (strong, nonatomic) IBOutlet UIButton *chanceBtn;

@property (strong, nonatomic) IBOutlet UIButton *sureBtn;

@property (strong, nonatomic) PushMessageModel *pushModel;

@property (nonatomic,copy) DeviceDataModel * md;

@property (nonatomic,assign) int  count;

@property (nonatomic,copy) playBlock playbock;



@end
