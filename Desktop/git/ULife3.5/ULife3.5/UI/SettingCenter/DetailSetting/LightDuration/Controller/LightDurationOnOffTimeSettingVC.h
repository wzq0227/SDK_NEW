//
//  LightDurationOnOffTimeSettingVC.h
//  ULife3.5
//
//  Created by zhuochuncai on 7/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^SelectTimeBlock)(int hour ,int min );

@interface LightDurationOnOffTimeSettingVC : UIViewController
@property (weak, nonatomic) IBOutlet UIPickerView *onOffTimePickerView;

@property(nonatomic,assign)int hour;
@property(nonatomic,assign)int min;

- (void)selectTimeCallback:(SelectTimeBlock)block;
@end
