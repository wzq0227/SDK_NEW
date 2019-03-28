//
//  SelfLocalString.h
//  UlifeAll
//
//  Created by goscam_sz on 15/5/21.
//  Copyright (c) 2015年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 用户登录的时候选择的版本,系统为英文时，不显示切换按钮；为中文时，显示切换按钮

 - UserChosenVersionNone: 用户选择默认 系统中文即中文，英文即英文
 - UserChosenVersionDomestic: 用户选择国内版，选定中文
 - UserChosenVersionOverseas: 用户选择国外版，选定英文
 */
typedef NS_ENUM(NSUInteger, UserChosenVersion) {
    UserChosenVersionNone=1,
    UserChosenVersionDomestic,
    UserChosenVersionOverseas,
};

@interface SelfLocalString : NSObject
+ (NSString *)LocalizedString:(NSString *)translation_key;
@end
