//
//  LanguageManager.m
//  ULife3.5
//
//  Created by AnDong on 2017/8/29.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "LanguageManager.h"


@interface LanguageManager ()


//0是中文，1是英文
@property (nonatomic,assign)int languageType;

@end

@implementation LanguageManager


+ (instancetype)manager{


    static LanguageManager *manager = nil;
    static dispatch_once_t token;
    if(nil == manager)
    {
        dispatch_once(&token,^{
            manager = [[LanguageManager alloc] init];
        });
    }
    return manager;
}


- (void)initLanguage{
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages objectAtIndex:0];
    
    if ([currentLanguage hasPrefix:@"zh"]) {
        _languageType = 0;
    }
    else{
        _languageType = 1;
    }
}


- (int)currentLanguage{
    return _languageType;
}




@end
