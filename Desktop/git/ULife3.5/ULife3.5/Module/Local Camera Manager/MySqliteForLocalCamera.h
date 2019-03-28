//
//  MySqliteForLocalCamera.h
//  Custom Ulife
//
//  Created by yuanx on 13-11-14.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import "MySqlite.h"
#import "GVAP_deviceDiscover.h"



@interface MySqliteForLocalCamera : MySqlite

+ (MySqliteForLocalCamera *)sharedInstance;


-(BOOL)updateInputPassword:(NSString*)inputPwd toCamId:(NSString*)camId;

-(BOOL)updateCameraInfo:(DeviceInfo)info belongToSsid:(NSString*)ssid online:(BOOL)online date:(NSDate*)date host:(NSString*)host port:(int)port;
-(BOOL)updateCameraInfo:(DeviceInfo)info belongToSsid:(NSString*)ssid online:(BOOL)online date:(NSDate*)date;

-(BOOL)insertCameraInfo:(DeviceInfo)info belongToSsid:(NSString*)ssid online:(BOOL)online date:(NSDate*)date host:(NSString*)host port:(int)port;
-(BOOL)insertCameraInfo:(DeviceInfo)info belongToSsid:(NSString*)ssid online:(BOOL)online date:(NSDate*)date;
-(BOOL)deleteCameraWithId:(char*)camId;
-(BOOL)offlineAllCameras;
-(BOOL)findCameraWithId:(NSString*)camId toExsit:(BOOL*)exsit;


-(BOOL)selectAllCameraIdToArray:(NSMutableArray*)camArray;
-(BOOL)selectCameraBasicInfoWithId:(NSString*)camId toInfo:(NSMutableDictionary*)info;
-(BOOL)selectCameraInfoWithId:(NSString *)camId toInfo:(DeviceInfo *)info;


@end
