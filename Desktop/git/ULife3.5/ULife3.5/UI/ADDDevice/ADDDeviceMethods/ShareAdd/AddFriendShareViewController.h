//
//  AddFriendShareViewController.h
//  goscamapp
//
//  Created by goscam_sz on 17/4/26.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddDeviceStyleModel.h"
#import "MediaHeader.h"

@interface AddFriendShareViewController : UIViewController

@property (nonatomic,assign) GosDeviceType   deviceType;

@property (strong, nonatomic) IBOutlet UITextField *MyDeviceIdTextField;

@property (strong, nonatomic) IBOutlet UIView *idView;

@property (strong, nonatomic) IBOutlet UIButton *nextBtn;

@property (weak, nonatomic) IBOutlet UILabel *scanTipLabel;

@property (strong, nonatomic) IBOutlet UIImageView *showimageview;

@end
