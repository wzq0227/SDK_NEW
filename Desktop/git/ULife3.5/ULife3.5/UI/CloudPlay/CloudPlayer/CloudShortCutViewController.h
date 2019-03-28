//
//  CloudShortCutViewController.h
//  ULife3.5
//
//  Created by AnDong on 2017/10/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GOSLivePlayerVC.h"
#import "CloudVideoModel.h"

@interface CloudShortCutViewController : UIViewController

//设备id
@property (nonatomic,copy)NSString *deviceId;

@property (nonatomic,weak)GOSLivePlayerVC *cloudPlayVC;

@property (nonatomic,strong)NSDate *currentSelectDate;

@property (nonatomic,assign)NSInteger currentShortCutTime;

@property (nonatomic,assign)int mins;

@property (nonatomic,assign)int seconds;

@property (nonatomic,strong)CloudVideoModel *videoModel;

@end
