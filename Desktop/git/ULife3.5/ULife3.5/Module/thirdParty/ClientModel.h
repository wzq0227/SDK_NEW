//
//  ClientModel.h
//  Sample_AVAPIs
//
//  Created by admin on 15/9/12.
//
//

#import <Foundation/Foundation.h>

@interface DataWaitFlag : NSObject
@property(nonatomic,copy)NSString *UID;
@property(nonatomic,assign)int videoCmd;
@property(nonatomic,assign)BOOL audioFlag;
@property(nonatomic,assign)BOOL dataFlag;
@property(nonatomic,assign)BOOL waitFlag;
@property(nonatomic,assign)BOOL cmdFlag;
@property(nonatomic,assign)BOOL videoModel;
@property(nonatomic,assign)BOOL downloadState;
@property(nonatomic,assign)BOOL isBindConnect;
+(DataWaitFlag *)initDataWaitFlagModel:(NSString *)uid andDataFlag:(BOOL)dataFlag and:(BOOL)waitFlag and:(BOOL)cmdFlag and:(BOOL)audioFlag andVideoModel:(BOOL)videoModel andVideoCmd:(int)VideoCmd andDownLoadState:(BOOL) downloadState;
@end

@interface ClientModel : NSObject
@property(nonatomic,copy)NSString *uidStr;
@property(nonatomic,copy)NSString *password;
@property(nonatomic,assign)int sid;
@property(nonatomic,assign)int avIndex;
@property(nonatomic,assign)int SessionID;
@property(nonatomic,assign)int retry_time;
@property(nonatomic,assign)BOOL connectState;
@property(nonatomic,copy)NSString *netMode;
@property(nonatomic,assign)BOOL streamOpened;
@property(nonatomic,assign)BOOL isConnecting;
@property(nonatomic,assign)NSTimeInterval lastConnectTimeInterval;
/**
 * reconnection = -5    //设备是否在线或者设备是否绑定,不需要重新连接
 * reconnection = -4    //网络异常,不需要重新连接
 * reconnection ＝ -3;  //获取视频和音频命令失败，需要重新连接
 * reconnection = -2;   //建立通道失败，需要重新连接
 * reconnection = -1,  //设备不在线,不需要重新连接
 * reconnection = 0    //可以重新连接,绑定失败
 * reconnection = 1;   //不需要重新连接,已经连接成功了
 *
 **/
@property(nonatomic,assign)int reconnection;
+(ClientModel*)initClientModelClass:(NSString *)UID andpwd:(NSString *)pwd andSID: (int)sid andAvIndex:(int)avIndex andSessionID:(int)SessionID andConnectState:(BOOL)connectState andReconnection:(int)reconnection andretry_time:(int)retry_time;

@end
