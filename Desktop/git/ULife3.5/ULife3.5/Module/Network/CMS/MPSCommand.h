//
//  MPSCommand.h
//  ULifePro
//
//  Created by zhuochuncai on 24/4/17.
//  Copyright © 2017年 Gospell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPSCommandRequest : NSObject
@property(nonatomic,copy)NSString *MessageType;
-(NSDictionary *)requestCMDData;
@end

@interface MPSCommandResponse : NSObject
@property(nonatomic,assign)int ResultCode;
@end


@interface MPS_LoginRequest : MPSCommandRequest
@property(nonatomic,copy)NSString *Terminal;    //iphone
@property(nonatomic,copy)NSString *UserName;    //Account
@property(nonatomic,copy)NSString *PassWord;
@property(nonatomic,copy)NSString *Token;       //from Apple
@property(nonatomic,copy)NSDictionary *Language;       //{"Cur":"chinese","Def":"chinese"}
@end

@interface MPS_LoginResponse : MPSCommandResponse
@property(nonatomic,copy)NSString *PingGap;     //心跳间隔
@property(nonatomic,copy)NSString *Date;        //服务器当前日期
@property(nonatomic,copy)NSString *History;     //服务器能够保存几天的消息
@property(nonatomic,copy)NSString *Token;
@end


@interface MPS_LogoutRequest : MPSCommandRequest
@property(nonatomic,copy)NSString *Terminal;    //iphone
@property(nonatomic,copy)NSString *UserName;    //Account
@property(nonatomic,copy)NSString *Token;       //from Apple
@end

@interface MPS_LogoutResponse : MPSCommandRequest
@end


@interface MPS_QueryMsgInfoReq : MPSCommandRequest
@property(nonatomic,strong)NSArray *Dates;
@end

@interface MPS_QueryMsgInfoResp: MPSCommandResponse
@property(nonatomic,strong)NSDictionary *Dates;
@end



@interface MPS_GetMsgReq : MPSCommandRequest
@property(nonatomic,strong)NSString *Date;
@property(nonatomic,strong)NSDictionary *MsgIdBetween;
@end

@interface MPS_GetMsgResp: MPSCommandResponse
@property(nonatomic,strong)NSDictionary *Msgs;
@property(nonatomic,strong)NSString *Date;
@end



@interface MPS_SetMsgReadReq : MPSCommandRequest
@property(nonatomic,strong)NSString *Date;
@property(nonatomic,strong)NSString *MsgId;
@end
@interface MPS_SetMsgReadResp : MPSCommandResponse
@end



@interface MPS_PushMsgReq : MPSCommandRequest
@property(nonatomic,copy)NSString *Date;
@property(nonatomic,strong)NSDictionary *Type;
@end
