//
//  ConfigurationWiFiViewController.h
//  goscamapp
//
//  Created by goscam_sz on 17/5/3.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddDeviceStyleModel.h"
#import "MediaHeader.h"
#import "InfoForAddingDevice.h"



@interface ConfigurationWiFiViewController : UIViewController
{

}

@property (strong, nonatomic)  InfoForAddingDevice *addDevInfo;


- (void) onRecognizerStart;
- (void) onRecognizerEnd:(int)_result data:(char *)_data dataLen:(int)_dataLen;

@end
