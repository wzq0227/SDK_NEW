//
//  AddDeviceTableViewCell.h
//  goscamapp
//
//  Created by goscam_sz on 17/4/21.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddDeviceStyleModel.h"

@interface AddDeviceTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *headerImage;

@property (strong, nonatomic) IBOutlet UIButton *FristButton;

@property (assign, nonatomic)  AddDeviceByStyle addDeviceMode;

@end
