//
//  DeviceSettingView.h
//  goscamapp
//
//  Created by goscam_sz on 17/5/6.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "settingMode.h"
#import "BaseCommand.h"
#import "DeviceDataModel.h"

typedef void(^SelectRowBlock)(DeviceSettingType type);

typedef void(^deleteDeviceBlock)(void);

typedef void(^UnbindSubDeviceBlock)(void);


@interface DeviceSettingView : UIView <UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *myDeviceTableView;

@property (nonatomic,copy) NSMutableArray * data;

/** 数据存储时长3,7,30天 */
@property (assign, nonatomic)  int dataStorageTime;

@property(nonatomic,strong)DeviceDataModel *model;

- (void)refreshTableView;

- (void)refreshTableViewWithResp:(CMD_GetAllParamResp*)getAllParamResp;

- (void)refreshTableViewWithModel:(UISettingModel*)devAbilityModel;

- (void) didSelectRowCallback:(SelectRowBlock)block;

- (void)deleteDeviceCallback: (deleteDeviceBlock)block;

- (void)unbindSubDeviceCallback: (UnbindSubDeviceBlock)block;

@end
