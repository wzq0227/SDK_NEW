//
//  deviceIcon.h
//  GVAP iPhone
//
//  Created by  on 12-3-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


#define DEV_ICON_FOLDER		@"MyDeviceIcons"

@interface GDDeviceIcon : NSObject

+(void)saveImage:(UIImage*)img andDevId:(NSString*)devId;

+(void)selectImage:(UIImage**)img byDevId:(NSString*)devId;

+(void)getImagePath:(NSString**)path forImg:(NSString*)imgName;


@end
