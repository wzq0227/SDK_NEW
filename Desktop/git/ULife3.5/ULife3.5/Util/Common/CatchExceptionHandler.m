//
//  CatchExceptionHandler.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/9/11.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "CatchExceptionHandler.h"
#import <signal.h>
#import <execinfo.h>

@implementation CatchExceptionHandler

+ (void)initHandler
{
    struct sigaction newSignalAction;
    memset(&newSignalAction, 0,sizeof(newSignalAction));
    newSignalAction.sa_handler = &signalHandler;
    sigaction(SIGABRT, &newSignalAction, NULL);
    sigaction(SIGILL,  &newSignalAction, NULL);
    sigaction(SIGSEGV, &newSignalAction, NULL);
    sigaction(SIGFPE,  &newSignalAction, NULL);
    sigaction(SIGBUS,  &newSignalAction, NULL);
    sigaction(SIGPIPE, &newSignalAction, NULL);
    
    //异常时调用的函数
    NSSetUncaughtExceptionHandler(&handleExceptions);
}


void handleExceptions(NSException *exception)
{
    NSArray *stackArray       = [exception callStackSymbols];
    NSString *exceptionReason = [exception reason];
    NSString *exceptionName   = [exception name];
    NSString *exceptionInfo   = [NSString stringWithFormat:@"Exception-reason：%@\nException-name：%@\nException-stack：%@", exceptionName,  exceptionReason, stackArray];
    
    NSLog(@"%@",exceptionInfo);
    
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask,
                                                             YES);
    NSString *documentPath = [pathArray objectAtIndex:0];
    NSString *writeFlePath = [documentPath stringByAppendingPathComponent:@"ExceptionInfoLog.txt"];
    NSString *fileContents = [NSString stringWithContentsOfFile:writeFlePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"【yyyy/MM/dd HH:mm:ss】"];
    NSString *timeStr   = [formatter stringFromDate:currentDate];
    NSString *startFlag = [NSString stringWithFormat:@"========================= %@ start =========================", timeStr];
    NSString *endFlag   = [NSString stringWithFormat:@"========================= %@ end =========================", timeStr];
    NSString *crashLog  = [NSString stringWithFormat:@"%@\n\n%@\n\n%@\n\n\n\n\n\n\n%@", startFlag, exceptionInfo, endFlag, fileContents ? fileContents : @""];
    
    [crashLog writeToFile:writeFlePath
               atomically:YES
                 encoding:NSUTF8StringEncoding
                    error:nil];
    
}


void signalHandler(int sig)
{
    //最好不要写，可能会打印太多内容
    NSLog(@"signal = %d", sig);
}

@end
