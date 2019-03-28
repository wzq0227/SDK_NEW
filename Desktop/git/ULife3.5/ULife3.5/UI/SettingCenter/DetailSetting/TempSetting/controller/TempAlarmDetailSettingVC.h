//
//  TempAlarmDetailSettingVC.h
//  ULife3.5
//
//  Created by zhuochuncai on 26/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseCommand.h"

typedef void(^FinishSavingCallback)(CMD_TempAlarm *alarmData);

@interface TempAlarmDetailSettingVC : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic,assign)BOOL isCelcius;
@property(nonatomic,assign)float upperLimit;
@property(nonatomic,assign)float lowerLimit;
@property(nonatomic,strong)CMD_TempAlarm *tempAlarmData;
@property(nonatomic,strong)NSString *deviceID;

- (void)didFinishSavingWithCallback:(FinishSavingCallback)callbackBlock;
@end
