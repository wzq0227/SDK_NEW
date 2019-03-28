//
//  GOSUIManager.h
//  ULife3.5
//
//  Created by Goscam on 2018/5/10.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GOSUIManager : NSObject


/**
 处理获取操作返回值的UI显示
 
 @param result 0：隐藏loading... ，其他显示获取错误
 */
+ (void)showGetOperationResult:(int)result;


/**
 处理设置操作返回值的UI显示

 @param result 0：隐藏loading... ，其他显示设置错误
 */
+ (void)showSetOperationResult:(int)result;

+ (void)hideSVProgressHUD;

@end
