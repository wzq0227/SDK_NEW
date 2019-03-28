//
//  SubDeviceSettingVC.h
//  ULife3.5
//
//  Created by Goscam on 2018/3/26.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface SubDeviceSettingVC : UIViewController

@property (strong, nonatomic)  DeviceDataModel *devModel;

@property (strong, nonatomic)  SubDevInfoModel *subDevInfo;
@end





typedef void(^SelectCellCallbackBlock)(NSInteger index);

typedef void(^ExitSelectingBlock)(void);

@interface PopupTableCellModel2:NSObject
@property (strong, nonatomic)  NSString *deviceName;
@property (assign, nonatomic)  NSInteger deviceId;
@end

/**
 此PopUpTableViewManager2是在PopUpTableViewManager的代码上稍作修改的
 只用于SubDeviceSettingVC显示NightVision选项弹框
 */
@interface PopUpTableViewManager2 : UIView

@property (nonatomic, strong,readwrite)  NSString * tableHeaderStr;

@property (strong, nonatomic) NSArray <PopupTableCellModel2 *>* devicesArray;

- (void)selectCellCallback:(SelectCellCallbackBlock)aCallbackBlock;


- (void)exitSelectingCallback:(ExitSelectingBlock)exitCallback;

@end
