//
//  CBSCommand.m
//  ULifePro
//
//  Created by zhuochuncai on 14/4/17.
//  Copyright © 2017年 Gospell. All rights reserved.
//

#import "CBSCommand.h"

@implementation BodyData
@end
@implementation BodyResponseData
@end
@implementation CBSCommandRequest
-(NSDictionary*)requestCMDData{
    return [self yy_modelToJSONObject];
}
@end
@implementation CBSCommandResponse
@end


//Register
@implementation BodyRegisterRequest
@end
@implementation BodyRegisterResponse
@end
@implementation CBS_RegisterRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"UserRegisterRequest";
    }
    return self;
}
@end
@implementation CBS_RegisterResponse
@end


//Login
@implementation BodyLoginRequest
@end
@implementation BodyLoginResponse
@end
@implementation CBS_LoginRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"LoginCBSRequest";
    }
    return self;
}
@end
@implementation CBS_LoginResponse
@end


//Bind
@implementation BodyBindRequest
@end
@implementation BodyBindResponse
@end
@implementation CBS_BindRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"BindSmartDeviceRequest";
    }
    return self;
}
@end
@implementation CBS_BindResponse
@end


//Unbind
@implementation BodyUnbindRequest
@end
@implementation BodyUnbindResponse
@end
@implementation CBS_UnbindRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"UnbindSmartDeviceRequest";
    }
    return self;
}
@end
@implementation CBS_UnbindResponse
@end


//StrongUnbind
@implementation BodyStrongUnbindRequest
@end
@implementation BodyStrongUnbindResponse
@end
@implementation CBS_StrongUnbindRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"ForceUnbindDeviceRequest";
    }
    return self;
}
@end
@implementation CBS_StrongUnbindResponse
@end


//ModifyAttr
@implementation BodyModifyAttrRequest
@end
@implementation BodyModifyAttrResponse
@end
@implementation CBS_ModifyAttrRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"ModifyDeviceAttrRequest";
    }
    return self;
}
@end
@implementation CBS_ModifyAttrResponse
@end


//GetDevList
@implementation BodyGetDevListRequest
@end
@implementation BodyGetDevListResponse
@end
@implementation CBS_GetDevListRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"GetUserDeviceListRequest";
    }
    return self;
}
@end
@implementation CBS_GetDevListResponse
@end


//GetSubDevList
@implementation BodyGetSubDevListRequest
@end
@implementation BodyGetSubDevListResponse
@end
@implementation CBS_GetSubDevListRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"AppGetSubDeviceListRequest";
    }
    return self;
}
@end
@implementation CBS_GetSubDevListResponse
@end


//QueryBind
@implementation BodyQueryBindRequest
@end
@implementation BodyQueryBindResponse
@end
@implementation CBS_QueryBindRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"QueryDeviceBindRequest";
    }
    return self;
}
@end
@implementation CBS_QueryBindResponse
@end


//ModifyUserPwd
@implementation BodyModifyUserPwdRequest
@end
@implementation BodyModifyUserPwdResponse
@end
@implementation CBS_ModifyUserPwdRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"ModifyUserPasswordRequest";
    }
    return self;
}
@end
@implementation CBS_ModifyUserPwdResponse
@end



//changePWD
@implementation BodyGetVerifyCodePwdRequest
@end
@implementation CMD_GetVerifyCodeRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"GetVerifyCodeRequest";
    }
    return self;
}
@end
@implementation CMD_GetVerifyCodeResponse
@end

@implementation BodyModifyPasswordByVerifyRequest
@end
@implementation CMD_ModifyPasswordByVerifyRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"ModifyPasswordByVerifyRequest";
    }
    return self;
}
@end
@implementation CMD_ModifyPasswordByVerifyResponse
@end



// checkDeviceRegisgter
@implementation BodyCheckDeviceRegisterRequest
@end
@implementation BodyCheckDeviceRegisterResponse
@end

@implementation CBS_CheckDeviceRegisterRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"CheckDeviceRegisterRequest";
    }
    return self;
}
@end
@implementation CBS_CheckDeviceRegisterResponse
@end



////查询子设备上报状态
//@implementation SubDevInfo @end
@implementation BodyCheckSubDevRegisterRequest @end
@implementation BodyCheckSubDevRegisterResponse @end

@implementation CBS_CheckSubDevRegisterRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"QuerySubDevReportRequest";
    }
    return self;
}
@end
//QuerySubDevReportResponse
@implementation CBS_CheckSubDevRegisterResponse @end



@implementation BodyAddSubDevRequest @end
@implementation BodyAddSubDevResponse @end
@implementation CBS_AddSubDevRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"AddSubDeviceRequest";
    }
    return self;
}
@end
//AddSubDeviceResponse
@implementation CBS_AddSubDevResponse @end



@implementation BodyDeleteSubDevRequest @end
@implementation BodyDeleteSubDevResponse @end
@implementation CBS_DeleteSubDevRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"DeleteSubDeviceRequest";
    }
    return self;
}
@end
//DeleteSubDeviceResponse
@implementation CBS_DeleteSubDevResponse @end



@implementation BodyGetDeviceShareListRequest @end
@implementation BodyGetDeviceShareListResponse @end
@implementation CBS_GetDeviceShareListRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"GetShareUserListRequest";
    }
    return self;
}
@end
//GetDeviceShareListiceResponse
@implementation CBS_GetDeviceShareListResponse @end


//
@implementation BodyModifyChanNameRequest @end
@implementation BodyModifyChanNameResponse @end
@implementation CBS_ModifyChanNameRequest
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"ModifyChanNameRequest";
    }
    return self;
}
@end
//ModifyChanNameResponse
@implementation CBS_ModifyChanNameResponse @end



//
@implementation BodyGetSubDevListAfterForceUnbindingReq @end
@implementation BodyGetSubDevListAfterForceUnbindingResp @end
@implementation CBS_GetSubDevListAfterForceUnbindingReq
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"GetSubDevListRecordRequest";
    }
    return self;
}
@end
@implementation CBS_GetSubDevListAfterForceUnbindingResp @end


//
@implementation ForceUnbindDevModel @end

@implementation BodyGetDevListAfterForceUnbindingReq @end
@implementation BodyGetDevListAfterForceUnbindingResp @end
@implementation CBS_GetDevListAfterForceUnbindingReq
-(id)init{
    self = [super init];
    if (self) {
        self.MessageType = @"GetUserForceDevRequest";
    }
    return self;
}
@end
@implementation CBS_GetDevListAfterForceUnbindingResp @end

