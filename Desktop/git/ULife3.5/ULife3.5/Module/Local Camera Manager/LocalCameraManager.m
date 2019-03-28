//
//  LocalCameraManager.m
//  Custom Ulife
//
//  Created by yuanx on 13-11-13.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import "LocalCameraManager.h"
#import "UlifeUdpSearcher.h"
#import "UlifeUdpModifier.h"
#import "Reachability.h"
#import <sqlite3.h>
#import "MySqliteForLocalCamera.h"
#import "CommonlyUsedFounctions.h"
typedef enum MyType
{
    MyTypeNone,
    MyTypeSearchAll,
    MyTypeSearchSpecify,
    MyTypeModify,
}
MyType;


@interface LocalCameraManager ()
{
    UlifeUdpSearcher* _searcher;
    UlifeUdpModifier* _modifier;
    id<LocalCameraManagerDelegate> _delegate;
    Reachability* _reachability;
    MyType _myType;
    MySqliteForLocalCamera* _sqlite;

}


@end


@implementation LocalCameraManager

-(id)init
{
    if (self = [super init])
    {
        _reachability = [Reachability reachabilityForLocalWiFi];
        _myType = MyTypeNone;
        _sqlite = [MySqliteForLocalCamera sharedInstance];
    }
    return self;
}


+ (LocalCameraManager *)sharedInstance
{
    static dispatch_once_t onceToken;
    static LocalCameraManager *sSharedInstance;
    dispatch_once(&onceToken, ^{
        sSharedInstance = [[LocalCameraManager alloc] init];
    });
    return sSharedInstance;
}

-(void)dealloc
{
    [self stopSearching];
    [self stopModifing];

    _delegate = nil;
    _myType = MyTypeNone;
}

//搜索全部, 并将结果保存至数据库

-(LocalSearchAndModifyError)localSearchAllCameraWithTimeout:(int)timeout delegate:(id<LocalCameraManagerDelegate>)delegate
{
    [_sqlite offlineAllCameras];
    if (_myType != MyTypeNone)
    {
        return LocalSearchAndModifyErrorBusy;
    }
    if ([_reachability currentReachabilityStatus] != ReachableViaWiFi)
    {
        return LocalSearchAndModifyErrorNoWifi;
    }
    NSLog(@"搜索  开始");
    _delegate = delegate;
    _myType = MyTypeSearchAll;
//    timeout = timeout < 1 ? 1 : timeout;
    if (_searcher == nil)
    {
        _searcher = [[UlifeUdpSearcher alloc] init];
    }
   // [_searcher startSearchWithTimeout:timeout delegate:self];
    return LocalSearchAndModifyErrorNone;
}

//搜索指定摄像头

-(LocalSearchAndModifyError)localSearchCamera:(NSString*)camId timeout:(int)timeout delegate:(id<LocalCameraManagerDelegate>)delegate
{
    if (_myType != MyTypeNone)
    {
        return LocalSearchAndModifyErrorBusy;
    }
    if ([_reachability currentReachabilityStatus] != ReachableViaWiFi)
    {
        return LocalSearchAndModifyErrorNoWifi;
    }
    _delegate = delegate;
    _myType = MyTypeSearchSpecify;
    timeout = timeout < 1 ? 1 : timeout;
    return LocalSearchAndModifyErrorNone;
}

//设置

-(LocalSearchAndModifyError)localModifyCameraWithInfo:(DeviceInfo)info timeout:(int)timeout delegate:(id<LocalCameraManagerDelegate>)delegate
{
    if (_myType != MyTypeNone)
    {
        return LocalSearchAndModifyErrorBusy;
    }
    if ([_reachability currentReachabilityStatus] != ReachableViaWiFi)
    {
        return LocalSearchAndModifyErrorNoWifi;
    }
    _delegate = delegate;
    _myType = MyTypeModify;
    timeout = timeout < 1 ? 1 : timeout;
    return LocalSearchAndModifyErrorNone;
}

//停止搜索
-(void)stopSearching
{
    if (_searcher)
    {
        [_searcher stopSearch];
        _searcher =nil;
    }
    _myType = MyTypeNone;
    _delegate = nil;
    NSLog(@"搜索  停止");
}


//停止修改
-(void)stopModifing
{
    
}

#pragma mark -

-(void)onUlifeUdpSearchGotInfo:(DeviceInfo)info fromHost:(char*)host port:(int)port
{
    //NSLog(@"搜索到 %s", info.szCamSerial);
    BOOL camExsit = NO;
    [_sqlite findCameraWithId:[[NSString alloc] initWithFormat:@"%s", info.szCamSerial] toExsit:&camExsit];
    if (camExsit)
    {
        //        lb-test
        [_sqlite updateCameraInfo:info belongToSsid:[CommonlyUsedFounctions getCurSSID] online:YES date:[NSDate date] host:[[NSString alloc] initWithFormat:@"%s", host == nil ? "" : host] port:port];
    }
    else
    {
        [_sqlite insertCameraInfo:info belongToSsid:[CommonlyUsedFounctions getCurSSID] online:YES date:[NSDate date] host:[[NSString alloc] initWithFormat:@"%s", host == nil ? "" : host] port:port];
    }
}

-(void)onUlifeUdpSearchDone
{
    NSLog(@"搜索  完成");
    switch (_myType)
    {
        case MyTypeSearchAll:
            if ([_delegate respondsToSelector:@selector(onLocalCameraManager:searchCompletedWithError:)])
            {
                [_delegate onLocalCameraManager:self searchCompletedWithError:LocalSearchAndModifyErrorNone];
            }
            break;
        case MyTypeSearchSpecify:
            break;
        case MyTypeModify:
            
            break;
        default:
            break;
    }
    _myType = MyTypeNone;
    _delegate = nil;
}


#pragma mark - sqlite

-(BOOL)updateInputPassword:(NSString*)inputPwd toCamId:(NSString*)camId
{
    return [_sqlite updateInputPassword:inputPwd toCamId:camId];
}


-(BOOL)getCameraArray:(NSMutableArray*)camArray
{
    return [_sqlite selectAllCameraIdToArray:camArray];
}
-(BOOL)getCameraBasicInfoWithId:(NSString*)camId toInfo:(NSMutableDictionary*)info
{
    return [_sqlite selectCameraBasicInfoWithId:camId toInfo:info];
}
-(BOOL)getCameraInfoWithId:(NSString *)camId toInfo:(DeviceInfo *)info
{
    return [_sqlite selectCameraInfoWithId:camId toInfo:info];
}

-(BOOL)delegateCameraWithId:(NSString*)camId
{
    return [_sqlite deleteCameraWithId:(char*)camId.UTF8String];
}

-(BOOL)offALLCamres
{
    return [_sqlite offlineAllCameras];
}

-(void)reBroadcast
{
    [_searcher reBroadcast];
}

@end
