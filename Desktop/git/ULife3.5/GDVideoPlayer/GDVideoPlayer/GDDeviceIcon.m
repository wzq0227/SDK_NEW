//
//  deviceIcon.m
//  GVAP iPhone
//
//  Created by  on 12-3-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GDDeviceIcon.h"

@implementation GDDeviceIcon


+(void)saveImage:(UIImage*)img andDevId:(NSString*)devId
{
	if (!img || !devId) 
	{
		return;
	}
	
	NSLog(@"save image.");

    NSFileManager* fm = [NSFileManager defaultManager];
	NSString* path = nil;
	[self getImagePath:&path forImg:devId];
	if ([fm fileExistsAtPath:path]) 
	{
		[fm removeItemAtPath:path error:nil];
	}
	
	[fm createFileAtPath:path contents:[fm contentsAtPath:devId] attributes:nil];
	NSFileHandle* fh = [NSFileHandle fileHandleForWritingAtPath:path];
	NSData* tempData = UIImagePNGRepresentation([self scale:img toSize:CGSizeMake(80*4, 60*4)]);

	[fh writeData:tempData];

    NSLog(@"save over");
}

+(void)selectImage:(UIImage**)img byDevId:(NSString*)devId
{
	if (!devId) 
	{
		*img = nil;
	}
	NSFileManager* fm = [NSFileManager defaultManager];
	
	
	NSString* path = nil;
	[self getImagePath:&path forImg:devId];
	int nRet = -1;
	nRet = [[fm attributesOfItemAtPath:path error:nil] fileSize];
	
	if ([fm fileExistsAtPath:path] && nRet > 0) 
	{
		*img = [UIImage imageWithContentsOfFile:path];
	}
	else 
	{
		*img = [UIImage imageNamed:@"cam_default_icon.jpg"];
	}
}

+(void)getImagePath:(NSString**)path forImg:(NSString*)imgName
{
	if (!imgName) 
	{
		*path = nil;
		return;
	}
//	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);  
    NSString *documentsDirectory = [paths objectAtIndex:0];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	[fm changeCurrentDirectoryPath:documentsDirectory];
	
	BOOL b = NO;
	if ([fm fileExistsAtPath:DEV_ICON_FOLDER isDirectory:&b]) //判断文件夹是否存在，是否为文件夹。
	{
		if (!b) //存在，但不是文件夹删掉重建
		{
			[fm removeItemAtPath:DEV_ICON_FOLDER error:nil];
			
			[fm createDirectoryAtPath:DEV_ICON_FOLDER withIntermediateDirectories:NO attributes:nil error:nil];
		}
	}
	else	//不存在，创建
	{
		[fm createDirectoryAtPath:DEV_ICON_FOLDER withIntermediateDirectories:NO attributes:nil error:nil];
	}
	
	//构建完整路径
    *path = [[[fm currentDirectoryPath] stringByAppendingPathComponent:DEV_ICON_FOLDER] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", imgName]];
//	NSLog(@"Path:%@", *path);
//	[pool release];
}


+(UIImage *)scale:(UIImage *)image toSize:(CGSize)size
{

    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];//这行报错
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return scaledImage;
}


@end
