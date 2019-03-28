//
//  CMSCommand.m
//  ULifePro
//
//  Created by zhuochuncai on 14/4/17.
//  Copyright © 2017年 Gospell. All rights reserved.
//

#import "CMSCommand.h"
#import "YYModel.h"

@implementation CMSCommandRequest
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

@implementation CMSCommandResponse
@end


@implementation ServerAddress
@end

@implementation CMD_GetAllAreaInfoRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"GetAllAreaInfoRequest";
    }
    return self;
}
@end
@implementation CMD_GetAllAreaInfoResponse
@end


@implementation CMD_UserRegisterRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"UserRegisterRequest";
    }
    return self;
}
@end
@implementation CMD_UserRegisterResponse
@end


@implementation CMD_RetrievePasswordRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"RetrievePasswordRequest";
    }
    return self;
}
@end
@implementation CMD_RetrievePasswordResponse
@end




@implementation CMD_AppGetBSAddressRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"AppGetBSAddressRequest";
    }
    return self;
}
@end
@implementation CMD_AppGetBSAddressResponse
@end



@implementation CMD_LoginGetCGSAAddressReq
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"LoginGetCGSAAddressRequest";
    }
    return self;
}
@end
@implementation CMD_LoginGetCGSAAddressResp
@end


@implementation CMD_QueryNewerVersionReq
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"QueryNewerVersionUPSRequest";
    }
    return self;
}
@end
@implementation CMD_QueryNewerVersionResp
@end

