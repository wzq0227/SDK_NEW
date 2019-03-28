//
//  GOSNetStatusManager.h
//  ULife3.5
//
//  Created by Goscam on 2018/5/2.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GOSNetStatusManager : NSObject

+ (void)checkIfUsingCellularData;

+ (void)stopCheckingUsingCellularData;
@end
