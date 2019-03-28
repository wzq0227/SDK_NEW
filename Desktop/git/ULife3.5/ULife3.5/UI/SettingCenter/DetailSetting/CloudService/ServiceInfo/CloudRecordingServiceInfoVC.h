//
//  CloudRecordingServiceInfoVC.h
//  ULife3.5
//
//  Created by Goscam on 2017/9/13.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface CloudRecordingServiceInfoVC : UIViewController


/** 存储天数 */
@property (weak, nonatomic) IBOutlet UILabel *storageDaysLabel;

/** 套餐类型 */
@property (weak, nonatomic) IBOutlet UILabel *packageTypeLabel;


/**
 3、7、30天云存储按钮组合
 */
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *storageDaysArray;


/**
 单月包按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *monthlyPaymentBtn;

/**
 包年按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *annualPaymentBtn;

/**
 支付按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *payBtn;


/**
 递减按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *decreaseBtn;

/**
 递增按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *increaseBtn;


/**
 套餐数量
 */
@property (weak, nonatomic) IBOutlet UIButton *packageNumberBtn;


@property (weak, nonatomic) IBOutlet UITableView *serviceTypeTableView;

@property (strong, nonatomic)  NSString *deviceId;

@property (strong, nonatomic)  DeviceDataModel *deviceModel;

/**
 购买过的套餐ID
 */
@property (assign, nonatomic) int   orderedPlanId;

@end
