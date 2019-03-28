//
//  CommonlyUsedFounctions.h
//  Custom Ulife
//
//  Created by yuanx on 13-11-27.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CommonlyUsedFounctions : NSObject

+ (NSString *)convertedValidTimeWithSartTime:(NSString *)startTime endTime:(NSString *)endTime;

+(NSDate*)getDataFromYear:(int)y month:(int)mon day:(int)d hour:(int)h minute:(int)min second:(int)s timeZone:(NSTimeZone*)timeZone;

+(NSString*)getStringFromYear:(int)y month:(int)mon day:(int)d hour:(int)h minute:(int)min second:(int)s;

+(NSString*)getCurSSID;

+(BOOL)getIp1:(char**)ip1 port1:(int*)port1 ip2:(char**)ip2 port2:(int*)port2 fromUrl:(char*)url;

+ (UIImage *)clipToRectImageFromImage:(UIImage *)image inRect:(CGRect)rect;

+ (UIImage *)clipToRoundImageWithRect:(CGRect)imageRect image:(UIImage *)clipImage;

+ (UILabel*)titleLabelWithStr:(NSString*)titleStr;

@end
