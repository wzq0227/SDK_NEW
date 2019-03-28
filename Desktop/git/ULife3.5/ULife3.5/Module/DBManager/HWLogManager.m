//
//  HWLogManager.m
//  EChannel
//
//  Created by AnDong on 16/12/14.
//  Copyright © 2016年 HuaWei. All rights reserved.
//

#import "HWLogManager.h"



@interface HWLogManager ()

@end

@implementation HWLogManager

static HWLogManager *logManager;

static dispatch_queue_t AD_api_log_creation_queue() {
    static dispatch_queue_t AD_api_log_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AD_api_log_creation_queue =
        dispatch_queue_create("ace.log.api.creation", DISPATCH_QUEUE_SERIAL);
    });
    return AD_api_log_creation_queue;
}

+ (instancetype) manager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logManager = [[HWLogManager alloc] init];
        [logManager setLogInitial];
//        [logManager uploadLogMsg];
        
    });
    
    return logManager;
}

- (void)setLogInitial{
    BOOL isDir = NO;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:[self getInfoFolderPath] isDirectory:&isDir];
    if (!(isExist && isDir)) {
        [fileManager createDirectoryAtPath:[self getInfoFolderPath] withIntermediateDirectories:YES attributes:nil error:nil];
    }

}

- (void)logMessage:(NSString *)logMsg{
    NSUserDefaults *userDealts = [NSUserDefaults standardUserDefaults];
    BOOL isUpload = [userDealts boolForKey:@"AllowUploadAPPLog"];
    if (isUpload) {
        return;
    }
    //异步记录
    dispatch_async(AD_api_log_creation_queue(), ^{
        //写入数据的时候加锁
        @synchronized (self) {
            //以日期作为文件名字
            NSString * logInfoPath = [NSString stringWithFormat:@"%@/%@.txt",[self getInfoFolderPath],[self getCurrentDateStr]];
            NSFileManager * fileManager = [NSFileManager defaultManager];
            BOOL isExsit = [fileManager fileExistsAtPath:logInfoPath];
            NSString *logEndMsg;
            if (isExsit) {
                //已经存在就追加
                NSFileHandle *outFile;
                NSData *buffer;
                outFile = [NSFileHandle fileHandleForWritingAtPath:logInfoPath];

                if (outFile) {
                    [outFile seekToEndOfFile];
                    logEndMsg = [NSString stringWithFormat:@"%@----------------------%@",[self getCurrentDetailDateStr],logMsg];
                    buffer = [logEndMsg dataUsingEncoding:NSUTF8StringEncoding];
                    [outFile writeData:buffer];
                    [outFile closeFile];
                }
            }
            else{
                logEndMsg = [NSString stringWithString:logMsg];
                logEndMsg = [NSString stringWithFormat:@"%@----------------------%@",[self getCurrentDetailDateStr],logEndMsg];
                //写入文件
                [logEndMsg writeToFile:logInfoPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
        }
    });
}

//获取文件夹下所有文件名字
- (NSArray *) getAllFileNames
{
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:[self getInfoFolderPath] error:nil];
    return files;
}

//获取文件夹路径
- (NSString *)getInfoFolderPath{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //InfoLog文件夹
    NSString * infoFolder = [NSString stringWithFormat:@"%@/HWChannelInfoLog",documentsPath];
    return infoFolder;
}

//获取当前日期字符串
- (NSString *)getCurrentDateStr{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy_MM_dd"];
    NSDate *nowDate = [NSDate date];
    NSString *dateStr = [format stringFromDate:nowDate];
    return  dateStr;
}

////上传日志
//- (void)uploadLogMsg{
//
//    NSUserDefaults *userDealts = [NSUserDefaults standardUserDefaults];
//    BOOL isUpload = [userDealts boolForKey:@"AllowUploadAPPLog"];
//    if (isUpload) {
//        return;
//    }
//   NSArray *paths = [self getAllFileNames];
//    //不是今天的
//    for (NSString *path in paths) {
//        if (![path containsString:[self getCurrentDateStr]]) {
//          //上传
//          NSString *postPath = [NSString stringWithFormat:@"%@/%@",[self getInfoFolderPath],path];
//          [self uploadLogWithFilePath:postPath];
//        }
//    }
//}
//
//
//- (void)uploadLogWithFilePath:(NSString *)filePath{
//    __block NSString *blockFilePath = [NSString stringWithString:filePath];
//    [HWNetFileAccess uploadFile:blockFilePath response:^(BOOL isSuccess, NSDictionary *params) {
//        if (isSuccess)
//        {
//            NSString *docId = params[@"docId"];
//            if (params == nil)
//            {
//                HWLog(@"上传APP日志文件失败");
//                return;
//            }else{
//                //上传成功--删除本地日志
//                NSFileManager * fileManager = [NSFileManager defaultManager];
//                BOOL isExsit = [fileManager fileExistsAtPath:blockFilePath];
//                if (isExsit) {
//                    [fileManager removeItemAtPath:blockFilePath error:nil];
//                }
//                
//                HWUPloadCrashLogTxtAPI *uploadTxtApi = [[HWUPloadCrashLogTxtAPI alloc] initAPIWithDocId:docId];
//                [uploadTxtApi setApiCompletionHandler:^(id _Nonnull reseponseObject, NSError * _Nullable error) {
//                    HWLog(@"上传APP日志 : %@",reseponseObject);
//                    if (error){
//                        HWLog(@"上传APP日志 error:%@",error);
//                        return ;
//                    }
//                }];
//                
//                [uploadTxtApi start];
//            }
//            
//        }else{
//            HWLog(@"上传APP日志文件失败");
//            return;
//        }
//    }];
//    
//}


- (NSString *)getCurrentDetailDateStr{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy_MM_dd hh:mm:ss"];
    NSDate *nowDate = [NSDate date];
    NSString *dateStr = [format stringFromDate:nowDate];
    return dateStr;
}


@end
