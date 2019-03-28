//
//  NvrSettingDataModel.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/23.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NvrSettingCellStyle) {
    NvrSettingCellDevInfo               = 0,        // 设备信息
    NvrSettingCellShareQr               = 1,        // 二维码分享
};

@interface NvrSettingDataModel : NSObject

@property (nonatomic, assign) NvrSettingCellStyle cellStyle;

@property (nonatomic, copy) NSString *cellContent;

@end
