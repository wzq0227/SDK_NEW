//
//  MediaManager.m
//  MediaManager
//
//  Created by shenyuanluo on 2017/7/20.
//  Copyright © 2017年 goscam. All rights reserved.
//

#import "MediaManager.h"


/**
 *          ------------------ 文件目录结构树 ------------------
 *  |--- AppData
 *  |--- |--- Documents
 *  |--- |--- |--- DevDefault
 *  |--- |--- |--- GosDeviceIPC
 *  |--- |--- |--- |--- DeviceId
 *  |--- |--- |--- |--- |--- Default
 *  |--- |--- |--- |--- |--- |--- othersFile
 *  |--- |--- |--- |--- |--- Cover
 *  |--- |--- |--- |--- |--- |--- Cover_position.png
 *  |--- |--- |--- |--- |--- Snapshot
 *  |--- |--- |--- |--- |--- |--- Snapshot_position.png
 *  |--- |--- |--- |--- |--- Record
 *  |--- |--- |--- |--- |--- |--- Record_position.mp4
 *  |--- |--- |--- GosDeviceNVR
 *  |--- |--- |--- |--- DeviceId
 *  |--- |--- |--- |--- |--- Default
 *  |--- |--- |--- |--- |--- |--- othersFile
 *  |--- |--- |--- |--- |--- Cover
 *  |--- |--- |--- |--- |--- |--- Cover_position.png
 *  |--- |--- |--- |--- |--- Snapshot
 *  |--- |--- |--- |--- |--- |--- Snapshot_position.png
 *  |--- |--- |--- |--- |--- Record
 *  |--- |--- |--- |--- |--- |--- Record_position.mp4
 *  |--- |--- |--- GosDevice360
 *  |--- |--- |--- |--- DeviceId
 *  |--- |--- |--- |--- |--- Default
 *  |--- |--- |--- |--- |--- |--- othersFile
 *  |--- |--- |--- |--- |--- Cover
 *  |--- |--- |--- |--- |--- |--- Cover_position.png
 *  |--- |--- |--- |--- |--- Snapshot
 *  |--- |--- |--- |--- |--- |--- Snapshot_position.png
 *  |--- |--- |--- |--- |--- Record
 *  |--- |--- |--- |--- |--- |--- Record_position.mp4
 */


@implementation MediaFileModel


@end


/** 文件名格式 */
#define FILE_NAME_FORMAT(fileName, positionn, fileSuffix) [NSString stringWithFormat:@"%@_%d.%@", fileName, (int)positionn, fileSuffix]

/** 默认文件名：yyyyMMddHHmmss(时间戳) */
#define DEFAULT_FILE_NAME [self getCurrentDateAndTime]


/** 设备类型 文件夹*/
static NSString *kDevDefaultDir         = @"GosDeviceDefault";      // 其他文件夹
static NSString *kDevIpcDir             = @"GosDeviceIPC";          // 普通 IPC 类型设备文件夹
static NSString *kDevNvrDir             = @"GosDeviceNVR";          // NVR 类型设备文件夹
static NSString *kDev360Dir             = @"GosDevice360";          // 全景360 类型设备文件夹


static NSString *kMediaDefaultDir       = @"Others";                // 默认其他
static NSString *kMediaCoverDir         = @"Cover";                 // 最后一帧图片保存文件夹
static NSString *kMediaSnapshotDir      = @"Snapshot";              // 拍照图片保存文件夹
static NSString *kMediaRecordDir        = @"Record";                // 录像视频保存文件夹


static NSString *kCoverName             = @"Cover";                 // 最后一帧图片 文件名(默认)
static NSString *kSnapshotName          = @"Snapshot";              // 拍照图片    文件名(默认)
static NSString *kRecordName            = @"Record";                // 录像视频    文件名(默认)

static NSString *kImageSuffix           = @"jpg";                   // 图片 文件类型
static NSString *kVideoSuffix           = @"mp4";                   // 视频 文件类型



@interface MediaManager ()

/** 沙盒 ‘Document’ 路径 */
@property (nonatomic, copy) NSString *documentPath;

/** IPC 设备媒体文件保存 路径 */
@property (nonatomic, copy) NSString *ipcMediaPath;

/** NVR 设备媒体文件保存 路径 */
@property (nonatomic, copy) NSString *nvrMediaPath;

/** 360 设备媒体文件保存 路径 */
@property (nonatomic, copy) NSString *panoramaMediaPath;

/** 其他类型 设备媒体文件保存 路径 */
@property (nonatomic, copy) NSString *othersMediaPath;

@end


@implementation MediaManager


#pragma mark - Public
+ (instancetype)shareManager
{
    static MediaManager *g_mediaManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (nil == g_mediaManager)
        {
            g_mediaManager = [[MediaManager alloc] init];
        }
    });
    return g_mediaManager;
}


- (instancetype)init
{
    if (self = [super init])
    {
        
    }
    return self;
}


#pragma mark -- 获取媒体文件路径
- (NSString *)mediaPathWithDevId:(NSString *)deviceId
                        fileName:(NSString *)fileName
                       mediaType:(GosMediaType)mediaType
                      deviceType:(GosDeviceType)deviceType
                        position:(PositionType)position
{
    if (!deviceId || 0 >= deviceId.length)
    {
        NSLog(@"无法获取文件路径，deviceId = nil");
        return nil;
    }
    NSString *retFileName = @"";
    NSString *defaultFileName = @"";
    NSString *fileSuffix = @"";
    switch (mediaType)
    {
        case GosMediaCover:
        {
            defaultFileName = kCoverName;
            fileSuffix      = kImageSuffix;
        }
            break;
            
        case GosMediaSnapshot:
        {
            defaultFileName = DEFAULT_FILE_NAME;
            fileSuffix      = kImageSuffix;
        }
            break;
            
        case GosMediaRecord:
        {
            defaultFileName = DEFAULT_FILE_NAME;
            fileSuffix      = kVideoSuffix;
        }
            break;
            
        case GosMediaShortCut:
        {
            defaultFileName = DEFAULT_FILE_NAME;
            fileSuffix      = kVideoSuffix;
        }
            break;
            
        default:
        {
            defaultFileName = DEFAULT_FILE_NAME;
            fileSuffix      = @"Unknow";
        }
            break;
    }
    if (!fileName || 0 >= fileName.length)
    {
        retFileName = FILE_NAME_FORMAT(defaultFileName, position, fileSuffix);
    }
    else
    {
        if (mediaType == GosMediaShortCut) {
            //协议是AAAA开头 + 时间 + fileName
            retFileName = [NSString stringWithFormat:@"AAAA%@%@",DEFAULT_FILE_NAME,fileName];
        }
        else{
            retFileName = FILE_NAME_FORMAT(fileName, position, fileSuffix);
        }
    }
    NSString *targetdDir = [self getMediaDirWithType:mediaType
                                            deviceId:deviceId
                                          deviceType:deviceType];
    NSString *rargetPath = [targetdDir stringByAppendingPathComponent:retFileName];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    [fileManager changeCurrentDirectoryPath:targetdDir];
//    BOOL isDirectory = NO;
//    if (YES == [fileManager fileExistsAtPath:rargetPath
//                                 isDirectory:&isDirectory])
//    {
//        if (NO == isDirectory)
//        {
//            // 移除旧文件
//            [fileManager removeItemAtPath:rargetPath
//                                    error:nil];
//        }
//    }
    
    return rargetPath;
}


#pragma mark -- 获取视频最后一帧图片
- (UIImage *)coverWithDevId:(NSString *)deviceId
                   fileName:(NSString *)fileName
                 deviceType:(GosDeviceType)deviceType
                   position:(PositionType)position
{
    if (!deviceId || 0 >= deviceId.length)
    {
        NSLog(@"无法获取视频最后一帧图片，deviceId = nil");
        return nil;
    }
    NSString *coverDir = [self getMediaDirWithType:GosMediaCover
                                          deviceId:deviceId
                                        deviceType:deviceType];
    NSString *imageName = nil;
    if (!fileName || 0 >= fileName)
    {
        imageName = FILE_NAME_FORMAT(kCoverName, position, kImageSuffix);
    }
    else
    {
        imageName = FILE_NAME_FORMAT(fileName, position, kImageSuffix);
    }
    NSString *filePath = [coverDir stringByAppendingPathComponent:imageName];
    UIImage *image = nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager changeCurrentDirectoryPath:coverDir];
    BOOL isDirectory = NO;
    if (YES == [fileManager fileExistsAtPath:filePath
                                 isDirectory:&isDirectory])
    {
        if (NO == isDirectory)
        {
            image = [UIImage imageWithContentsOfFile:filePath];
        }
        else
        {
            image = [self getDefaultCover];
        }
    }
    else
    {
        image = [self getDefaultCover];
    }
    return image;
}


- (NSMutableArray <MediaFileModel *>*)mediaArrayWithDevId:(NSString *)deviceId
                                                mediaType:(GosMediaType)mediaType
                                               deviceType:(GosDeviceType)deviceType
                                                 position:(PositionType)position
{
    if (!deviceId || 0 >= deviceId.length)
    {
        NSLog(@"无法获取视频最后一帧图片，deviceId = nil");
        return nil;
    }
    NSString *mediaDir = [self getMediaDirWithType:mediaType
                                          deviceId:deviceId
                                        deviceType:deviceType];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *filePathArray = [fileManager contentsOfDirectoryAtPath:mediaDir
                                                              error:nil];
    NSMutableArray <MediaFileModel *>*mediaArray = [NSMutableArray arrayWithCapacity:0];
    for (NSString *filePath in filePathArray)
    {
//        if (position != [self positionWithFileName:filePath])
//        {
//            continue;
//        }
       
        NSString *fileAbsPath = [mediaDir stringByAppendingPathComponent:filePath];
        
        if ([filePath hasPrefix:@"AAAA"]) {
            //截取掉4个A
            NSString * tureFilePath = [filePath substringFromIndex:4];
            unsigned long long fileSize = [self fileSizeAtPath:fileAbsPath];
            if (fileSize < 0.08 * 1024 * 1024 && mediaType == GosMediaRecord) {
                //小于80kb的不保存 删除文件 这个也播放不了
                [[NSFileManager defaultManager] removeItemAtPath:fileAbsPath error:nil];
                continue;
            }
            MediaFileModel *mediaModel = [[MediaFileModel alloc] init];
            mediaModel.createDate = [self extractDateWithFileName:tureFilePath];
            mediaModel.createTime = [self extractTimeWithFileName:tureFilePath];
            //14开始截取
            mediaModel.fileName   = [tureFilePath substringFromIndex:14];
            mediaModel.fileSize   = [self fileSizeAtPath:fileAbsPath];
            mediaModel.filePath   = fileAbsPath;
            // 逆序显示
            [mediaArray insertObject:mediaModel
                             atIndex:0];
        }
        else{
           
            unsigned long long fileSize = [self fileSizeAtPath:fileAbsPath];
            if (fileSize < 0.08 * 1024 * 1024 && mediaType == GosMediaRecord) {
                //小于80kb的不保存 删除文件 这个也播放不了
                [[NSFileManager defaultManager] removeItemAtPath:fileAbsPath error:nil];
                continue;
            }
            MediaFileModel *mediaModel = [[MediaFileModel alloc] init];
            mediaModel.createDate = [self extractDateWithFileName:filePath];
            mediaModel.createTime = [self extractTimeWithFileName:filePath];
            mediaModel.fileName   = [self extractNameWithFileName:filePath];
            mediaModel.fileSize   = [self fileSizeAtPath:fileAbsPath];
            mediaModel.filePath   = fileAbsPath;
            // 逆序显示
            [mediaArray insertObject:mediaModel
                             atIndex:0];
            
        }
//        [mediaArray addObject:mediaModel];
        
    }
    return mediaArray;
}




#pragma mark - Private
#pragma mark -- 获取默认屏保图片
- (UIImage *)getDefaultCover
{
    NSString *resourceBundle = [[NSBundle mainBundle] pathForResource:@"MediaResource"
                                                               ofType:@"bundle"];
    NSString *imagePath = [[NSBundle bundleWithPath:resourceBundle] pathForResource:@"Cover"
                                                                             ofType:@"jpg"
                                                                        inDirectory:@"Images"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    return image;
}


#pragma mark -- 提取文件日期(yyyy/MM/dd)
- (NSString *)extractDateWithFileName:(NSString *)fileName
{
    if (!fileName || 7 >= fileName.length)
    {
        return nil;
    }
    NSString *yearStr  = [fileName substringWithRange:NSMakeRange(0, 4)];
    NSString *monthStr = [fileName substringWithRange:NSMakeRange(4, 2)];
    NSString *dayStr   = [fileName substringWithRange:NSMakeRange(6, 2)];
    NSString *dateStr  = [NSString stringWithFormat:@"%@/%@/%@", yearStr, monthStr, dayStr];
    
    return dateStr;
}


- (NSString *)extractDateWithFilePath:(NSString *)filePath
{
    if (!filePath || 0 >= filePath.length)
    {
        return nil;
    }
    NSFileManager * fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = NO;
    isExist = [fileManager fileExistsAtPath:filePath
                                isDirectory:&isDir];
    if (YES == isExist && NO == isDir)
    {
        NSDate *fileDate = [[fileManager attributesOfItemAtPath:filePath
                                                          error:nil] fileCreationDate];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        
        [formatter setDateFormat:@"yyyy/MM/dd"];
        NSString *dateStr = [formatter stringFromDate:fileDate];
        
        return dateStr;
    }
    
    return nil;
}


#pragma mark -- 提取文件时间（HH:mm:ss）
- (NSString *)extractTimeWithFileName:(NSString *)fileName
{
    if (!fileName || 14 >= fileName.length)
    {
        return nil;
    }
    NSString *hourStr   = [fileName substringWithRange:NSMakeRange(8, 2)];
    NSString *minuteStr = [fileName substringWithRange:NSMakeRange(10, 2)];
    NSString *secondStr = [fileName substringWithRange:NSMakeRange(12, 2)];
    NSString *timeStr   = [NSString stringWithFormat:@"%@:%@:%@", hourStr, minuteStr, secondStr];
    
    return timeStr;
}


- (NSString *)extractTimeWithFilePath:(NSString *)filePath
{
    if (!filePath || 0 >= filePath.length)
    {
        return nil;
    }
    NSFileManager * fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = NO;
    isExist = [fileManager fileExistsAtPath:filePath
                                isDirectory:&isDir];
    if (YES == isExist && NO == isDir)
    {
        NSDate *fileDate = [[fileManager attributesOfItemAtPath:filePath
                                                          error:nil] fileCreationDate];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        
        [formatter setDateFormat:@"HH:mm:ss"];
        NSString *timeStr = [formatter stringFromDate:fileDate];
        
        return timeStr;
    }
    
    return nil;
}


#pragma mark -- 提取文件名称（例：20170905210321_4.mp4 --> 例：20170905210321.mp4）
- (NSString *)extractNameWithFileName:(NSString *)fileName
{
    if (!fileName || 20 > fileName.length)
    {
        return nil;
    }
    NSString *nameStr    = [fileName substringWithRange:NSMakeRange(0, 14)];
    NSString *fileSuffix = [fileName substringWithRange:NSMakeRange(16, fileName.length - 16)];
    NSString *retName    = [NSString stringWithFormat:@"%@%@", nameStr, fileSuffix];
    
    return retName;
}


#pragma mark -- 获取文件大小
- (unsigned long long)fileSizeAtPath:(NSString *)filePath
{
    if (!filePath || 0 >= filePath.length)
    {
        return 0;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = NO;
    isExist = [fileManager fileExistsAtPath:filePath
                                isDirectory:&isDir];
    if (YES == isExist && NO == isDir)
    {
        return [[fileManager attributesOfItemAtPath:filePath
                                              error:nil] fileSize];
    }
    
    return 0;
}


#pragma mark -- 提取文件画面位置 (例：20170905210321_4.mp4)
- (PositionType)positionWithFileName:(NSString *)fileName
{
    if (!fileName || 16 > fileName.length)
    {
        return PositionMain;
    }
    NSString *positionStr  = [fileName substringWithRange:NSMakeRange(15, 1)];
    PositionType filePosition = [positionStr integerValue];
    
    return filePosition;
}


#pragma mark -- 创建文件夹
- (NSString *)createDirWithPath:(NSString *)dirPath
{
    if (!dirPath || 0 >= dirPath.length)
    {
        return nil;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager createDirectoryAtPath:dirPath
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:&error];
    NSAssert(!error, @"Create directory is failed !");
    return dirPath;
}


#pragma mark -- 获取媒体类型文件夹，没有则创建
- (NSString *)getMediaDirWithType:(GosMediaType)mediaType
                         deviceId:(NSString *)deviceId
                       deviceType:(GosDeviceType)deviceType
{
    if (!deviceId || 0 >= deviceId.length)
    {
        NSLog(@"无法创建设备文件夹，deviceId = nil");
        return nil;
    }
    NSString *mediaDirPath = nil;
    switch (mediaType)
    {
        case GosMediaCover:
        {
            mediaDirPath = [[self getIDPathWitDevId:deviceId
                                         deviceType:deviceType] stringByAppendingPathComponent:kMediaCoverDir];
        }
            break;
            
        case GosMediaSnapshot:
        {
            mediaDirPath = [[self getIDPathWitDevId:deviceId
                                         deviceType:deviceType] stringByAppendingPathComponent:kMediaSnapshotDir];
        }
            break;
            
        case GosMediaRecord:
        {
            mediaDirPath = [[self getIDPathWitDevId:deviceId
                                         deviceType:deviceType] stringByAppendingPathComponent:kMediaRecordDir];
        }
            break;
            
        case GosMediaShortCut:
        {
            mediaDirPath = [[self getIDPathWitDevId:deviceId
                                         deviceType:deviceType] stringByAppendingPathComponent:kMediaRecordDir];
        }
            break;
            
        default:
        {
            mediaDirPath = [[self getIDPathWitDevId:deviceId
                                         deviceType:deviceType] stringByAppendingPathComponent:kMediaDefaultDir];
        }
            break;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if (YES == [fileManager fileExistsAtPath:mediaDirPath
                                 isDirectory:&isDirectory])
    {
        if (YES == isDirectory)
        {
            return mediaDirPath;
        }
        else
        {
            return [self createDirWithPath: mediaDirPath];
        }
    }
    else
    {
        return [self createDirWithPath: mediaDirPath];
    }
}


#pragma mark -- 获取设备 ID 文件夹，没有则创建
- (NSString *)getIDPathWitDevId:(NSString *)deviceId
                     deviceType:(GosDeviceType)deviceType
{
    if (!deviceId || 0 >= deviceId.length)
    {
        NSLog(@"无法创建设备文件夹，deviceId = nil");
        return nil;
    }
    NSString *idDirPath = [[self getDevPathWithType:deviceType] stringByAppendingPathComponent:deviceId];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if (YES == [fileManager fileExistsAtPath:idDirPath
                                 isDirectory:&isDirectory])
    {
        if (YES == isDirectory)
        {
            return idDirPath;
        }
        else
        {
            return [self createDirWithPath: idDirPath];
        }
    }
    else
    {
        return [self createDirWithPath: idDirPath];
    }
}


#pragma mark -- 获取设备类型目录
- (NSString *)getDevPathWithType:(GosDeviceType)devType
{
    NSString *typeDirPath = nil;
    switch (devType)
    {
        case GosDeviceIPC:
        {
            typeDirPath = self.ipcMediaPath;
        }
            break;
            
        case GosDeviceNVR:
        {
            typeDirPath = self.nvrMediaPath;
        }
            break;
            
        case GosDevice360:
        {
            typeDirPath = self.panoramaMediaPath;
        }
            break;
            
        default:
        {
            typeDirPath = self.othersMediaPath;
        }
            break;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if (YES == [fileManager fileExistsAtPath:typeDirPath
                                 isDirectory:&isDirectory])
    {
        if (YES == isDirectory)
        {
            return typeDirPath;
        }
        else
        {
            return [self createDirWithPath: typeDirPath];
        }
    }
    else
    {
        return [self createDirWithPath: typeDirPath];
    }
}


#pragma mark - 懒加载
#pragma mark -- 获取 Doc 目录
- (NSString *)documentPath
{
    if (!_documentPath)
    {
        NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                 NSUserDomainMask,
                                                                 YES);
        _documentPath = [pathArray objectAtIndex:0];
    }
    return _documentPath;
}


#pragma mark -- 获取 IPC 媒体文件保存路径
- (NSString *)ipcMediaPath
{
    if (!_ipcMediaPath)
    {
        _ipcMediaPath = [self.documentPath stringByAppendingPathComponent:kDevIpcDir];
    }
    return _ipcMediaPath;
}


#pragma mark -- 获取 NVR 媒体文件保存路径
- (NSString *)nvrMediaPath
{
    if (!_nvrMediaPath)
    {
        _nvrMediaPath = [self.documentPath stringByAppendingPathComponent:kDevNvrDir];
    }
    return _nvrMediaPath;
}


#pragma mark -- 获取 360 媒体文件保存路径
- (NSString *)panoramaMediaPath
{
    if (!_panoramaMediaPath)
    {
        _panoramaMediaPath = [self.documentPath stringByAppendingPathComponent:kDev360Dir];
    }
    return _panoramaMediaPath;
}


#pragma mark -- 获取 其他 媒体文件保存路径
- (NSString *)othersMediaPath
{
    if (!_othersMediaPath)
    {
        _othersMediaPath = [self.documentPath stringByAppendingPathComponent:kDevDefaultDir];
    }
    return _othersMediaPath;
}


#pragma mark -- 获取当前时间(用作默认文件名,格式：yyyyMMddHHmmss)
- (NSString *)getCurrentDateAndTime
{
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *currentTimeStr = [formatter stringFromDate:date];
    
    return currentTimeStr;
}


@end
