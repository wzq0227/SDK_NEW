//
//  CommenlyUsedFounctions.h
//  Custom Ulife
//
//  Created by yuanx on 13-11-27.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CommenlyUsedFounctions : NSObject

+(NSDate*)getDataFromYear:(int)y month:(int)mon day:(int)d hour:(int)h minute:(int)min second:(int)s timeZone:(NSTimeZone*)timeZone;

+(NSString*)getStringFromYear:(int)y month:(int)mon day:(int)d hour:(int)h minute:(int)min second:(int)s;

+(NSString*)getCurSSID;

+(BOOL)getIp1:(char**)ip1 port1:(int*)port1 ip2:(char**)ip2 port2:(int*)port2 fromUrl:(char*)url;

@end
