//
//  VideoModel.h
//  goscamapp
//
//  Created by goscam_sz on 17/4/20.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoModel : NSObject

@property (nonatomic, copy) NSString *devId;          // 设备ID
@property (nonatomic, copy) NSString *streamNam;           // 设备登录名称
@property (nonatomic, copy) NSString *streamPwd;           // 设备登录密码
@property (nonatomic, copy) NSString *devName;            // 设备昵称
@property (nonatomic, assign) int userRight;               // 是否是分享

@end
