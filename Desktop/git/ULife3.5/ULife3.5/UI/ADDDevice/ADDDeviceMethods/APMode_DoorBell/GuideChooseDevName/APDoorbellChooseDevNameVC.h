//
//  APDoorbellChooseDevNameVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/12/5.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InfoForAddingDevice.h"


@interface APDoorbellChooseDevNameVC : UIViewController
@property (assign, nonatomic)  BOOL isDevListEmpty;

@property (strong, nonatomic)  InfoForAddingDevice *addDevInfo;

@end
