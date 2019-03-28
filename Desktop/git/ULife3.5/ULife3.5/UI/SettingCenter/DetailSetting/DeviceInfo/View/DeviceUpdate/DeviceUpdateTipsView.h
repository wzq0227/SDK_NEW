//
//  DeviceUpdateTipsView.h
//  ULife3.5
//
//  Created by zhuochuncai on 6/7/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceUpdateTipsView : UIView

@property (weak, nonatomic) IBOutlet UILabel *updateTipsTitle;

@property (weak, nonatomic) IBOutlet UILabel *versionInfo;

@property (weak, nonatomic) IBOutlet UITextView *updateContentTxt;

@property (weak, nonatomic) IBOutlet UIButton *updateNowBtn;

@property (weak, nonatomic) IBOutlet UIButton *updateNextTimeBtn;

@end
