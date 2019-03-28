////
////  DeviceConnectManager.m
////  ULife3.5
////
////  Created by 广东省深圳市 on 2017/7/3.
////  Copyright © 2017年 GosCam. All rights reserved.
////
//
//#import "DeviceConnectManager.h"
//#import <NSTimer+YYAdd.h>
//#import "NetAPISet.h"
//#import "DeviceManagement.h"
//#import "DeviceConnectModel.h"
//#import <RealReachability.h>
//
//static NSString *const status4G = @"status4G";
//static NSString *const statusWifi = @"statusWifi";
//static NSString *lastSid;
//static NSString * const kNotifyDevStatus    = @"NotifyDeviceStatus";
//
//@interface DeviceConnectManager ()
//
//@property (nonatomic,strong)NSTimer *clearTimer;
//@property (nonatomic,strong)NSTimer *connectTimer;
//@property (nonatomic,strong)NSTimer *validateTimer;
//@property (nonatomic,strong)NSMutableArray <DeviceConnectModel *>*needConnectArray;
//@property (nonatomic,strong)NSString *currentConnectDevice;
//
//@end
//
//@implementation DeviceConnectManager
//
//+ (instancetype)shareInstance{
//    static DeviceConnectManager *connectManager = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        if (connectManager == nil) {
//            connectManager = [[DeviceConnectManager alloc]init];
//        }
//    });
//    return connectManager;
//}
//
//
//- (void)startMonitor{;
//    self.needConnectArray = [NSMutableArray array];
//    [self startConnectTimer];
//    [self addClientConnectStatusNotification];
//    [self addDeviceStatusNotify];
//
//}
//
//
//-(void)startConnectTimer
//{
//    if ( _connectTimer ==nil)
//    {
//        __weak typeof(self) weakSelf = self;
//        self.connectTimer = [NSTimer yyscheduledTimerWithTimeInterval:0.3 block:^(NSTimer * _Nonnull timer) {
//            //连接一台设备
//            [weakSelf connectOneDevice];
//        } repeats:YES];
//        [self.connectTimer setFireDate:[NSDate distantPast]];
//        [[NSRunLoop mainRunLoop] addTimer:self.connectTimer forMode:NSDefaultRunLoopMode];
//    }
//}
//
//
//- (void)stopConnectTimer
//{
//    if (_connectTimer) {
//        [_connectTimer invalidate];
//        _connectTimer = nil;
//    }
//}
//
//
///**
// 校验sid
// */
//-(void)startValidateSidTimer
//{
//    if ( _validateTimer ==nil)
//    {
//        __weak typeof(self) weakSelf = self;
//        self.validateTimer = [NSTimer yyscheduledTimerWithTimeInterval:1 block:^(NSTimer * _Nonnull timer) {
//            //校验需要重新连接的设备
//            [weakSelf validateDevice];
//        } repeats:YES];
//        [self.validateTimer setFireDate:[NSDate distantPast]];
//        [[NSRunLoop mainRunLoop] addTimer:self.validateTimer forMode:NSDefaultRunLoopMode];
//    }
//}
//
//
//- (void)stopValidateSidTimer
//{
//    if (_validateTimer) {
//        [_validateTimer invalidate];
//        _validateTimer = nil;
//    }
//}
//
//
//- (void)validateDevice{
//    @synchronized (self) {
//        for (DeviceConnectModel * connModel in self.needConnectArray) {
//            if (connModel.isConnectingSuccess && connModel.isOnline) {
//                //连接成功的并且在线
//                BOOL isConnecting = [[NetAPISet sharedInstance] isDeviceConnectingWithUID:connModel.deviceID];
//                if (!isConnecting) {
//                    //当前sid  大概是4G和真实sid
//                    NSString *sid = [self getCurrentConnectSuccessSid];
//                    
//                    ReachabilityStatus currentStatus = [[RealReachability sharedInstance] currentReachabilityStatus];
//                    
//                    if (currentStatus == RealStatusViaWWAN || currentStatus == RealStatusViaWiFi) {
//                        
//                        if (![connModel.connectSuccessSid isKindOfClass:[NSString class]]) {
//                            continue;
//                        }
//                        
//                        if (![connModel.connectSuccessSid isEqualToString:sid]) {
//                            //sid不匹配 重新连接
//                            connModel.isConnecting = YES;
//                            connModel.isConnectingSuccess = NO;
//                            [self reconectClientWithDeviceID:connModel.deviceID];
//                            return;
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
//- (void)connectOneDevice{
//    if (self.currentConnectDevice) {
//        return;
//    }
//    for (DeviceConnectModel *model in self.needConnectArray) {
//        if ([self.ignoreDeviceID isEqualToString:model.deviceID]) {
//            //这个不用管了
//            continue;
//        }
//        
//        if (model.isOnline) {
//            //上一次连接失败的话 --跳过一次 --优化算法
//            if (model.isLastConnectFail) {
//                model.isLastConnectFail = NO;
//                continue;
//            }
//            
//            //已经连接成功的不管
//            if (model.isConnectingSuccess) {
//                continue;
//            }
//            
//            BOOL isConnected = [[NetAPISet sharedInstance] isDeviceConnectedWithUID:model.deviceID];
//            BOOL isConnecting = [[NetAPISet sharedInstance] isDeviceConnectingWithUID:model.deviceID];
//            if (!isConnected && !isConnecting) {
//                model.isConnecting = YES;
//                [self connectClientWithUID:model.deviceID password:@"goscam123"];
//                self.currentConnectDevice = model.deviceID;
//                return;
//            }
//        }
//    }
//}
//
//
////连接TUTK
//- (void)connectClientWithUID:(NSString *)uid password:(NSString *)password{
//    //异步线程操作
//    dispatch_async(dispatch_queue_create("TestTUTK", 0), ^{
//        [[NetAPISet sharedInstance] addClient:uid andpassword:password];
//    });
//}
//
//
//
//
//
//- (void)dealloc{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [self stopConnectTimer];
//    [self stopValidateSidTimer];
//}
//
//
//#pragma mark - 添加连接状态通知
//- (void)addClientConnectStatusNotification{
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(connectStatusChange:)
//                                                 name:ADDeviceConnectStatusNotification
//                                               object:nil];
//}
//
//#pragma mark - 连接状态回调
//- (void)connectStatusChange:(NSNotification *)notifyData{
//    NSDictionary *statusDict = notifyData.userInfo;
//    NSString *UID = statusDict[@"UID"];
//    NSNumber *statusNumber = statusDict[@"State"];
//    if (![UID isKindOfClass:[NSString class]]) {
//        return;
//    }
//    else{
//        if ([UID isEqualToString:self.currentConnectDevice]) {
//            self.currentConnectDevice = nil;
//        }
//    }
//    
//    DeviceConnectModel *connModel = [self getModelFromDeviceID:UID];
//    NSString *sid = [self getCurrentConnectSuccessSid];
//    if (connModel) {
//        if (statusNumber.intValue == NotificationTypeConnected) {
//            //成功移除
//            NSLog(@"AD ConnectSuccess-----------------%@",UID);
//            connModel.isConnectingSuccess = YES;
//            connModel.isLastConnectFail = NO;
//            connModel.connectFailCount = 0;
//            connModel.connectSuccessSid = sid;
//            connModel.isConnecting = NO;
//            
//        }
//        else{
//            //失败
//            NSLog(@"AD ConnectFail-----------------%@",UID);
//            connModel.isConnectingSuccess = NO;
//            connModel.isLastConnectFail = YES;
//            connModel.connectFailCount++;
//            connModel.connectSuccessSid = nil;
//            connModel.isConnecting = NO;
//        }
//    }
//
//}
//
//- (DeviceConnectModel *)getModelFromDeviceID:(NSString *)deviceID{
//    for (DeviceConnectModel *connModel in self.needConnectArray) {
//        if ([connModel.deviceID isEqualToString:deviceID]) {
//            return connModel;
//            break;
//        }
//    }
//    return nil;
//}
//
//#pragma mark - 添加设备在线离线状态通知
//- (void)addDeviceStatusNotify
//{
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(updateDeviceStatus:)
//                                                 name:kNotifyDevStatus
//                                               object:nil];
//}
//
//
//#pragma mark -- 接收在线状态通知
//- (void)updateDeviceStatus:(NSNotification *)notifyData
//{
//    @synchronized (self) {
//        NSDictionary *recvDict = notifyData.object;
//        NSString *msgType = recvDict[@"MessageType"];
//        if (![msgType isEqualToString:kNotifyDevStatus])
//        {
//            NSLog(@"不是设备在线状态通知！");
//            return;
//        }
//        if ([[NSNull null] isEqual:recvDict[@"Body"]]
//            || [[NSNull null] isEqual:recvDict[@"Body"][@"DeviceStatus"]]
//            || [[NSNull null] isEqual:recvDict[@"Body"][@"DeviceStatus"][0]]
//            || [[NSNull null] isEqual:recvDict[@"Body"][@"DeviceStatus"][0][@"Status"]]
//            || [[NSNull null] isEqual:recvDict[@"Body"][@"DeviceStatus"][0][@"DeviceId"]])
//        {
//            NSLog(@"无法提取设备在线状态！");
//            return ;
//        }
//        GosDeviceStatus devStatus = (GosDeviceStatus)[recvDict[@"Body"][@"DeviceStatus"][0][@"Status"] integerValue];
//        NSString *deviceId = recvDict[@"Body"][@"DeviceStatus"][0][@"DeviceId"];
//        NSLog(@"更新设备 deviceId = %@ 在线状态：status = %d", deviceId, (int)devStatus);
//        [self updateDeviceStatus:devStatus withDeviceId:deviceId];
//    }
//}
//
//
//#pragma mark -- 更新在线状态
//- (void)updateDeviceStatus:(GosDeviceStatus)status
//              withDeviceId:(NSString *)deviceId
//{
//    //加锁
//    @synchronized (self) {
//        if (!deviceId || 0 >= deviceId.length)
//        {
//            NSLog(@"deviceId 错误，无法更新在线状态！");
//            return;
//        }
//        //从设备列表去取设备
//        
//        if (status == GosDeviceStatusOnLine) {
//            //在线 -- 添加连接数组
//            [self addNeedConnectDeviceModel:[deviceId substringFromIndex:8]];
//        }
//        else{
//            //离线 -- 移除连接数组
//            [self removeNeedConnectDeviceModel:[deviceId substringFromIndex:8]];
//        }
//        
//        
////        NSMutableArray *deviceArray = [[DeviceManagement sharedInstance] deviceListArray];
////        for (DeviceDataModel *dataModel in deviceArray) {
////            if ([[dataModel.DeviceId substringFromIndex:8] isEqualToString:deviceId]) {
////                if (status == GosDeviceStatusOnLine) {
////                    //在线 -- 添加连接数组
////                    [self addNeedConnectDeviceModel:deviceId];
////                }
////                else{
////                    //离线 -- 移除连接数组
////                    [self removeNeedConnectDeviceModel:deviceId];
////                }
////                break;
////            }
////        }
//        
//    }
//}
//
//
//- (void)reconnectByWifiChangeWithIsSwitchWifi:(BOOL)isSwitch{
//    
//    //加锁
//    @synchronized (self) {
//        //重连
//        for (DeviceConnectModel *model in self.needConnectArray) {
//            if(!isSwitch){
//                if ([self.ignoreDeviceID isEqualToString:model.deviceID]){
//                    continue;
//                }
//            }
//            
//            //在线并且连接成功的开始重连
//            if (model.isOnline && model.isConnectingSuccess) {
//                BOOL isConnecting = [[NetAPISet sharedInstance] isDeviceConnectingWithUID:model.deviceID];
//                //开始重连
//                if (!isConnecting) {
//                    //重置连接状态
//                    model.isConnectingSuccess = NO;
//                    model.isConnecting = YES;
//                    [self reconectClientWithDeviceID:model.deviceID];
//                }
//            }
//    }
//   }
//}
//
//
//- (void)reconectClientWithDeviceID:(NSString *)deviceID{
//    //重新连接
//    [[NetAPISet sharedInstance] ReconnectAndCloseOldStreamLaterWithUID:deviceID resultBlock:^(int result, int state, int cmd) {
//    }];
//}
//
//
///**
// 添加需要连接的设备
// */
//-(void)addNeedConnectDeviceModel:(NSString *)deviceID{
//    NSString *deviceTUTKID = deviceID;
//    BOOL isExsit = NO;
//    for (DeviceConnectModel *connModel in self.needConnectArray) {
//        if ([connModel.deviceID isEqualToString:deviceTUTKID]) {
//            connModel.isOnline = YES;
//            isExsit = YES;
//            break;
//        }
//    }
//    if (!isExsit) {
//        //不存在 创建
//        DeviceConnectModel *connModel = [DeviceConnectModel new];
//        connModel.deviceID = deviceTUTKID;
////        connModel.deviceDataModel = deviceModel;
//        connModel.isOnline = YES;
//        [self.needConnectArray addObject:connModel];
//    }
//}
//
//
///**
// 移除需要连接的设备
// */
//-(void)removeNeedConnectDeviceModel:(NSString *)deviceID{
//    NSString *deviceTUTKID = deviceID;
//    BOOL isExsit = NO;
//    for (DeviceConnectModel *connModel in self.needConnectArray) {
//        if ([connModel.deviceID isEqualToString:deviceTUTKID]) {
//            connModel.isOnline = NO;
//            connModel.lastConnectFailTime = 0;
//            connModel.isConnectingSuccess = NO;
//            connModel.connectSuccessSid = nil;
//            connModel.isLastConnectFail = NO;
//            isExsit = YES;
//            break;
//        }
//    }
//    if (!isExsit) {
//        //不存在 创建
//        DeviceConnectModel *connModel = [DeviceConnectModel new];
//        connModel.deviceID = deviceTUTKID;
////        connModel.deviceDataModel = deviceModel;
//        connModel.isOnline = NO;
//        connModel.lastConnectFailTime = 0;
//        connModel.isConnectingSuccess = NO;
//        connModel.connectSuccessSid = nil;
//        connModel.isLastConnectFail = NO;
//        [self.needConnectArray addObject:connModel];
//    }
//}
//
//
///**
// 返回4G或者Wifi
// */
//- (NSString *)getCurrentConnectSuccessSid{
//    NSString *currentSid = [NetAPISet GetCurrentWifiHotSpotName];
//    if (!currentSid) {
//        //4G状况 --或者没网的状态
//        return @"4G";
//    }
//    return currentSid;
//}
//
//
//#pragma mark - 网络监听处理
//- (void)networkChanged:(NSNotification *)notification{
//    RealReachability *reachability = (RealReachability *)notification.object;
//    ReachabilityStatus curStatus = [reachability currentReachabilityStatus];
//    ReachabilityStatus prevStatus = [reachability previousReachabilityStatus];
//    
//    //这种情况下必须重连
//    if((curStatus == RealStatusViaWiFi || curStatus == RealStatusViaWWAN) && (prevStatus == RealStatusUnknown || prevStatus == RealStatusNotReachable)){
//        //这种时候必须重新连接
//        [self reconnectByWifiChangeWithIsSwitchWifi:NO];
//    }
//}
//
//
//
//
//
//
////-(void)startClearTimer
////{
////    if ( _clearTimer ==nil)
////    {
////        __weak typeof(self) weakSelf = self;
////        self.clearTimer =  [NSTimer yyscheduledTimerWithTimeInterval:5 block:^(NSTimer * _Nonnull timer) {
////            weakSelf.currentConnectDevice = nil;
////        } repeats:YES];
////        [self.clearTimer setFireDate:[NSDate distantPast]];
////        [[NSRunLoop mainRunLoop] addTimer:self.clearTimer forMode:NSDefaultRunLoopMode];
////    }
////}
////
////- (void)stopClearTimer
////{
////    if (_clearTimer) {
////        [_clearTimer invalidate];
////        _clearTimer = nil;
////    }
////}
//
//@end
