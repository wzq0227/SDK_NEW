//
//  SelfLocalString.m
//  UlifeAll
//
//  Created by goscam_sz on 15/5/21.
//  Copyright (c) 2015年 yuanx. All rights reserved.
//

#import "SelfLocalString.h"
#define CURR_LANG ([[NSLocale preferredLanguages] objectAtIndex:0])

@implementation SelfLocalString

+ (NSString *)LocalizedString:(NSString *)translation_key {
    
    NSString * s = NSLocalizedString(translation_key, nil);
    
    NSString *langTypeStr =nil;

    UserChosenVersion chosenVersion = [mUserDefaults integerForKey:mUserChosenVersion];

    if (isENVersion==1) {
        langTypeStr =  (@"en");
    }else{
        if (chosenVersion == UserChosenVersionDomestic)
        {
            langTypeStr = @"zh-Hans";
        }
        else if (chosenVersion == UserChosenVersionOverseas)
        {
            langTypeStr = @"en";
        }else{
            langTypeStr = @"zh-Hans";
        }
    }
    
    
    
    s = [[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:langTypeStr ofType:@"lproj"]]  localizedStringForKey:translation_key value:@"" table:nil];
    
//    if (![CURR_LANG rangeOfString:@"zh-Hans"].length) {
//        if([CURR_LANG rangeOfString:@"de"].length){
//            NSString * path = [[NSBundle mainBundle] pathForResource:@"de" ofType:@"lproj"];
//            NSBundle * languageBundle = [NSBundle bundleWithPath:path];
//            s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
//        }
//        else if([CURR_LANG rangeOfString:@"fr"].length){
//            NSString * path = [[NSBundle mainBundle] pathForResource:@"fr" ofType:@"lproj"];
//            NSBundle * languageBundle = [NSBundle bundleWithPath:path];
//            s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
//        }
//        else if([CURR_LANG rangeOfString:@"hu"].length){
//            NSString * path = [[NSBundle mainBundle] pathForResource:@"hu" ofType:@"lproj"];
//            NSBundle * languageBundle = [NSBundle bundleWithPath:path];
//            s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
//        }
//        
//        else if([CURR_LANG rangeOfString:@"pt-PT"].length){
//            NSString * path = [[NSBundle mainBundle] pathForResource:@"pt-PT" ofType:@"lproj"];
//            NSBundle * languageBundle = [NSBundle bundleWithPath:path];
//            s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
//        }
//        else if([CURR_LANG rangeOfString:@"it"].length){
//            NSString * path = [[NSBundle mainBundle] pathForResource:@"it" ofType:@"lproj"];
//            NSBundle * languageBundle = [NSBundle bundleWithPath:path];
//            s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
//        }
//        else if([CURR_LANG rangeOfString:@"es"].length){
//            NSString * path = [[NSBundle mainBundle] pathForResource:@"es" ofType:@"lproj"];
//            NSBundle * languageBundle = [NSBundle bundleWithPath:path];
//            s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
//        }
//       
//        else if([CURR_LANG rangeOfString:@"ru"].length){
//            NSString * path = [[NSBundle mainBundle] pathForResource:@"ru" ofType:@"lproj"];
//            NSBundle * languageBundle = [NSBundle bundleWithPath:path];
//            s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
//        }
//        
//        else if([CURR_LANG rangeOfString:@"pl"].length){
//            NSString * path = [[NSBundle mainBundle] pathForResource:@"pl" ofType:@"lproj"];
//            NSBundle * languageBundle = [NSBundle bundleWithPath:path];
//            s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
//        }
//        else if([CURR_LANG rangeOfString:@"uk"].length){
//            NSString * path = [[NSBundle mainBundle] pathForResource:@"uk" ofType:@"lproj"];
//            NSBundle * languageBundle = [NSBundle bundleWithPath:path];
//            s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
//        }
//        else if([CURR_LANG rangeOfString:@"ro"].length){
//            NSString * path = [[NSBundle mainBundle] pathForResource:@"ro" ofType:@"lproj"];
//            NSBundle * languageBundle = [NSBundle bundleWithPath:path];
//            s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
//        }
//
//        else{
//         
//            NSString * path = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
//            NSBundle * languageBundle = [NSBundle bundleWithPath:path];
//            s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
//
//        }
//    }
    return s;
}
@end
