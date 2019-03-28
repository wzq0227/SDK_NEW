//
//  ScanGuideViewController.h
//  ULife3.5
//
//  Created by AnDong on 2017/10/27.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"
#import "InfoForAddingDevice.h"

/** 添加方式 */
typedef NS_ENUM(NSInteger, ADDMethodsType) {
    ADDMethodsTypeWifi               = 0,               // wifi添加
    ADDMethodsTypeQrcode            = 1,               // 扫描二维码添加
};

@interface ScanGuideViewController : UIViewController
@property (nonatomic,strong)DeviceDataModel *dataModel;
@property (nonatomic,assign)ADDMethodsType addMethodType;

@property (nonatomic,copy)NSString *wifiPWD;
@property (nonatomic,copy)NSString *wifiStr;
@property (strong, nonatomic)  InfoForAddingDevice *addDevInfo;
@end
