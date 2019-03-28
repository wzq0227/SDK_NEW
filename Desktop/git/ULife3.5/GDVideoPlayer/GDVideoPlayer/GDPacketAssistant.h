//
//  PacketAssistant.h
//  U5800YCameraViewer
//
//  Created by Lasia on 12-9-26.
//  Copyright (c) 2012年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
 
说明: 
 
1. 446的头部, 在字典中对应的key分别为:
	U_LIFE_VERSION 
	U_LIFE_COMMAND 
	U_LIFE_LENGTH
2. 解析不分大小写.
 
*/




@interface GDPacketAssistant : NSObject

+(int)properBufferLenForDict:(NSMutableDictionary*)dict;
+(BOOL)makePacketWith:(NSMutableDictionary*)dict to:(void**)tarBuf len:(int*)len;
+(BOOL)parserPacketWith:(void*)buf len:(int)len toDict:(NSMutableDictionary**)dict;
+(BOOL)make2PacketWith:(NSMutableDictionary*)dict to:(void**)tarBuf len:(int*)len;
@end
