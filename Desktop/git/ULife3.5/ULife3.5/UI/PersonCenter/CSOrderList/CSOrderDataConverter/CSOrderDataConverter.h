//
//  CSOrderDataConverter.h
//  ULife3.5
//
//  Created by Goscam on 2018/4/26.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSOrderDeviceListCellModel.h"
#import "CSNetworkLib.h"
#import "CBSCommand.h"


@interface CSOrderDataConverter : NSObject

+ (NSArray<CSOrderDeviceListCellModel*> *)csOrderDeviceListFromCSDataArray:(NSArray<CSOrderItemInfo*>*)dataArray
                                                    withForceUnbindDevList:(NSArray<ForceUnbindDevModel*>*)forceUnbindDevList;

@end
