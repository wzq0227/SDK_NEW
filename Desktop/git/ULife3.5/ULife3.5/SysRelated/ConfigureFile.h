//
//  ConfigureFile.h
//  Custom Ulife
//
//  Created by yuanx on 13-12-19.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ConfigureFile : NSObject


+(NSString*)getImageName:(NSString*)name;

+(NSString*)getConfigString:(NSString*)name;

+(int)getConfigNumber:(NSString*)name;

+(UIColor *)getConfigColor:(NSString*)name;

@end
