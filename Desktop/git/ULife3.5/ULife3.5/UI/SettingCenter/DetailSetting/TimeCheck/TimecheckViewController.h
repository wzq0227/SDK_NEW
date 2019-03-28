//
//  TimecheckViewController.h
//  QQI
//
//  Created by goscam_sz on 16/8/3.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimecheckViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *opResultLabel;

@property (nonatomic,copy)  NSString *deviceID;

@property (weak, nonatomic) IBOutlet UIImageView *opResultFace;

@property (weak, nonatomic) IBOutlet UIView *opResultView;

@property (weak, nonatomic) IBOutlet UIButton *timeCheckBtn;

@property (weak, nonatomic) IBOutlet UILabel *timeCheckTipsLabel;

@end
