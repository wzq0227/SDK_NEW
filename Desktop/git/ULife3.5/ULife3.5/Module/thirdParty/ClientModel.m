//
//  ClientModel.m
//  Sample_AVAPIs
//
//  Created by admin on 15/9/12.
//
//

#import "ClientModel.h"

@implementation DataWaitFlag
+(DataWaitFlag*)initDataWaitFlagModel:(NSString *)uid andDataFlag:(BOOL)dataFlag and:(BOOL)waitFlag and:(BOOL)cmdFlag and:(BOOL)audioFlag andVideoModel:(BOOL)videoModel andVideoCmd:(int)VideoCmd andDownLoadState:(BOOL) downloadState
{
    DataWaitFlag *flag  = [[DataWaitFlag alloc]init];
    flag.UID = uid;
    flag.videoCmd = VideoCmd;
    flag.audioFlag = audioFlag;
    flag.dataFlag = dataFlag;
    flag.waitFlag = waitFlag;
    flag.cmdFlag = cmdFlag;
    flag.videoModel = videoModel;
    flag.downloadState = downloadState;
    return flag;
}
@end

@implementation ClientModel
+(ClientModel*)initClientModelClass:(NSString *)UID andpwd:(NSString *)pwd andSID: (int)sid andAvIndex:(int)avIndex andSessionID:(int)SessionID andConnectState:(BOOL)connectState andReconnection:(int)reconnection andretry_time:(int)retry_time
{
    ClientModel *Client = [[ClientModel alloc]init];
    Client.uidStr = UID;
    Client.password = pwd;
    Client.sid = sid;
    Client.SessionID = SessionID;
    Client.avIndex = avIndex;
    Client.connectState = connectState;
    Client.reconnection = reconnection;
    Client.retry_time = retry_time;
    return Client;
}
@end
