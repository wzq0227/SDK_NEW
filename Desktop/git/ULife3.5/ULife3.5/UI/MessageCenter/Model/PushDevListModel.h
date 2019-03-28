//
//  PushDevListModel.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/13.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PushDevModel : NSObject  <
                                        NSCopying,
                                        NSCoding,
                                        NSMutableCopying
                                    >

/**
 *  设备 ID
 */
@property (nonatomic, copy) NSString *deviceId;

/**
 *  设备是否已注册推送
 */
@property (nonatomic, assign) BOOL isRegistry;

@end


@interface PushDevListModel : NSObject  <
                                            NSCopying,
                                            NSCoding,
                                            NSMutableCopying
                                        >

/**
 *  iOS 设备 APNS token
 */
@property (nonatomic, copy) NSString *pushToken;

/**
 *  注册推送设备列表
 */
@property (nonatomic, strong) NSMutableArray <PushDevModel *> *deviceArray;

@end
