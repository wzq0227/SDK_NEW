//
//  CMSCommand.h
//  ULifePro
//
//  Created by zhuochuncai on 14/4/17.
//  Copyright © 2017年 Gospell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMSCommandRequest : NSObject
@property(nonatomic,copy)NSString *MessageType;
-(NSDictionary *)requestCMDData;
@end

@interface CMSCommandResponse : NSObject
@property(nonatomic,assign)int ResultCode;
@end

@interface ServerAddress : NSObject
@property(nonatomic,assign) int Type;
@property(nonatomic,assign) int Port;
@property(nonatomic,copy)NSString *Address;
@end



@interface CMD_GetAllAreaInfoRequest : CMSCommandRequest
@property(nonatomic,copy)NSString *AppKey;
@end
@interface CMD_GetAllAreaInfoResponse : CMSCommandResponse
@property(nonatomic,copy)NSMutableArray *AreaList;
@end



@interface CMD_UserRegisterRequest : CMSCommandRequest
@property(nonatomic,copy)NSString *UserName;
@property(nonatomic,copy)NSString *Password;
@property(nonatomic,copy)NSString *PhoneNumber;
@property(nonatomic,copy)NSString *EmailAddr;
@property(nonatomic,copy)NSString *AreaId;
@end
@interface CMD_UserRegisterResponse : CMSCommandResponse
@end



@interface CMD_RetrievePasswordRequest : CMSCommandRequest
@property(nonatomic,copy)NSString *UserName;
@property(nonatomic,copy)NSString *Password;
@property(nonatomic,copy)NSString *VerificationCode;
@property(nonatomic,copy)NSString *AreaId;
@end
@interface CMD_RetrievePasswordResponse : CMSCommandResponse
@end

@interface CMD_AppGetBSAddressRequest : CMSCommandRequest
@property(nonatomic,copy)NSString *UserName;
@property(nonatomic,copy)NSString *Password;
@property(nonatomic,copy)NSArray *ServerType;
@end
@interface CMD_AppGetBSAddressResponse : CMSCommandResponse
@property(nonatomic,copy)NSString *UserName;
@property(nonatomic,copy)NSMutableArray *ServerList;
@end

@interface CMD_LoginGetCGSAAddressReq : CMSCommandRequest
@property(nonatomic,copy)NSString *UserName;
@property(nonatomic,copy)NSString *Password;
@end
@interface CMD_LoginGetCGSAAddressResp : CMSCommandRequest
@property(nonatomic,copy)NSString *CGSAAddress;
@property(nonatomic,assign)int CGSAPort;
@end


@interface CMD_QueryNewerVersionReq : CMSCommandRequest
@property(nonatomic,copy)NSString *DeviceId;
@property(nonatomic,copy)NSString *DevType;
@property(nonatomic,copy)NSString *AppVersion;
@property(nonatomic,copy)NSString *FwVersion;
@property(nonatomic,copy)NSString *UbootVersion;
@property(nonatomic,copy)NSString *KernelVersion;
@property(nonatomic,copy)NSString *CustomType;
@property(nonatomic,copy)NSString *HardWareVersion;

@end
@interface CMD_QueryNewerVersionResp : CMSCommandResponse
@property(nonatomic,copy)NSString *DeviceId;
@property(nonatomic,assign)int HasNewer;
@property(nonatomic,copy)NSString *app;
@property(nonatomic,copy)NSString *fw;
@property(nonatomic,copy)NSString *uboot;
@property(nonatomic,copy)NSString *kernel;
@property(nonatomic,copy)NSString *UpsIp;
@property(nonatomic,copy)NSDictionary *Des;
@property(nonatomic,assign)int UpsPort;
@end
