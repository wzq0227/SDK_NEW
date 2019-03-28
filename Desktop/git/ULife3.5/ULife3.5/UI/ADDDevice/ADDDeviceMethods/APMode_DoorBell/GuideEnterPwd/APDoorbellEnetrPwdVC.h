//
//  APDoorbellEnetrPwdVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/12/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InfoForAddingDevice.h"

@interface APDoorbellEnetrPwdVC : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *enterPwdTitleLabel;

@property (weak, nonatomic) IBOutlet UILabel *checkPwdTipLabel;

@property (weak, nonatomic) IBOutlet UITextField *pwdTextField;

@property (weak, nonatomic) IBOutlet UIButton *nextBtn;


@property (strong, nonatomic)  InfoForAddingDevice *addDevInfo;

@end
