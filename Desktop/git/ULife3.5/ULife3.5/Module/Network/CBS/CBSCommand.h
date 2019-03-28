//
//  CBSCommand.h
//  ULifePro
//
//  Created by zhuochuncai on 14/4/17.
//  Copyright © 2017年 Gospell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYModel.h"
#import "DeviceDataModel.h"

@interface BodyData : NSObject
@property(nonatomic,copy)NSString *SessionId;
@end
@interface BodyResponseData : BodyData
@property(nonatomic,copy)NSString *AreaId;
@end
@interface CBSCommandRequest : NSObject
@property (nonatomic,copy  ) NSString *MessageType;
-(NSDictionary*)requestCMDData;
@end
@interface CBSCommandResponse : NSObject
@property (nonatomic,copy  ) NSString *MessageType;
@property (nonatomic,assign) int      ResultCode;
@end



#pragma mark -- Register --
@interface BodyRegisterRequest : NSObject
@property (nonatomic,copy  ) NSString *UserName;
@property (nonatomic,copy  ) NSString *Password;
@property (nonatomic,copy  ) NSString *EmailAddr;
@property (nonatomic,copy  ) NSString *PhoneNumber;
@property (nonatomic,copy  ) NSString *AreaId;
@property (nonatomic,assign) int      RegisterWay; //2– 邮箱地址 3–电话号码
@property (nonatomic,assign) NSString *VerifyCode;
@property (nonatomic,assign) int      UserType;     //1-中性, 2-VOXX

@end
@interface BodyRegisterResponse : NSObject
@end
@interface CBS_RegisterRequest : CBSCommandRequest
@property(nonatomic,strong) BodyRegisterRequest *Body;
@end
@interface CBS_RegisterResponse : CBSCommandResponse
@property(nonatomic,strong) BodyRegisterResponse *Body;
@end


#pragma mark -- Login --
@interface BodyLoginRequest : NSObject
@property(nonatomic,copy)NSString *UserName;
@property(nonatomic,copy)NSString *Password;
@end
@interface BodyLoginResponse : BodyResponseData
@end
@interface CBS_LoginRequest : CBSCommandRequest
@property(nonatomic,strong) BodyLoginRequest *Body;
@end
@interface CBS_LoginResponse : CBSCommandResponse
@property(nonatomic,strong) BodyLoginResponse *Body;
@end



#pragma mark  -- Bind Device --
@interface BodyBindRequest : BodyData
@property(nonatomic,copy)NSString *UserName;
@property(nonatomic,copy)NSString *DeviceId;
@property(nonatomic,copy)NSString *DeviceName;
@property(nonatomic,copy)NSString *StreamUser;
@property(nonatomic,copy)NSString *StreamPassword;
@property(nonatomic,copy)NSString *AreaId;
@property(nonatomic,assign)int     DeviceType;  //1 IPC 2 NVR
@property(nonatomic,assign)int     DeviceOwner; //1 owner 0 share
@end
@interface BodyBindResponse : BodyResponseData
@end
@interface CBS_BindRequest : CBSCommandRequest
@property(nonatomic,strong) BodyBindRequest *Body;
@end
@interface CBS_BindResponse : CBSCommandResponse
@property(nonatomic,strong) BodyBindResponse *Body;
@end



#pragma mark  -- Unbind Device --
@interface BodyUnbindRequest : BodyData
@property(nonatomic,copy)NSString *UserName;
@property(nonatomic,copy)NSString *DeviceId;
@property(nonatomic,assign)int DeviceOwner; //1 owner 0 share
@end
@interface BodyUnbindResponse : BodyResponseData
@end
@interface CBS_UnbindRequest : CBSCommandRequest
@property(nonatomic,strong) BodyUnbindRequest *Body;
@end
@interface CBS_UnbindResponse : CBSCommandResponse
@property(nonatomic,strong) BodyUnbindResponse *Body;
@end


#pragma mark  -- Strong Unbind Device --
@interface BodyStrongUnbindRequest : BodyData
@property (nonatomic,copy)NSString *DeviceId;
@end

@interface BodyStrongUnbindResponse : BodyResponseData
@end

@interface CBS_StrongUnbindRequest : CBSCommandRequest
@property(nonatomic,strong) BodyUnbindRequest *Body;
@end
@interface CBS_StrongUnbindResponse : CBSCommandResponse
@property(nonatomic,strong) BodyUnbindResponse *Body;
@end


#pragma mark  -- ModifyDeviceAttr  --
@interface BodyModifyAttrRequest : BodyData
@property(nonatomic,copy)NSString *DeviceId;
@property(nonatomic,copy)NSString *DeviceName;
@property(nonatomic,copy)NSString *StreamUser;
@property(nonatomic,copy)NSString *StreamPassword;
@end
@interface BodyModifyAttrResponse : BodyResponseData
@end
@interface CBS_ModifyAttrRequest : CBSCommandRequest
@property(nonatomic,strong) BodyModifyAttrRequest *Body;
@end
@interface CBS_ModifyAttrResponse : CBSCommandResponse
@property(nonatomic,strong) BodyModifyAttrResponse *Body;
@end



#pragma mark  -- GetDeviceList  --
@interface BodyGetDevListRequest : BodyData
@property(nonatomic,copy)NSString *UserName;
@end
@interface BodyGetDevListResponse : BodyData
@property(nonatomic,strong)NSArray *DeviceList;
@end
@interface CBS_GetDevListRequest : CBSCommandRequest
@property(nonatomic,strong) BodyGetDevListRequest *Body;
@end
@interface CBS_GetDevListResponse : CBSCommandResponse
@property(nonatomic,strong) BodyGetDevListResponse *Body;
@end


#pragma mark  -- GetSubDeviceList  --
@interface BodyGetSubDevListRequest : BodyData
@property(nonatomic,copy)NSString *UserName;
@end
@interface BodyGetSubDevListResponse : BodyData
@property(nonatomic,strong)NSArray<SubDevInfoModel*> *SubDevList;//SubDeviceList;
@end
@interface CBS_GetSubDevListRequest : CBSCommandRequest
@property(nonatomic,strong) BodyGetSubDevListRequest *Body;
@end
@interface CBS_GetSubDevListResponse : CBSCommandResponse
@property(nonatomic,strong) BodyGetSubDevListResponse *Body;
@end



#pragma mark  -- QueryBindState  --
@interface BodyQueryBindRequest : BodyData
@property(nonatomic,copy)NSString *UserName;
@property(nonatomic,copy)NSString *DeviceId;
@end
@interface BodyQueryBindResponse : BodyQueryBindRequest
@property(nonatomic,assign)int BindStatus;
@end
@interface CBS_QueryBindRequest : CBSCommandRequest
@property(nonatomic,strong) BodyQueryBindRequest *Body;
@end
@interface CBS_QueryBindResponse : CBSCommandResponse
@property(nonatomic,strong) BodyQueryBindResponse *Body;
@end



#pragma mark  -- ModifyUserPwd Device --
@interface BodyModifyUserPwdRequest : BodyData
@property(nonatomic,copy)NSString *UserName;
@property(nonatomic,copy)NSString *OldPassword;
@property(nonatomic,copy)NSString *NewPassword;
@end
@interface BodyModifyUserPwdResponse : BodyData
@end
@interface CBS_ModifyUserPwdRequest : CBSCommandRequest
@property(nonatomic,strong) BodyModifyUserPwdRequest *Body;
@end
@interface CBS_ModifyUserPwdResponse : CBSCommandResponse
@property(nonatomic,strong) BodyModifyUserPwdResponse *Body;
@end



#pragma mark -- ForgetPWD --
@interface BodyGetVerifyCodePwdRequest : BodyData
@property(nonatomic,assign)int  FindPasswordType;   //1用户名， 2 邮箱  3 手机
@property(nonatomic,strong)NSString *UserInfo;
@property(nonatomic,assign)int  VerifyWay;          //1-用户注册, 2-忘记密码
@property(nonatomic,assign)int  UserType;           //1-中性, 2-VOXX 9-门铃
@end
@interface CMD_GetVerifyCodeRequest : CBSCommandRequest
@property(nonatomic,strong)BodyGetVerifyCodePwdRequest *Body;
@end
@interface CMD_GetVerifyCodeResponse : CBSCommandResponse
@end

@interface BodyModifyPasswordByVerifyRequest : BodyData
@property(nonatomic,assign)int       FindPasswordType; //1用户名， 2 邮箱  3 手机
@property(nonatomic,strong)NSString *UserInfo;
@property(nonatomic,strong)NSString *NewPassword;
@property(nonatomic,strong)NSString *VerifyCode;

@end
@interface CMD_ModifyPasswordByVerifyRequest : CBSCommandRequest
@property(nonatomic,strong)BodyModifyPasswordByVerifyRequest *Body;
@end
@interface CMD_ModifyPasswordByVerifyResponse : CBSCommandResponse
@end



#pragma mark  -- CheckDeviceRegister Status --
@interface BodyCheckDeviceRegisterRequest : BodyData
@property(nonatomic,copy)NSString *UserName;
@property(nonatomic,copy)NSString *DeviceId;
@end
@interface BodyCheckDeviceRegisterResponse : BodyData
@property(nonatomic,copy)NSString *UserName;
@property(nonatomic,copy)NSString *DeviceId;
@property (assign, nonatomic)  int Status;
@end

@interface CBS_CheckDeviceRegisterRequest : CBSCommandRequest
@property(nonatomic,strong) BodyCheckDeviceRegisterRequest *Body;
@end
@interface CBS_CheckDeviceRegisterResponse : CBSCommandResponse
@property(nonatomic,strong) BodyCheckDeviceRegisterResponse *Body;
@end



//子设备信息
//@interface SubDevInfo:NSObject
//
//@property (strong, nonatomic)  NSString *DeviceId;
//
//@property (strong, nonatomic)  NSString *SubId;
//
//@property (assign, nonatomic)  NSInteger ChanNum;           //通道号
//
//@property (assign, nonatomic)  NSInteger Status;            //
//
//@property (assign, nonatomic)  NSInteger Online;            //上报状态
//
//@property (strong, nonatomic)  NSString *ChanName;
//
//@end


//查询子设备上报状态
@interface BodyCheckSubDevRegisterRequest : BodyData

@property(nonatomic,copy)NSString *DeviceId;
@end
@interface BodyCheckSubDevRegisterResponse : BodyData

@property(nonatomic,copy)NSString *DeviceId;

@property (strong, nonatomic)  NSMutableArray *SubDevList;
@end

@interface CBS_CheckSubDevRegisterRequest : CBSCommandRequest
@property(nonatomic,strong) BodyCheckSubDevRegisterRequest *Body;
@end
@interface CBS_CheckSubDevRegisterResponse : CBSCommandResponse
@property(nonatomic,strong) BodyCheckSubDevRegisterResponse *Body;
@end



//添加子设备
@interface BodyAddSubDevRequest : BodyData

@property (strong, nonatomic)  NSString *DeviceId;
@property (strong, nonatomic)  NSString *SubId;
@property (strong, nonatomic)  NSString *ChanName;
@property (assign, nonatomic)  NSInteger ChanNum;
@end
@interface BodyAddSubDevResponse : BodyData

@property(nonatomic,copy)NSString *DeviceId;
@property (strong, nonatomic)  NSString *SubId;
@end

@interface CBS_AddSubDevRequest : CBSCommandRequest
@property(nonatomic,strong) BodyAddSubDevRequest *Body;
@end
@interface CBS_AddSubDevResponse : CBSCommandResponse
@property(nonatomic,strong) BodyAddSubDevResponse *Body;
@end



//删除子设备
@interface BodyDeleteSubDevRequest : BodyData

@property (strong, nonatomic)  NSString *DeviceId;
@property (strong, nonatomic)  NSString *SubId;
@end

@interface BodyDeleteSubDevResponse : BodyData

@property(nonatomic,copy)NSString *DeviceId;
@property (strong, nonatomic)  NSString *SubId;
@end


//5200 门铃删除子设备（子设备存储在服务器，通过服务器 删除）
@interface CBS_DeleteSubDevRequest : CBSCommandRequest
@property(nonatomic,strong) BodyDeleteSubDevRequest *Body;
@end
@interface CBS_DeleteSubDevResponse : CBSCommandResponse
@property(nonatomic,strong) BodyDeleteSubDevResponse *Body;
@end



//获取设备分享给了哪些用户
@interface BodyGetDeviceShareListRequest : BodyData
@property (strong, nonatomic)  NSString *DeviceId;
//@property(nonatomic,copy)NSString *UserName; 
@end

@interface BodyGetDeviceShareListResponse : BodyData
//@property(nonatomic,copy)NSString *DeviceId;
@property (strong, nonatomic)  NSArray *UserList;
@end

//
@interface CBS_GetDeviceShareListRequest : CBSCommandRequest
@property(nonatomic,strong) BodyGetDeviceShareListRequest *Body;
@end
@interface CBS_GetDeviceShareListResponse : CBSCommandResponse
@property(nonatomic,strong) BodyGetDeviceShareListResponse *Body;
@end




//修改设备通道名称
@interface BodyModifyChanNameRequest : BodyData
@property (strong, nonatomic)  NSString *DeviceId;
@property (strong, nonatomic)  NSString *ChanName;
@property (assign, nonatomic)  NSInteger ChanNum;
@end

@interface BodyModifyChanNameResponse : BodyData
@property(nonatomic,copy)NSString *DeviceId;
@property (assign, nonatomic)  NSInteger ChanNum;
@end

@interface CBS_ModifyChanNameRequest : CBSCommandRequest
@property(nonatomic,strong) BodyModifyChanNameRequest *Body;
@end
@interface CBS_ModifyChanNameResponse : CBSCommandResponse
@property(nonatomic,strong) BodyModifyChanNameResponse *Body;
@end


//获取中继被强解绑后的子设备列表-用于云服务回放
@interface BodyGetSubDevListAfterForceUnbindingReq : BodyData
@property(nonatomic,strong)  NSString *DeviceId;
@property(nonatomic,strong)  NSString *UserName;
@end

@interface BodyGetSubDevListAfterForceUnbindingResp : BodyData
@property(nonatomic,strong)  NSString  *DeviceCap;
@property(nonatomic,strong)  NSArray<SubDevInfoModel*> *SubDevList;
@end

@interface CBS_GetSubDevListAfterForceUnbindingReq : CBSCommandRequest
@property(nonatomic,strong) BodyGetSubDevListAfterForceUnbindingReq *Body;
@end
@interface CBS_GetSubDevListAfterForceUnbindingResp : CBSCommandResponse
@property(nonatomic,strong) BodyGetSubDevListAfterForceUnbindingResp *Body;
@end


@interface ForceUnbindDevModel:NSObject

@property (nonatomic, strong)  NSString *DevName;
@property (nonatomic, strong)  NSString *DevId;
@property (nonatomic, strong)  NSString *DevCap;
@end

//获取中继被强解绑后的设备列表-用于云服务回放
@interface BodyGetDevListAfterForceUnbindingReq : BodyData
//@property(nonatomic,strong)  NSString *DeviceId;
@property(nonatomic,strong)  NSString *UserName;
@end

@interface BodyGetDevListAfterForceUnbindingResp : BodyData
@property(nonatomic,strong)  NSArray<ForceUnbindDevModel*> *ForceDevList;
@end

@interface CBS_GetDevListAfterForceUnbindingReq : CBSCommandRequest
@property(nonatomic,strong) BodyGetDevListAfterForceUnbindingReq *Body;
@end
@interface CBS_GetDevListAfterForceUnbindingResp : CBSCommandResponse
@property(nonatomic,strong) BodyGetDevListAfterForceUnbindingResp *Body;
@end
