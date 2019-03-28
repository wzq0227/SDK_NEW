//
//  PacketAssistant.m
//  U5800YCameraViewer
//
//  Created by Lasia on 12-9-26.
//  Copyright (c) 2012年 yuanx. All rights reserved.
//

#import "GDPacketAssistant.h"

@implementation GDPacketAssistant

//打包后, 包的长度, 用于创建buffer时设定长度
+(int)properBufferLenForDict:(NSMutableDictionary*)dict
{
    int nTotalLen = 14;
    NSArray* arrayKey = [dict allKeys];
    NSArray* arrayValue = [dict allValues];
    int nCount = [arrayKey count];
    
    for (int i = 0; i < nCount; i ++)
    {
        NSString* keyName = [arrayKey objectAtIndex:i];
        id keyValue = [arrayValue objectAtIndex:i];
        
        if (![[keyName lowercaseString] isEqualToString:[@"U_LIFE_VERSION" lowercaseString]] &&
            ![[keyName lowercaseString] isEqualToString:[@"U_LIFE_COMMAND" lowercaseString]])
        {
            nTotalLen += 8 + [keyName length] + [keyValue length];
        }
    }
    return nTotalLen + 1;
}

+(BOOL)makePacketWith:(NSMutableDictionary*)dict to:(void**)tarBuf len:(int*)len
{
    if (*tarBuf == nil)
    {
        return NO;
    }
    NSLog(@"makePacketWith1");
    NSArray* arrayKey = [dict allKeys] ;
    NSArray* arrayValue = [dict allValues] ;
    int nCount = [arrayKey count];
    int nCurrentBytes = 14;
    
    BOOL bVersionGot = NO, bCommandGot = NO;
    
    
    for (int i = 0; i < nCount; i ++)
    {
        NSString* keyName = [arrayKey objectAtIndex:i];
        id keyValue = [arrayValue objectAtIndex:i];
        
        int nLen = [keyName length];
        int vLen = [keyValue length];
        const char *cKeyName = [keyName UTF8String];
        
        const char* cKeyValue;
        
        if (![keyName isEqualToString:@"Data"]) {
            cKeyValue = [keyValue UTF8String];
        }
        
        
        if ([[keyName lowercaseString] isEqualToString:[@"U_LIFE_VERSION" lowercaseString]])
        {
            memcpy(*tarBuf, cKeyValue, 4);
            bVersionGot = YES;
        }
        else if([[keyName lowercaseString] isEqualToString:[@"U_LIFE_COMMAND" lowercaseString]])
        {
            memcpy(*tarBuf + 4, cKeyValue, 4);
            bCommandGot = YES;
        }
        else
        {
            if ([keyValue isKindOfClass:[NSData class]])
            {
                sprintf(*tarBuf + nCurrentBytes, "%02X%06X%s", nLen, vLen, cKeyName);
                nCurrentBytes += 8 + nLen;
                memcpy(*tarBuf + nCurrentBytes, [keyValue bytes], vLen);
                nCurrentBytes += vLen;
            }
            else
            {
                sprintf(*tarBuf + nCurrentBytes, "%02X%06X%s%s", nLen, vLen, cKeyName, cKeyValue);
                nCurrentBytes += 8 + nLen + vLen;
            }
        }
    }
    
    
    
    NSLog(@"2makePacketWith");
    if (bVersionGot && bCommandGot)
    {
        char totalLen[7] = {0};
        sprintf(totalLen, "%06X", nCurrentBytes - 14);
        memcpy(*tarBuf + 8, totalLen, 6);
        *len = nCurrentBytes;
        NSLog(@"makePacketWith3");
        return YES;
    }
    else
    {
        return NO;
    }
}

+(BOOL)make2PacketWith:(NSMutableDictionary*)dict to:(void**)tarBuf len:(int*)len
{
    if (*tarBuf == nil)
    {
        return NO;
    }
    NSLog(@"makePacketWith1");
    NSArray* arrayKey = [dict allKeys] ;
    NSArray* arrayValue = [dict allValues] ;
    int nCount = [arrayKey count];
    int nCurrentBytes = 14;
    
    BOOL bVersionGot = NO, bCommandGot = NO;
    
    
    for (int i = 0; i < nCount; i ++)
    {
        NSString* keyName = [arrayKey objectAtIndex:i];
        id keyValue = [arrayValue objectAtIndex:i];
        
        int nLen = [keyName length];
        int vLen = [keyValue length];
        const char* cKeyName;
        const char* cKeyValue;
        cKeyName = [keyName UTF8String];
        
        if (![keyName isEqualToString:@"audiodata"]) {
            cKeyValue = [keyValue UTF8String];
        }
        
        
        if ([[keyName lowercaseString] isEqualToString:[@"U_LIFE_VERSION" lowercaseString]])
        {
            memcpy(*tarBuf, cKeyValue, 4);
            bVersionGot = YES;
        }
        else if([[keyName lowercaseString] isEqualToString:[@"U_LIFE_COMMAND" lowercaseString]])
        {
            memcpy(*tarBuf + 4, cKeyValue, 4);
            bCommandGot = YES;
        }
        else
        {
            if ([keyValue isKindOfClass:[NSData class]])
            {
                sprintf(*tarBuf + nCurrentBytes, "%02X%06X%s", nLen, vLen, cKeyName);
                nCurrentBytes += 8 + nLen;
                memcpy(*tarBuf + nCurrentBytes, [keyValue bytes], vLen);
                nCurrentBytes += vLen;
            }
            else
            {
                sprintf(*tarBuf + nCurrentBytes, "%02X%06X%s%s", nLen, vLen, cKeyName, cKeyValue);
                nCurrentBytes += 8 + nLen + vLen;
            }
        }
    }
    
    NSLog(@"2makePacketWith");
    if (bVersionGot && bCommandGot)
    {
        char totalLen[7] = {0};
        sprintf(totalLen, "%06X", nCurrentBytes - 14);
        memcpy(*tarBuf + 8, totalLen, 6);
        *len = nCurrentBytes;
        NSLog(@"makePacketWith3");
        return YES;
    }
    else
    {
        return NO;
    }
}

+(BOOL)parserPacketWith:(void*)buf len:(int)len toDict:(NSMutableDictionary**)dict
{
    if (len == 0)
    {
        return NO;
    }
    NSString* strVersion = [[NSString alloc] initWithBytes:buf length:4 encoding:NSUTF8StringEncoding];
    NSString* strCommand = [[NSString alloc] initWithBytes:buf + 4 length:4 encoding:NSUTF8StringEncoding];
    char totalLen[7] = {0};
    memcpy(totalLen, buf + 8, 6);
    NSNumber* numTotalLen = [[NSNumber alloc] initWithInt:strtol(totalLen, NULL, 16)];
    [*dict setObject:numTotalLen forKey:@"U_LIFE_LENGTH"];
    [*dict setObject:strVersion forKey:@"U_LIFE_VERSION"];
    [*dict setObject:strCommand forKey:@"U_LIFE_COMMAND"];
    
    
    
    
    
    int nCurrentLen = 14;
    char nameLen[3] = {0};
    char valueLen[7] = {0};
    int nNameLen = 0, nValueLen = 0;
    
    while (nCurrentLen < len)
    {
        memcpy(nameLen, buf + nCurrentLen, 2);
        memcpy(valueLen, buf + nCurrentLen + 2, 6);
        nNameLen = strtol(nameLen, NULL, 16);
        nValueLen = strtol(valueLen, NULL, 16);
        
        if (nameLen == 0 || nValueLen == 0)
        {
            //为0返回错误
            return NO;
        }
        NSString* strName = [[NSString alloc] initWithBytes:buf + nCurrentLen + 8 length:nNameLen encoding:NSUTF8StringEncoding];
        NSString* strValue = nil;
        NSData* strData = nil;
        if ([[strName lowercaseString] isEqualToString:@"data"] || [[strName lowercaseString] isEqualToString:@"hisdata"])
        {
            strData = [[NSData alloc] initWithBytes:buf + nCurrentLen + 8 + nNameLen length:nValueLen];
            if (strData) {
                [*dict setObject:strData forKey:strName];
            }
            
        }
        else
        {
            strValue = [[NSString alloc] initWithBytes:buf + nCurrentLen + 8 + nNameLen length:nValueLen encoding:NSUTF8StringEncoding];
            if (strValue) {
                [*dict setObject:strValue forKey:strName];
            }
            
        }
        
        nCurrentLen += 8 + nNameLen + nValueLen;
    }
    return YES;
}




@end
