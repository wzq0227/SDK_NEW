//
//  UserModel.h
//  QQI
//
//  Created by goscam on 16/1/6.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserModel : NSObject
@property (nonatomic, copy) NSString *account;              // 账号
@property (nonatomic, copy) NSString *password;             // 密码
@property (nonatomic, copy) NSString *email;                // 邮箱
@property (nonatomic, copy) NSString *phoneNum;             // 手机
@property (nonatomic, copy) NSString *QQ;                   // QQ 号
@property (nonatomic, copy) NSString *weChat;               // 微信号
@end
