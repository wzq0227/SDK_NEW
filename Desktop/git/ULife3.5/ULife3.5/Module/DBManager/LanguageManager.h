//
//  LanguageManager.h
//  ULife3.5
//
//  Created by AnDong on 2017/8/29.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LanguageManager : NSObject


/**
 语言管理类
 */

+ (instancetype)manager;

//初始化语言
- (void)initLanguage;

//返回当前语言
- (int)currentLanguage;

@end
