//
//  ParseQRResult.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/7/26.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AddDeviceStyleModel.h"
#import "MediaHeader.h"

@interface QRParseResultModel:NSObject

@property (strong, nonatomic)  NSString *deviceId;                      //设备 ID（解析成功时返回）

@property (assign, nonatomic)  BOOL parseSuccessfully;                  //解析是否成功

@property (assign, nonatomic)  QRCodeGenerateStyle qrCodeType;          //设备生成的二维码方式标志

@property (assign, nonatomic)  SmartConnectStyle smartConStyle;         //Smart 连接方式

@property (assign, nonatomic)  GosDeviceType deviceType;                //设备类型（解析成功时返回）

@property (assign, nonatomic)  BOOL supportForceUnbnid;                 //支持硬解绑与否

@property (assign, nonatomic)  BOOL hasEthernet;

@end


@protocol ParseQRResultDelegate <NSObject>

@required

- (void)parseQRResult:(QRParseResultModel*)qrModel;

@end


@interface ParseQRResult : NSObject

@property (nonatomic, weak) id<ParseQRResultDelegate>delegate;

+ (instancetype)shareQRParser;


- (void)parseWithQRString:(NSString *)qrString
            addDeviceType:(AddDeviceByStyle)addDeviceType;

@end
