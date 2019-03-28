//
//  MPSCommand.m
//  ULifePro
//
//  Created by zhuochuncai on 24/4/17.
//  Copyright © 2017年 Gospell. All rights reserved.
//

#import "MPSCommand.h"
#import "YYModel.h"

@implementation MPSCommandRequest
-(NSDictionary *)requestBodyData{
    NSMutableDictionary *dict = [self yy_modelToJSONObject];
    [dict removeObjectForKey:@"MessageType"];
    return dict;
}

-(NSDictionary*)requestCMDData{
    NSDictionary *dict = @{@"MessageType":self.MessageType, @"Body":[self requestBodyData]};
    return dict;
}
@end

@implementation MPSCommandResponse
@end


@implementation MPS_LoginRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"LoginRequest";
    }
    return self;
}
@end
@implementation MPS_LoginResponse
@end


@implementation MPS_LogoutRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"LogoutRequest ";
    }
    return self;
}
@end
@implementation MPS_LogoutResponse
@end



@implementation MPS_QueryMsgInfoReq
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"QueryMsgInfoRequest";
    }
    return self;
}
@end

@implementation MPS_QueryMsgInfoResp
@end


@implementation MPS_GetMsgReq
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"GetMsgRequest";
    }
    return self;
}
@end
@implementation MPS_GetMsgResp
@end



@implementation MPS_SetMsgReadReq
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"SetReadedRequest";
    }
    return self;
}
@end
@implementation MPS_SetMsgReadResp
@end



//“Type1”:{
//    "MaxMsgId":125,
//    “NonReadNum”:20 //未读消息条数
//},
//“Type2”:{
//    “devid”:”123457896asdf”,
//    “time”:”2012457856”,
//    “type”:”IO_TEMP”,
//    “msg”:”50 high danger”
//}

@implementation MPS_PushMsgReq
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"PushMsgRequest";
    }
    return self;
}
@end
