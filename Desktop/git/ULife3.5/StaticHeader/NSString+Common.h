//
//  NSString+Common.h
//  QQI
//
//  Created by goscam on 16/7/6.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Common)
- (BOOL)isEmail;
-(BOOL)isPassword;
-(BOOL)isMetacharacter;
-(BOOL)isAccountValid;
- (BOOL)isMobilePhone;

-(BOOL)isPasswordValid;
@end
