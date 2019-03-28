//
//  ShareWithFriendsViewController.h
//  ULife3.5
//
//  Created by zhuochuncai on 3/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface ShareWithFriendsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *shareQRCode;

@property (weak, nonatomic) IBOutlet UILabel *shareTitle;

@property (weak, nonatomic) IBOutlet UILabel *stepOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepTwoContent;

@property(nonatomic,strong)DeviceDataModel *model;
@end
