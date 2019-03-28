//
//  QQIGetDeviceListSocket.m
//  QQI
//
//  Created by shenyuanluo on 2017/2/22.
//  Copyright © 2017年 yuanx. All rights reserved.
//

#import "QQIGetDeviceListSocket.h"
#import "MJExtension.h"

#define BUFFER_LEN (1024 * 20)
#define GET_DEVICE_LIST_IP_ZH   @"120.24.84.182"    // 国内服务器
#define GET_DEVICE_LIST_IP_EN   @"52.41.26.100"

#define IS_NVR_ID_FLAG  @"0001"  // NVR 设备标识
#define NO_NVR_ID_FLAG  @"0000"  // IPC 设备标识

#define DOMAIN_ZH   @"010101"   // 国内 domain
#define DOMAIN_EN   @"900101"   // 国外 domain

#define GET_DEVICE_LIST_PORT    20002


@interface QQIGetDeviceListSocket ()
{
    char _recvBuff[BUFFER_LEN];
    int _recvBuffLength;        // 总缓存已接收数据长度
}

@property (nonatomic, copy) NSString *userLoginId;   // 用户登录ID
@property (nonatomic, strong) Class resultClass;
@property (nonatomic, strong) dispatch_queue_t getDeviceListSocketQuque;
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSString *getDeviceListHost;
@property (nonatomic, assign) u_int16_t getDeviceListPort;
@property (nonatomic, copy)   NSString *userName;
@property (nonatomic, copy)   NSString *userPwd;
@property (nonatomic, copy)   NSString *Httptype;
@property (nonatomic, copy)   NSString *requestBody;
@property (nonatomic, copy)   NSString *sendMsg;
@property (nonatomic, copy)   NSString *NewUserPassWord;
@property (nonatomic, copy)   NSString *OldUserPassWord;
@property (nonatomic, copy)   NSString *emailString;
@property (nonatomic, copy)   NSString *checkCode;
@property (nonatomic, copy)   NSString *devID;
@property (nonatomic, copy)   NSString *domain;
@property (nonatomic, assign)   int userRight;
@property (nonatomic, strong) NSDictionary * dic;
@property (nonatomic, copy)   NSString *devName;
@end

@implementation QQIGetDeviceListSocket

static QQIGetDeviceListSocket *_getDeviceListSocket = nil;
static QQIGetDeviceListSocket *_NewgetDeviceListSocket = nil;



+ (instancetype)shareInstanceUpListand:(NSString *)ip andPort:(NSString *)port
{
    
    static dispatch_once_t onceToken;
    
    if (!_NewgetDeviceListSocket)
    {
        dispatch_once(&onceToken, ^{
            
            
            
            _NewgetDeviceListSocket = [[QQIGetDeviceListSocket alloc]initWith:ip andPort:port];
            
            
        });
    }
    
    return _NewgetDeviceListSocket;
}




+ (instancetype)shareInstance
{
    
    static dispatch_once_t onceToken;
    
    if (!_getDeviceListSocket)
    {
        dispatch_once(&onceToken, ^{
            
            _getDeviceListSocket = [[QQIGetDeviceListSocket alloc] init];
        });
    }
    
    return _getDeviceListSocket;
}


- (instancetype)init
{
    if (self = [super init])
    {
        self.getDeviceListSocketQuque = dispatch_queue_create("getDeviceListSocketQuque", DISPATCH_QUEUE_CONCURRENT);
        self.socket = [[GCDAsyncSocket alloc]initWithDelegate:self
                                                delegateQueue:self.getDeviceListSocketQuque];
        NSString *ip   = nil;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *allLanguages    = [defaults objectForKey:@"AppleLanguages"];
        NSString *preferredLang  = [allLanguages objectAtIndex:0];
        if( 7 <= preferredLang.length
           && [[preferredLang substringToIndex:7] isEqualToString:@"zh-Hans"])
        {
            ip = GET_DEVICE_LIST_IP_ZH;
        }
        else
        {
            ip = GET_DEVICE_LIST_IP_EN;
        }
        self.getDeviceListHost = ip;
        self.getDeviceListPort = GET_DEVICE_LIST_PORT;
    }
    return self;
}



- (instancetype)initWith:(NSString *)IP andPort:(NSString *)port
{
    if (self = [super init])
    {
        self.getDeviceListSocketQuque = dispatch_queue_create("getDeviceListSocketQuque", DISPATCH_QUEUE_CONCURRENT);
        self.socket = [[GCDAsyncSocket alloc]initWithDelegate:self
                                                delegateQueue:self.getDeviceListSocketQuque];
        self.getDeviceListHost = IP;
        self.getDeviceListPort = [port intValue];
    }
    return self;
}


#pragma mark -- 根据设备类型获取设备标识串
- (NSString *)GetDeviceTagWithType:(DeviceType)deviceType
{
    switch (deviceType)
    {
        case DeviceIPC:
        {
            return NO_NVR_ID_FLAG;
        }
            break;
            
        case DeviceNVR:
        {
            return IS_NVR_ID_FLAG;
        }
            break;
            
        default:
        {
            return nil;
        }
            break;
    }
}


#pragma mark -- 根据语言环境获取 domain
- (NSString *)getDomain
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *allLanguages    = [defaults objectForKey:@"AppleLanguages"];
    NSString *preferredLang  = [allLanguages objectAtIndex:0];
    if( 7 <= preferredLang.length
       && [[preferredLang substringToIndex:7] isEqualToString:@"zh-Hans"])
    {
        return DOMAIN_ZH;
    }
    else
    {
        return DOMAIN_EN;
    }
}


#pragma mark -- 获取设备 ID
- (NSString *)getDeviceIdWithType:(DeviceType)deviceType
                      rawDeviceId:(NSString *)rawDeviceId
{
    NSString *deviceId = [NSString stringWithFormat:@"%@%@%@", [self getDomain], [self GetDeviceTagWithType:deviceType], rawDeviceId];
    
    return deviceId;
}



#pragma mark -- 修改设备名字
- (void)DeviceChangeDevAttrReqWithUserId:(NSString *)userld
                                andDevId:(NSString *)devid
                              andDevName:(NSString *)devName
                              deviceType:(DeviceType)deviceType;
{
    self.Httptype    = @"ChangeDevAttrReq";
    self.userLoginId = userld;
    self.devID       = [self getDeviceIdWithType:deviceType
                                     rawDeviceId:devid];
    self.devName     = devName;
    
    [self startConnect];
}




#pragma mark --  解绑设备
- (void)DeviceUnBindDevReqWithUserId:(NSString *)userld
                            andDevId:(NSString *)devid
                          deviceType:(DeviceType)deviceType
{
    self.Httptype    = @"UnBindDevReq";
    self.userLoginId = userld;
    self.devID       = [self getDeviceIdWithType:deviceType
                                     rawDeviceId:devid];
    
    [self startConnect];
}



#pragma mark -- 绑定设备
- (void)DeviceBindDevReqWithUserId:(NSString *)userId
                          andDevId:(NSString *)devId
                      andUserRight:(int)userRight
                        andDevInfo:(NSDictionary *)dic
                        deviceType:(DeviceType)deviceType
{
    self.Httptype    = @"BindDevReq";
    self.userLoginId = userId;
    self.devID       = [self getDeviceIdWithType:deviceType
                                     rawDeviceId:devId];
    self.userRight   = userRight;
    self.dic         = [[NSDictionary alloc] initWithDictionary:dic];
    
    [self startConnect];
}


//查询是否被绑定
- (void)DeviceFindDevBindReqWithUserId:(NSString *)userId
                              andDevId:(NSString *)devId
                            deviceType:(DeviceType)deviceType
{
    self.Httptype    = @"FindDevBindReq";
    self.userLoginId = userId;
    self.devID       = [self getDeviceIdWithType:deviceType
                                     rawDeviceId:devId];
    
    [self startConnect];
}




//忘记密码
-(void)DeviceForgetPwdWithUsename:(NSString *)userNameString
{
    self.Httptype=@"SendCheckCodeReq";
    self.userName=userNameString;
    [self startConnect];
}



//根据验证码重置密码
-(void)DeviceUseCheckCodeChangePwdReqWithUsename:(NSString *)userNameString
                                       andNewPwd:(NSString *)NewPwdString
                                    andCheckCode:(NSString *)checkCode
{
    self.Httptype=@"UseCheckCodeChangePwdReq";
    self.userName=userNameString;
    self.NewUserPassWord=NewPwdString;
    self.checkCode=checkCode;
    [self startConnect];
    
}




//注册账号
-(void)DeviceRegisterUsername:(NSString *)userNameString
                   andUserPwd:(NSString *)userPwd
                     andemail:(NSString *)email
{
    self.Httptype=@"RegisterReq";
    self.userName=userNameString;
    self.userPwd=userPwd;
    self.emailString=email;
    [self startConnect];
}



//修改密码
-(void)DeviceChangePwdWithUsername:(NSString *)userNameString
                         andNewPwd:(NSString *)newPwd
                         andOldPwd:(NSString *)oldPwd
{
    
    self.Httptype=@"changePwd";
    self.userName=userNameString;
    self.NewUserPassWord=newPwd;
    self.OldUserPassWord=oldPwd;
    [self startConnect];
}


//登录
-(void)DeviceloginWithUsename:(NSString *)useNameString
                    andUsePwd:(NSString *)usePwdSting
{
    
    if (!useNameString || 0 >= usePwdSting.length)
    {
        NSLog(@"用户登录ID不能为空！");
        return ;
    }
    self.Httptype=@"login";
    self.userName=useNameString;
    self.userPwd=usePwdSting;
    [self startConnect];
}



//刷列表
- (void)getDeviceListWithId:(NSString *)userLoginId
                resultClass:(Class)resultClass
{
    if (!userLoginId || 0 >= userLoginId.length
        || !resultClass)
    {
        NSLog(@"用户登录ID不能为空！");
        
        return ;
    }
    self.Httptype=@"list";
    self.userLoginId = userLoginId;
    self.resultClass = resultClass;
    
    [self startConnect];
}



- (void)startConnect
{
    if (!_socket.isConnected)
    {
        [self startConnectToServer];
        _recvBuffLength  = 0;
    }else{
        [_socket disconnect];
        [self startConnectToServer];
        _recvBuffLength  = 0;
    }
}



- (void)stopConnect
{
    if (_socket.isConnected)
    {
        NSLog(@"关闭获取设备列表 socket ！");
        [_socket disconnect];
    }
}


- (void)startConnectToServer
{
    
    NSError *error;
//    [_socket connectToHost:self.getDeviceListHost
//                    onPort:self.getDeviceListPort
//                     error:&error];
    [_socket connectToHost:self.getDeviceListHost onPort:self.getDeviceListPort withTimeout:10 error:&error];
    
    if (error) {
        NSLog(@"connnect______error:%@",error.description);
    }
}




#pragma mark-SocketDelegate

- (void)socketDidConnectTimeout{
    memset(_recvBuff, 0, sizeof(1024*20));
    NSLog(@"socketDid_______________________________________Connect___________Timeout");
    NSData *data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    [self socket:self.socket didReadData:data withTag:0];
}



- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(nonnull NSString *)host port:(uint16_t)port
{
    
    //修改属性
    if ([self.Httptype isEqualToString:@"ChangeDevAttrReq"]) {
        NSString * STR = self.dic[@"devName"];
        _requestBody = [NSString stringWithFormat:@"{\"cmdType\":\"ChangeDevAttrReq\",\"userId\":\"%@\",\"devId\":\"%@\",\"devInfo\":{\"streamName\":\"admin\",\"streamPwd\":\"goscam123\",\"devName\":\"%@\"}}", self.userLoginId,self.devID,self.devName];
        _sendMsg = [NSString stringWithFormat:@"POST / HTTP/1.1\r\nContent-type: application/json\r\nContent-Length: %lu\r\n\r\n{\"cmdType\":\"ChangeDevAttrReq\",\"userId\":\"%@\",\"devId\":\"%@\",\"devInfo\":{\"streamName\":\"admin\",\"streamPwd\":\"goscam123\",\"devName\":\"%@\"}}", (unsigned long)_requestBody.length,self.userLoginId,self.devID,self.devName];
    }
    //解除绑定
    if ([self.Httptype isEqualToString:@"UnBindDevReq"]) {
        _requestBody = [NSString stringWithFormat:@"{\"cmdType\":\"UnBindDevReq\",\"userId\":\"%@\",\"devId\":\"%@\"}", self.userLoginId,self.devID];
        _sendMsg = [NSString stringWithFormat:@"POST / HTTP/1.1\r\nContent-type: application/json\r\nContent-Length: %lu\r\n\r\n{\"cmdType\":\"UnBindDevReq\",\"userId\":\"%@\",\"devId\":\"%@\"}", (unsigned long)_requestBody.length,self.userLoginId,self.devID];
    }
    //绑定
    if ([self.Httptype isEqualToString:@"BindDevReq"]) {
        
        NSString * STR = self.dic[@"devName"];
        _requestBody = [NSString stringWithFormat:@"{\"cmdType\":\"BindDevReq\",\"userId\":\"%@\",\"devId\":\"%@\",\"userRight\":%d,\"devInfo\":{\"streamName\":\"admin\",\"streamPwd\":\"goscam123\",\"devName\":\"%@\"}}", self.userLoginId,self.devID,self.userRight,STR];
        _sendMsg = [NSString stringWithFormat:@"POST / HTTP/1.1\r\nContent-type: application/json\r\nContent-Length: %lu\r\n\r\n{\"cmdType\":\"BindDevReq\",\"userId\":\"%@\",\"devId\":\"%@\",\"userRight\":%d,\"devInfo\":{\"streamName\":\"admin\",\"streamPwd\":\"goscam123\",\"devName\":\"%@\"}}", (unsigned long)_requestBody.length,self.userLoginId,self.devID,self.userRight,STR];
    }
    //查询是否被绑定
    if ([self.Httptype isEqualToString:@"FindDevBindReq"]) {
        
        _requestBody = [NSString stringWithFormat:@"{\"cmdType\":\"FindDevBindReq\",\"userId\":\"%@\",\"devId\":\"%@\"}", self.userLoginId,self.devID];
        _sendMsg = [NSString stringWithFormat:@"POST / HTTP/1.1\r\nContent-type: application/json\r\nContent-Length: %lu\r\n\r\n{\"cmdType\":\"FindDevBindReq\",\"userId\":\"%@\",\"devId\":\"%@\"}", (unsigned long)_requestBody.length,self.userLoginId,self.devID];
    }
    //根据验证码重置密码
    if ([self.Httptype isEqualToString:@"UseCheckCodeChangePwdReq"]) {
        
        _requestBody = [NSString stringWithFormat:@"{\"cmdType\":\"UseCheckCodeChangePwdReq\",\"userName\":\"%@\",\"newPwd\":\"%@\",\"checkCode\":\"%@\"}", self.userName,self.NewUserPassWord,self.checkCode];
        _sendMsg = [NSString stringWithFormat:@"POST / HTTP/1.1\r\nContent-type: application/json\r\nContent-Length: %lu\r\n\r\n{\"cmdType\":\"UseCheckCodeChangePwdReq\",\"userName\":\"%@\",\"newPwd\":\"%@\",\"checkCode\":\"%@\"}", (unsigned long)_requestBody.length,self.userName,self.NewUserPassWord,self.checkCode];
    }
    //忘记密码
    if ([self.Httptype isEqualToString:@"SendCheckCodeReq"]) {
        
        _requestBody = [NSString stringWithFormat:@"{\"cmdType\":\"SendCheckCodeReq\",\"userName\":\"%@\",\"productKey\":1,\"expireTime\":600}", self.userName];
        _sendMsg = [NSString stringWithFormat:@"POST / HTTP/1.1\r\nContent-type: application/json\r\nContent-Length: %lu\r\n\r\n{\"cmdType\":\"SendCheckCodeReq\",\"userName\":\"%@\",\"productKey\":1,\"expireTime\":600}", (unsigned long)_requestBody.length,self.userName];
    }
    // 注册
    if ([self.Httptype isEqualToString:@"RegisterReq"]) {
        _requestBody = [NSString stringWithFormat:@"{\"cmdType\":\"RegisterReq\",\"userName\":\"%@\",\"pwd\":\"%@\",\"email\":\"%@\",\"customKey\":\"voxx\",\"expireTime\":600}", self.userName,self.userPwd,self.emailString];
        _sendMsg = [NSString stringWithFormat:@"POST / HTTP/1.1\r\nContent-type: application/json\r\nContent-Length: %lu\r\n\r\n{\"cmdType\":\"RegisterReq\",\"userName\":\"%@\",\"pwd\":\"%@\",\"email\":\"%@\",\"customKey\":\"voxx\",\"expireTime\":600}", (unsigned long)_requestBody.length,self.userName,self.userPwd,self.emailString];
    }
    //刷新列表
    if ([self.Httptype isEqualToString:@"list"]) {
        
        _requestBody = [NSString stringWithFormat:@"{\"cmdType\":\"GetDevListReq\",\"userId\":\"%@\"}", self.userLoginId];
        _sendMsg = [NSString stringWithFormat:@"POST / HTTP/1.1\r\nContent-type: application/json\r\nContent-Length: %lu\r\n\r\n{\"cmdType\":\"GetDevListReq\",\"userId\":\"%@\"}", (unsigned long)_requestBody.length, self.userLoginId];
    }
    //登录
    if ([self.Httptype isEqualToString:@"login"]) {
        
        _requestBody = [NSString stringWithFormat:@"{\"cmdType\":\"LoginReq\",\"userName\":\"%@\",\"pwd\":\"%@\"}",self.userName,self.userPwd];
        _sendMsg = [NSString stringWithFormat:@"POST / HTTP/1.1\r\nContent-type: application/json\r\nContent-Length: %lu\r\n\r\n{\"cmdType\":\"LoginReq\",\"userName\":\"%@\",\"pwd\":\"%@\"}", (unsigned long)_requestBody.length, self.userName,self.userPwd];
    }
    
    //修改密码
    if ([self.Httptype isEqualToString:@"changePwd"]) {
        
        _requestBody = [NSString stringWithFormat:@"{\"cmdType\":\"ChangePwdReq\",\"userName\":\"%@\",\"newPwd\":\"%@\",\"oldPwd\":\"%@\"}",self.userName,self.NewUserPassWord,self.OldUserPassWord];
        _sendMsg = [NSString stringWithFormat:@"POST / HTTP/1.1\r\nContent-type: application/json\r\nContent-Length: %lu\r\n\r\n{\"cmdType\":\"ChangePwdReq\",\"userName\":\"%@\",\"newPwd\":\"%@\",\"oldPwd\":\"%@\"}", (unsigned long)_requestBody.length, self.userName,self.NewUserPassWord,self.OldUserPassWord];
    }
    if (!_sendMsg || 0 >= _sendMsg.length)
    {
        return ;
    }
    NSData *data = [_sendMsg dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"获取设备列表请求");
    [self.socket writeData:data withTimeout:20 tag:1];
}



- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    memcpy(_recvBuff + _recvBuffLength, data.bytes, data.length);
    
    _recvBuffLength += data.length;
    _recvBuff[_recvBuffLength] = 0;
    char *headEnd = strstr(_recvBuff, "\r\n\r\n");  //http头
    
    
    if (NULL == headEnd)
    {
        
        
        if ([self.Httptype isEqualToString:@"ChangeDevAttrReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didChangeDevAttrRespResultCode:isSuccess:)])
            {
                [self.delegate didChangeDevAttrRespResultCode:-2017 isSuccess:NO];
            }
        }
        
        
        if ([self.Httptype isEqualToString:@"UnBindDevReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didUnBindDevRespResultCode:isSuccess:)])
            {
                [self.delegate didUnBindDevRespResultCode:-2017 isSuccess:NO];
            }
        }
        if ([self.Httptype isEqualToString:@"BindDevReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didBindDevRespWithResultCode:isSuccess:)])
            {
                [self.delegate didBindDevRespWithResultCode:-2017 isSuccess:NO];
            }
        }
        if ([self.Httptype isEqualToString:@"FindDevBindReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didFindDevBindRespWithDevId:andState:andResultCode:isSuccess:)])
            {
                [self.delegate didFindDevBindRespWithDevId:nil andState:-2017 andResultCode:-2017 isSuccess:NO];
            }
        }
        
        NSLog(@"无法获取 http 头，请求获取设备列表失败！");
        if ([self.Httptype isEqualToString:@"SendCheckCodeReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didSendCheckCodeRespisSuccess:)])
            {
                [self.delegate didSendCheckCodeRespisSuccess:NO];
            }
        }
        if ([self.Httptype isEqualToString:@"changePwd"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didChangPWD:)])
            {
                [self.delegate didChangPWD:NO];
            }
        }
        if ([self.Httptype isEqualToString:@"login"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didlogin:andMDS:andresultCode:isSuccess:)])
            {
                [self.delegate didlogin:nil andMDS:nil andresultCode:-2017 isSuccess:NO];
            }
        }
        if ([self.Httptype isEqualToString:@"list"]) {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didReceiveList:userLoginId:isSuccess:)])
            {
                [self.delegate didReceiveList:nil
                                  userLoginId:nil
                                    isSuccess:NO];
            }
        }
        if ([self.Httptype isEqualToString:@"RegisterReq"]) {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didRegisterResp:isSuccess:andresultCode:)])
            {
                [self.delegate didRegisterResp:nil isSuccess:NO andresultCode:-2017];
            }
        }
    }
    else
    {
        char *contentLengAddr = strstr(_recvBuff, "Content-length");
        if(contentLengAddr == NULL)
        {
            contentLengAddr = strstr(_recvBuff, "Content-Length");
        }
        if(contentLengAddr == NULL)
        {
            contentLengAddr = strstr(_recvBuff, "content-Length");
        }
        if(contentLengAddr == NULL)
        {
            contentLengAddr = strstr(_recvBuff, "content-length");
        }
        if(NULL == contentLengAddr|| contentLengAddr > headEnd)
        {
            NSLog(@"无法获取数据长度，请求获取设备列表失败");
            if ([self.Httptype isEqualToString:@"ChangeDevAttrReq"]) {
                
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(didChangeDevAttrRespResultCode:isSuccess:)])
                {
                    [self.delegate didChangeDevAttrRespResultCode:-2017 isSuccess:NO];
                }
            }
            
            
            if ([self.Httptype isEqualToString:@"UnBindDevReq"]) {
                
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(didUnBindDevRespResultCode:isSuccess:)])
                {
                    [self.delegate didUnBindDevRespResultCode:-2017 isSuccess:NO];
                }
            }
            
            
            if ([self.Httptype isEqualToString:@"BindDevReq"]) {
                
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(didBindDevRespWithResultCode:isSuccess:)])
                {
                    [self.delegate didBindDevRespWithResultCode:-2017 isSuccess:NO];
                }
            }
            
            
            
            if ([self.Httptype isEqualToString:@"FindDevBindReq"]) {
                
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(didFindDevBindRespWithDevId:andState:andResultCode:isSuccess:)])
                {
                    [self.delegate didFindDevBindRespWithDevId:nil andState:-2017 andResultCode:-2017 isSuccess:NO];
                }
            }
            
            if ([self.Httptype isEqualToString:@"changePwd"]) {
                
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(didChangPWD:)])
                {
                    [self.delegate didChangPWD:NO];
                }
            }
            
            if ([self.Httptype isEqualToString:@"changePwd"]) {
                
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(didChangPWD:)])
                {
                    [self.delegate didChangPWD:NO];
                }
            }
            
            if ([self.Httptype isEqualToString:@"login"]) {
                
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(didlogin:andMDS:andresultCode:isSuccess:)])
                {
                    [self.delegate didlogin:nil andMDS:nil andresultCode:-2017 isSuccess:NO];
                }
            }
            
            if ([self.Httptype isEqualToString:@"list"]) {
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(didReceiveList:userLoginId:isSuccess:)])
                {
                    [self.delegate didReceiveList:nil
                                      userLoginId:nil
                                        isSuccess:NO];
                }
            }
            if ([self.Httptype isEqualToString:@"RegisterReq"]) {
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(didRegisterResp:isSuccess:andresultCode:)])
                {
                    [self.delegate didRegisterResp:nil isSuccess:NO andresultCode:-2017];
                }
            }
            
            if ([self.Httptype isEqualToString:@"SendCheckCodeReq"]) {
                
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(didSendCheckCodeRespisSuccess:)])
                {
                    [self.delegate didSendCheckCodeRespisSuccess:NO];
                }
            }
            
        }
        else
        {
            contentLengAddr = contentLengAddr + sizeof("Content-Length"); //跳过Content-Length字符串
            while('0' > (*contentLengAddr) || '9' < (*contentLengAddr))
            {
                contentLengAddr++;
            }
            int jsonStrLen = 0;
            sscanf(contentLengAddr,"%d", &jsonStrLen);
            NSLog(@"解析获取的json串长度：%d", jsonStrLen);
            
            if (_recvBuffLength == (headEnd - _recvBuff) + strlen("\r\n\r\n") + jsonStrLen)   // 完整的数据包
            {
                NSString *recvMsg =[NSString stringWithUTF8String:(headEnd + strlen("\r\n\r\n"))];
                NSLog(@"接收到：%ld 长度的字节，内容是：%@", recvMsg.length, recvMsg);
                
                [self parseJsonString:recvMsg];
            }
        }
    }
    [self.socket readDataWithTimeout:30 tag:0  ];
}



#pragma mark - 解析请求获取设备列表返回的 JSON 数据
- (void)parseJsonString:(NSString *)jsonStr
{
    
    if (!jsonStr || 0 >= jsonStr)
    {
        return ;
    }
    NSData *responseJsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *responJsonStr = [NSJSONSerialization JSONObjectWithData:responseJsonData
                                                                  options:NSJSONReadingMutableContainers
                                                                    error:&error];
    
    NSLog(@"%@",responJsonStr);
    if(error)
    {
        [self stopConnect];
        if ([self.Httptype isEqualToString:@"ChangeDevAttrReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didChangeDevAttrRespResultCode:isSuccess:)])
            {
                [self.delegate didChangeDevAttrRespResultCode:-2017 isSuccess:NO];
            }
        }
        
        if ([self.Httptype isEqualToString:@"UnBindDevReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didUnBindDevRespResultCode:isSuccess:)])
            {
                [self.delegate didUnBindDevRespResultCode:-2017 isSuccess:NO];
            }
        }
        
        
        if ([self.Httptype isEqualToString:@"BindDevReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didBindDevRespWithResultCode:isSuccess:)])
            {
                [self.delegate didBindDevRespWithResultCode:-2017 isSuccess:NO];
            }
        }
        if ([self.Httptype isEqualToString:@"FindDevBindReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didFindDevBindRespWithDevId:andState:andResultCode:isSuccess:)])
            {
                [self.delegate didFindDevBindRespWithDevId:nil andState:-2017 andResultCode:-2017 isSuccess:NO];
            }
        }
        
        
        if ([self.Httptype isEqualToString:@"UseCheckCodeChangePwdReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didUseCheckCodeChangePwdReqisSuccess:andresultCode:)])
            {
                [self.delegate didUseCheckCodeChangePwdReqisSuccess:NO andresultCode:-2017];
            }
        }
        
        if ([self.Httptype isEqualToString:@"SendCheckCodeReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didSendCheckCodeRespisSuccess:)])
            {
                [self.delegate didSendCheckCodeRespisSuccess:NO];
            }
        }
        
        
        if ([self.Httptype isEqualToString:@"changePwd"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didChangPWD:)])
            {
                [self.delegate didChangPWD:NO];
            }
        }
        
        if ([self.Httptype isEqualToString:@"login"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didlogin:andMDS:andresultCode:isSuccess:)])
            {
                [self.delegate didlogin:nil andMDS:nil andresultCode:-2017 isSuccess:NO];
            }
        }
        
        if ([self.Httptype isEqualToString:@"list"]) {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didReceiveList:userLoginId:isSuccess:)])
            {
                [self.delegate didReceiveList:nil
                                  userLoginId:nil
                                    isSuccess:NO];
            }
        }
        if ([self.Httptype isEqualToString:@"RegisterReq"]) {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didRegisterResp:isSuccess:andresultCode:)])
            {
                [self.delegate didRegisterResp:nil isSuccess:NO andresultCode:-2017];
            }
        }
        return ;
    }
    // 请求成功
    if ([[NSNull null] isEqual:responJsonStr[@"resultCode"]])
    {
        [self stopConnect];
        NSLog(@"请求获取设备列表时，服务器返回的‘RetCode’为空，无法判断请求数据成功与否！");
        if ([self.Httptype isEqualToString:@"ChangeDevAttrReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didChangeDevAttrRespResultCode:isSuccess:)])
            {
                [self.delegate didChangeDevAttrRespResultCode:-2017 isSuccess:NO];
            }
        }
        
        if ([self.Httptype isEqualToString:@"UnBindDevReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didUnBindDevRespResultCode:isSuccess:)])
            {
                [self.delegate didUnBindDevRespResultCode:-2017 isSuccess:NO];
            }
        }
        
        
        if ([self.Httptype isEqualToString:@"BindDevReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didBindDevRespWithResultCode:isSuccess:)])
            {
                [self.delegate didBindDevRespWithResultCode:-2017 isSuccess:NO];
            }
        }
        if ([self.Httptype isEqualToString:@"UseCheckCodeChangePwdReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didUseCheckCodeChangePwdReqisSuccess:andresultCode:)])
            {
                [self.delegate didUseCheckCodeChangePwdReqisSuccess:NO andresultCode:-2017];
            }
        }
        if ([self.Httptype isEqualToString:@"SendCheckCodeReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didSendCheckCodeRespisSuccess:)])
            {
                [self.delegate didSendCheckCodeRespisSuccess:NO];
            }
        }
        
        if ([self.Httptype isEqualToString:@"FindDevBindReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didFindDevBindRespWithDevId:andState:andResultCode:isSuccess:)])
            {
                [self.delegate didFindDevBindRespWithDevId:nil andState:-2017 andResultCode:-2017 isSuccess:NO];
            }
        }
        if ([self.Httptype isEqualToString:@"changePwd"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didChangPWD:)])
            {
                [self.delegate didChangPWD:NO];
            }
        }
        
        if ([self.Httptype isEqualToString:@"login"]) {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didlogin:andMDS:andresultCode:isSuccess:)])
            {
                [self.delegate didlogin:nil andMDS:nil andresultCode:-2017 isSuccess:NO];
            }
        }
        
        if ([self.Httptype isEqualToString:@"list"]) {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didReceiveList:userLoginId:isSuccess:)])
            {
                [self.delegate didReceiveList:nil
                                  userLoginId:nil
                                    isSuccess:NO];
            }
        }
        if ([self.Httptype isEqualToString:@"RegisterReq"]) {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didRegisterResp:isSuccess:andresultCode:)])
            {
                [self.delegate didRegisterResp:nil isSuccess:NO andresultCode:-2017];
            }
        }
        return ;
    }
    int resultFlag = [responJsonStr[@"resultCode"] intValue];
    if (0 == resultFlag)    //"0"="success"
    {
        [self stopConnect];
        if ([self.Httptype isEqualToString:@"UnBindDevReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didUnBindDevRespResultCode:isSuccess:)])
            {
                [self.delegate didUnBindDevRespResultCode:resultFlag isSuccess:YES];
            }
        }
        
        if ([self.Httptype isEqualToString:@"ChangeDevAttrReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didChangeDevAttrRespResultCode:isSuccess:)])
            {
                [self.delegate didChangeDevAttrRespResultCode:resultFlag isSuccess:YES];
            }
        }
        
        
        
        if ([self.Httptype isEqualToString:@"BindDevReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didBindDevRespWithResultCode:isSuccess:)])
            {
                [self.delegate didBindDevRespWithResultCode:resultFlag isSuccess:YES];
            }
        }
        
        
        if ([self.Httptype isEqualToString:@"FindDevBindReq"]) {
            
            int count =[responJsonStr[@"state"] intValue];
            NSString * dev =responJsonStr[@"devId"];
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didFindDevBindRespWithDevId:andState:andResultCode:isSuccess:)])
            {
                [self.delegate didFindDevBindRespWithDevId:dev andState:count andResultCode:resultFlag isSuccess:YES];
            }
        }
        
        if ([self.Httptype isEqualToString:@"UseCheckCodeChangePwdReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didUseCheckCodeChangePwdReqisSuccess:andresultCode:)])
            {
                [self.delegate didUseCheckCodeChangePwdReqisSuccess:YES andresultCode:resultFlag];
            }
        }
        
        
        if ([self.Httptype isEqualToString:@"SendCheckCodeReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didSendCheckCodeRespisSuccess:)])
            {
                [self.delegate didSendCheckCodeRespisSuccess:YES];
            }
        }
        
        if ([self.Httptype isEqualToString:@"changePwd"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didChangPWD:)])
            {
                [self.delegate didChangPWD:YES];
            }
        }
        if ([self.Httptype isEqualToString:@"RegisterReq"]) {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didRegisterResp:isSuccess:andresultCode:)])
            {
                [self.delegate didRegisterResp:nil isSuccess:YES andresultCode:resultFlag];
            }
        }
        
        if ([self.Httptype isEqualToString:@"login"]) {
            
            NSDictionary * dic = responJsonStr[@"MDS"];
            NSString *respUserId = responJsonStr[@"userId"];
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didlogin:andMDS:andresultCode:isSuccess:)])
            {
                [self.delegate didlogin:respUserId andMDS:dic andresultCode:resultFlag isSuccess:YES];
            }
            
        }
        if ([self.Httptype isEqualToString:@"list"]) {
            
            if ([[NSNull null] isEqual:responJsonStr[@"devs"]])
            {
                NSLog(@"请求服务器获取设备列表数据失败，因为服务器返回的‘Devs’为 null ！");
                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(didReceiveList:userLoginId:isSuccess:)])
                {
                    [self.delegate didReceiveList:nil
                                      userLoginId:nil
                                        isSuccess:NO];
                }
                
                return ;
            }
            else
            {
                NSLog(@"请求服务器获取设备列表数据成功！");
                // 字典数组 -> 模型数组
                NSMutableArray *dictArray = responJsonStr[@"devs"];
                NSString *respUserId = responJsonStr[@"userId"];
                //            NSLog(@"+++++++++++++%@+++++++++++++++",respUserId);
                if (!dictArray || 0 >= dictArray.count)
                {
                    if (self.delegate
                        && [self.delegate respondsToSelector:@selector(didReceiveList:userLoginId:isSuccess:)])
                    {
                        [self.delegate didReceiveList:dictArray
                                          userLoginId:respUserId
                                            isSuccess:YES];
                    }
                }
                else
                {
                    NSMutableArray *deviceListArray = [self.resultClass mj_objectArrayWithKeyValuesArray:dictArray];
                    
                    if (self.delegate
                        && [self.delegate respondsToSelector:@selector(didReceiveList:userLoginId:isSuccess:)])
                    {
                        [self.delegate didReceiveList:deviceListArray
                                          userLoginId:respUserId
                                            isSuccess:YES];
                    }
                }
            }
            
        }
        //        [self stopConnect];
    }
    else
    {
        [self stopConnect];
        NSLog(@"请求服务器成功，但获取设备列表数据数据失败！");
        if ([self.Httptype isEqualToString:@"UnBindDevReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didUnBindDevRespResultCode:isSuccess:)])
            {
                [self.delegate didUnBindDevRespResultCode:resultFlag isSuccess:YES];
            }
        }
        
        if ([self.Httptype isEqualToString:@"FindDevBindReq"]) {
            
            int count =[responJsonStr[@"state"] intValue];
            NSString * dev =responJsonStr[@"devId"];
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didFindDevBindRespWithDevId:andState:andResultCode:isSuccess:)])
            {
                [self.delegate didFindDevBindRespWithDevId:dev andState:count andResultCode:resultFlag isSuccess:YES];
            }
        }
        
        if ([self.Httptype isEqualToString:@"SendCheckCodeReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didSendCheckCodeRespisSuccess:)])
            {
                [self.delegate didSendCheckCodeRespisSuccess:NO];
            }
        }
        
        if ([self.Httptype isEqualToString:@"UseCheckCodeChangePwdReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didUseCheckCodeChangePwdReqisSuccess:andresultCode:)])
            {
                [self.delegate didUseCheckCodeChangePwdReqisSuccess:YES andresultCode:resultFlag];
            }
        }
        
        
        if ([self.Httptype isEqualToString:@"changePwd"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didChangPWD:)])
            {
                [self.delegate didChangPWD:NO];
            }
            
        }
        if ([self.Httptype isEqualToString:@"RegisterReq"]) {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didRegisterResp:isSuccess:andresultCode:)])
            {
                [self.delegate didRegisterResp:nil isSuccess:YES andresultCode:resultFlag];
            }
        }
        
        
        if ([self.Httptype isEqualToString:@"login"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didlogin:andMDS:andresultCode:isSuccess:)])
            {
                [self.delegate didlogin:nil andMDS:nil andresultCode:resultFlag isSuccess:YES];
            }
            
        }
        if ([self.Httptype isEqualToString:@"list"]) {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didReceiveList:userLoginId:isSuccess:)])
            {
                [self.delegate didReceiveList:nil
                                  userLoginId:nil
                                    isSuccess:NO];
            }
        }
        
        if ([self.Httptype isEqualToString:@"FindDevBindReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didFindDevBindRespWithDevId:andState:andResultCode:isSuccess:)])
            {
                [self.delegate didFindDevBindRespWithDevId:nil
                                                  andState:-2017
                                             andResultCode:resultFlag
                                                 isSuccess:NO];
            }
        }
        if ([self.Httptype isEqualToString:@"BindDevReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didBindDevRespWithResultCode:isSuccess:)])
            {
                [self.delegate didBindDevRespWithResultCode:resultFlag isSuccess:YES];
            }
        }
        if ([self.Httptype isEqualToString:@"ChangeDevAttrReq"]) {
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(didChangeDevAttrRespResultCode:isSuccess:)])
            {
                [self.delegate didChangeDevAttrRespResultCode:resultFlag isSuccess:YES];
            }
        }
        
        return ;
    }
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    //    NSLog(@"socketDidWriteDataToHost");
    [_socket readDataWithTimeout:-1 tag:0  ];
}


@end
