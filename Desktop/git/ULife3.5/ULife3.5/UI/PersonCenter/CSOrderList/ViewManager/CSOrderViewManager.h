//
//  CSOrderViewManager.h
//  ULife3.5
//
//  Created by Goscam on 2018/4/23.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSOrderDeviceListCellModel.h"

typedef void(^SelectCellCallbackBlock)(NSInteger index);

@interface CSOrderViewManager : UIView

@property (strong, nonatomic)  NSArray<CSOrderDeviceListCellModel*> *devicesArray;

- (void)selectCellCallback:(SelectCellCallbackBlock)aCallbackBlock;

@end
