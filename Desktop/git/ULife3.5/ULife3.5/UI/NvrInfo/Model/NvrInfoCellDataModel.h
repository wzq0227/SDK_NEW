//
//  NvrInfoCellDataModel.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/24.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Cell 类型枚举 */
typedef NS_ENUM(NSInteger, NvrInfoCellStyle) {
    NvrInfoCellSysFirmware              = 0,            // 系统固件
    NvrInfoCellAppFirmware              = 1,            // 引用固件
    NvrInfoCellDevModel                 = 2,            // 设备型号
    NvrInfoCellDevId                    = 3,            // 设备 ID
    NvrInfoCellWiFiName                 = 4,            // WiFi名称
};

@interface NvrInfoCellDataModel : NSObject

/** Cell 类型 */
@property (nonatomic, assign) NvrInfoCellStyle cellStyle;

/** 信息类型 string */
@property (nonatomic, copy) NSString *infoKeyStr;

/** 信息值 string */
@property (nonatomic, copy) NSString *infoValueStr;

@end
