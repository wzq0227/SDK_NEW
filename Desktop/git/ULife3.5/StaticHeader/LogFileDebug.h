//
//  LogFile.h
//  LogTest
//
//  Created by apple on 16/5/21.
//  Copyright © 2016年 crazyit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#define FUNCIONT __PRETTY_FUNCTION__
#define FILENAME __FILE__
#define LINENUM __LINE__

typedef enum : NSUInteger {
    ERROR = 0,
    WARNING,
    NORMAL,
} PRINTLEVEL;

@interface LogFileDebug : NSObject
+(LogFileDebug *)shareInstance;
-(void) CreateLogFile:(NSString *)fileName;

//可以设置某一行 某个函数 某个文件
-(void) LogWriteLineWithLevel:(PRINTLEVEL)nErrorLevel andFunction:(const char*)funcion andFileName:(const char*)fileName andLine:(int)line andFormat:(NSString *)format, ...;

//只能设置打印信息
-(void)LogWriteWithLevel:(PRINTLEVEL)nErrorLevel andFormat:(NSString *)format, ...;
-(void) LogClose;
@end

//使用方法，文件保存在“tmp/LOG”下面
//LogFile *file = [LogFile shareInstance];
//[file CreateLogFile:@"viewControll"];
//[file LogWriteLineWithLevel:0 andFunction:FUNCIONT andFileName:FILENAME andLine:LINENUM andFormat:@"frame = %@",NSStringFromCGRect(self.view.frame)];
//[file LogWriteLineWithLevel:1 andFunction:FUNCIONT andFileName:FILENAME andLine:LINENUM andFormat:@"ViewController = %@",NSStringFromCGRect(self.view.frame)];
//[file LogWriteLineWithLevel:1 andFunction:FUNCIONT andFileName:FILENAME andLine:LINENUM andFormat:@"ViewController = %d %d %d",1,2,3];
//[file LogClose];