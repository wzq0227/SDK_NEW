//
//  APDoorbellNoVoiceTipVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/12/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InfoForAddingDevice.h"

@interface APDoorbellNoVoiceTipVC : UIViewController

@property (weak, nonatomic) IBOutlet UIView *demoVideoView;

@property (weak, nonatomic) IBOutlet UILabel *voiceTipLabel;

@property (weak, nonatomic) IBOutlet UIButton *heardVoiceBtn;

@property (weak, nonatomic) IBOutlet UIButton *notHeardVoiceBtn;



@property (strong, nonatomic)  InfoForAddingDevice *addDevInfo;



@end
