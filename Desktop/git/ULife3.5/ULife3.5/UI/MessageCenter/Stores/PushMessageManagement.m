//
//  PushMessageManagement.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "PushMessageManagement.h"
#import "UserDB.h"


@implementation PushMessageManagement

+ (instancetype)sharedInstance
{
    static PushMessageManagement *g_pushMsgManagement = nil;
    static dispatch_once_t token;
    if(nil == g_pushMsgManagement)
    {
        dispatch_once(&token,^{
            
            g_pushMsgManagement = [[PushMessageManagement alloc] init];
        });
    }
    return g_pushMsgManagement;
}


#pragma mark -- 添加新推送
- (BOOL)addPushMessage:(PushMessageModel *)pushMsgModel
{
    if (!pushMsgModel)
    {
        return NO;
    }
    BOOL isInsert = [[UserDB sharedInstance] insertPushMessageModel:pushMsgModel];
    
    if (YES == isInsert)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_APNS_NOTIFY
                                                            object:pushMsgModel];
    }
    
    return isInsert;
}


#pragma mark -- 删除推送
- (BOOL)deletePushMessage:(PushMessageModel *)pushMsgModel
{
    if (!pushMsgModel)
    {
        return NO;
    }
    return [[UserDB sharedInstance] deletePushMessageModel:pushMsgModel];
}

- (void)deletePushMsgsOfDevice:(NSString *)deviceID{
    NSMutableArray<PushMessageModel*> *msgArray = [self pushMsgArrayWithDevId:deviceID];
    for (PushMessageModel*model in msgArray) {
        [[UserDB sharedInstance] deletePushMessageModel:model];
    }
    return ;
}

#pragma mark -- 更新推送消息查看状态
- (BOOL)updateReadState:(PushMessageModel *)pushMsgModel
{
    if (!pushMsgModel)
    {
        return NO;
    }
    return [[UserDB sharedInstance] updatePushMsgReadState:pushMsgModel];
}


#pragma mark -- 获取当前账号下的所有推送消息列表
-(NSMutableArray <PushMessageModel *>*)pushMessageArray
{
    return [[UserDB sharedInstance] pushMessageArray];
}


#pragma mark -- 根据设备 ID 获取该设备的所有推送
- (NSMutableArray <PushMessageModel *>*)pushMsgArrayWithDevId:(NSString *)deviceId
{
    if (!deviceId || 0 >= deviceId.length)
    {
        return nil;
    }
    return [[UserDB sharedInstance] pushMsgArrayWidthDevId:deviceId];
}

@end
