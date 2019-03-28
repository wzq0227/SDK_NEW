//
//  LocalCameraManager.h
//  Custom Ulife
//
//  Created by yuanx on 13-11-13.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GVAP_deviceDiscover.h"



typedef enum LocalSearchAndModifyError
{
    LocalSearchAndModifyErrorNone = 1,
    LocalSearchAndModifyErrorNoWifi,
    LocalSearchAndModifyErrorBusy,
    LocalSearchAndModifyErrorTimeout,
    LocalSearchAndModifyErrorUncorrectPassword,
    LocalSearchAndModifyErrorFailed,
    
}LocalSearchAndModifyError;



@protocol LocalCameraManagerDelegate, UlifeUdpSearchDelegate;

@interface LocalCameraManager : NSObject

+ (LocalCameraManager *)sharedInstance;

//搜索全部, 并将结果保存至数据库

-(LocalSearchAndModifyError)localSearchAllCameraWithTimeout:(int)timeout delegate:(id<LocalCameraManagerDelegate>)delegate;

//搜索指定摄像头

-(LocalSearchAndModifyError)localSearchCamera:(NSString*)camId timeout:(int)timeout delegate:(id<LocalCameraManagerDelegate>)delegate;

//设置

-(LocalSearchAndModifyError)localModifyCameraWithInfo:(DeviceInfo)info timeout:(int)timeout delegate:(id<LocalCameraManagerDelegate>)delegate;

//停止搜索
-(void)stopSearching;


//数据库操作. 查询, 删除, 修改等

-(BOOL)updateInputPassword:(NSString*)inputPwd toCamId:(NSString*)camId;

-(BOOL)getCameraArray:(NSMutableArray*)camArray;
-(BOOL)getCameraBasicInfoWithId:(NSString*)camId toInfo:(NSMutableDictionary*)info;
-(BOOL)getCameraInfoWithId:(NSString *)camId toInfo:(DeviceInfo *)info;
-(BOOL)delegateCameraWithId:(NSString*)camId;
-(BOOL)offALLCamres;
-(void)reBroadcast;


@end


@protocol LocalCameraManagerDelegate <NSObject>

@optional

//搜索所有摄像头的回调
-(void)onLocalCameraManager:(LocalCameraManager*)localCameraManager searchCompletedWithError:(LocalSearchAndModifyError)err;

//搜索指定摄像头的回调
-(void)onLocalCameraManager:(LocalCameraManager*)localCameraManager specifiedSearchCompletedWithError:(LocalSearchAndModifyError)err cameraInfo:(DeviceInfo)info;

@end





