//
//  NetSDK.m
//  NetSDK
//
//  Created by zhuochuncai on 10/4/17.
//  Copyright © 2017年 Gospell. All rights reserved.
//

#import "NetSDK.h"
#import "NetSDKAPI.h"

//BaseCommand.h
@interface NetSDK(){
    CommandBlock CMDBlocks[128];
    CommandBlock BypassBlock[128];
}
@property long handleFromCBS;
@property long handleFromCMS;
@property long handleFromMPS;
@property long handleFromUPS;

@property NSString *sessionID;
@property CommandBlock bypassResponseBlock;
@property ResultBlock  connResultBlock;
@property ResultBlock  connCMSResultBlock;
@property ResultBlock  connCBSResultBlock;
@property ResultBlock  connMPSResultBlock;
@property ResultBlock  connUPSResultBlock;

@property(nonatomic,copy)CommandBlock  resultCMSCmd;
@property(nonatomic,copy)CommandBlock  resultCBSCmd;
@property(nonatomic,copy)CommandBlock  resultMPSCmd;
@property(nonatomic,copy)CommandBlock  resultUPSCmd;
@property(nonatomic,copy)CommandBlock  resultNewVersion;
@property(nonatomic,copy)CommandBlock  resultCBSPort;

@property(nonatomic,copy)dispatch_queue_t cmdRequestQueue;
@property(nonatomic,copy)CommandBlock loginResultBlock;
@property(nonatomic,assign)BOOL loginedToCBS;

@property(nonatomic,strong)NSData *upsReqData;
@property(nonatomic,strong)NSDictionary *MsgTypeDict;
@property(nonatomic,strong)NSMutableOrderedSet *BypassCmdTypeSet; //设备透传命令集
@property(nonatomic,copy)NSString *criptkey;
@property(nonatomic,strong)NSMutableDictionary *resultBlockDict;
@end

@implementation NetSDK


static NSString * getCBSIP;
static int getCBSPort;

-(NSDictionary*)MsgTypeDict{
    if (!_MsgTypeDict) {
        _MsgTypeDict = @{
                         @"QueryNewerVersionUPSRequest":@"QueryNewerVersionUPSResponse",
                         @"AppHeartRequest":@"AppHeartResponse",
                         @"GetAllAreaInfoRequest":@"GetAllAreaInfoResponse",
                         @"AppGetBSAddressRequest":@"APPGetBSAddressResponse",
                         @"LoginGetCGSAAddressRequest":@"LoginGetCGSAAddressResponse",
                         @"UserRegisterRequest":@"UserRegisterResponse",
                         @"LoginCGSARequest":@"LoginCGSAResponse",
                         @"BypassParamRequest":@"BypassParamResponse",
                         @"BindSmartDeviceRequest":@"BindSmartDeviceResponse",
                         @"UnbindSmartDeviceRequest":@"UnbindSmartDeviceResponse",
                         @"ModifyDeviceAttrRequest":@"ModifyDeviceAttrResponse",
                         @"GetUserDeviceListRequest":@"GetUserDeviceListResponse",
                         @"QueryDeviceBindRequest":@"QueryDeviceBindResponse",
                         @"CheckDeviceRegisterRequest":@"CheckDeviceRegisterResponse",
                         @"ModifyUserPasswordRequest":@"ModifyUserPasswordResponse",
                         @"GetVerifyCodeRequest":@"GetVerifyCodeResponse",
                         @"ModifyPasswordByVerifyRequest":@"ModifyPasswordByVerifyResponse"
                         };
    }
    return _MsgTypeDict;
}

- (int)getCMDBlockIndexWithMsgType:(NSString*)msgType{
    int index = -1;

    NSArray *tempArray = [[self.MsgTypeDict allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString*  _Nonnull obj1, NSString*  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    
    for (int i =0; i< tempArray.count; i++) {
        if ([tempArray[i] isEqualToString:msgType] ||[self.MsgTypeDict[tempArray[i]] isEqualToString:msgType] ) {
            index = i;
            break;
        }
    }
    return index;
}


- (long)net_init{
    NSString *mFilePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingString:@"/log.txt"];
    return Net_Init(mFilePath.UTF8String);
}

- (long)net_unInit{
    return Net_UnInit();
}

/**
 修改登录逻辑，登录完成后再去建立CGSA的长连接,然后用sessionID发送心跳
 */
- (void)net_loginWithIP:(NSString*)ip port:(int)port userName:(NSString*)userName password:(NSString*)pwd timeout:(int)timeout result:(CommandBlock)resultBlock{

    NSDictionary *dict = @{@"MessageType":@"LoginCGSARequest", @"Body":@{@"UserName":userName, @"Password":pwd}};

    __weak typeof(self) weakSelf = self;
    NSData *reqData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    [self net_sendSyncRequestWithIP:ip port:port data:reqData timeout:timeout responseBlock:^(int result, NSDictionary *dict) {
        if (resultBlock) {
            resultBlock(result,dict);
        }
        if (result == 0 && [dict[@"MessageType"]isEqualToString:@"LoginCGSAResponse"]) {
            weakSelf.sessionID = dict[@"Body"][@"SessionId"];
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [weakSelf net_connectToCBSWithAddress:ip nport:port resultBlock:^(int result) {
                if (result==0) {
                    NSDictionary *dict = @{@"MessageType":@"AppHeartRequest",@"Body":@{@"SessionId":strongSelf.sessionID}};
                    NSData *reqData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
                    //开启心跳
                    Net_S_StartHeartBeat(strongSelf.handleFromCBS, (const char *)reqData.bytes, (int)reqData.length);
                }
            }];
        }
    }];
}

- (long)net_connectToCBSWithAddress:(NSString*)address nport:(int)port resultBlock:(ResultBlock)result{
    _connCBSResultBlock = result;
    //长连接
    _handleFromCBS = Net_S_Connect([address UTF8String], port, 0, EventCallBackOC, 0,1);
    //加密
    if (self.criptkey) {
        NSData *scriptData = [self.criptkey dataUsingEncoding:NSUTF8StringEncoding];
        unsigned char *pkey = (unsigned char *)scriptData.bytes;
        int length = (int)scriptData.length;
        Net_S_SetKey(_handleFromCBS, pkey, length);
    }
    return _handleFromCBS;
}

- (long)net_connectToCMSWithAddress:(NSString*)address nport:(int)port resultBlock:(ResultBlock)result{
    _connCMSResultBlock = result;
    _handleFromCMS = Net_S_Connect([address UTF8String], port, 0, EventCallBackOC, 0,0);
    //加密
    if (self.criptkey) {
        NSData *scriptData = [self.criptkey dataUsingEncoding:NSUTF8StringEncoding];
        unsigned char *pkey = (unsigned char *)scriptData.bytes;
        int length = (int)scriptData.length;
        Net_S_SetKey(_handleFromCMS, pkey, length);
    }
    return _handleFromCMS;
}


- (long)net_connectToMPSWithAddress:(NSString*)address nport:(int)port resultBlock:(ResultBlock)result{
    _connMPSResultBlock = result;
    _handleFromMPS = Net_S_Connect([address UTF8String], port, 0, EventCallBackOC, 0,0);
    //加密
    if (self.criptkey) {
        NSData *scriptData = [self.criptkey dataUsingEncoding:NSUTF8StringEncoding];
        unsigned char *pkey = (unsigned char *)scriptData.bytes;
        int length = (int)scriptData.length;
        Net_S_SetKey(_handleFromMPS, pkey, length);
    }
    return _handleFromMPS;
}

- (long)net_closeCBSConnect{
    long result = [self net_closeConnectWithHandle:(int)_handleFromCBS];
    _handleFromCBS = -1;
    return result;
}

- (long)net_closeMPSConnect{
    long result = [self net_closeConnectWithHandle:(int)_handleFromMPS];
    _handleFromMPS = -1;
    return result;
}

- (long)net_closeConnectWithHandle:(int)lHandle{
    long result = Net_S_Close(lHandle);
    return result;
}

- (BOOL)net_loginedToCBS{
    return self.loginedToCBS;
}

- (long)net_startHeartBeatWithHandle:(long)lHandle data:(NSData*)data{
    return Net_S_StartHeartBeat(_handleFromCBS, (const char*)data.bytes, (int)data.length);
}

- (long)net_stopHeartBeatWithHandle:(long)lHandle{
    return Net_S_StopHeartBeat(_handleFromCBS);
}

- (NSMutableOrderedSet*)BypassCmdTypeSet{
    if (!_BypassCmdTypeSet) {
        _BypassCmdTypeSet = [NSMutableOrderedSet orderedSetWithCapacity:1];
    }
    return _BypassCmdTypeSet;
}

- (void)net_sendLongLinkRequestWithUID:(NSString *)UID requestData:(NSDictionary*)data timeout:(int)timeout responseBlock:(CommandBlock)result{
    NSNumber *cmdType = data[@"CMDType"];
    NSString *cmdTypeStr = [NSString stringWithFormat:@"%d",cmdType.intValue];
    [self.resultBlockDict setObject:result forKey:cmdTypeStr];
    NSDictionary *dict = [self requestCmdDataWithUID:UID sessionID:_sessionID paramData:data];
    NSData *reqData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    char* pSendData = [self getMallocDataWithData:reqData];
    [self net_sendCmdWithData:pSendData length:(int)reqData.length handle:(int)_handleFromCBS timeout:timeout];
}


- (void)net_sendBypassRequestWithUID:(NSString *)UID requestData:(NSDictionary*)data timeout:(int)timeout responseBlock:(CommandBlock)result{
    
    NSDictionary *dict = [self requestCmdDataWithUID:UID sessionID:_sessionID paramData:data];
    NSLog(@"\n net_sendBypassRequestWithUID__________________:%@",dict);
    
    NSError *error;

    NSData *reqData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (error) {
        NSLog(@"___________________________________ToJsonError:%@",error.description);
    }
    
    [self net_sendSyncRequestWithIP:getCBSIP port:getCBSPort data:reqData timeout:timeout responseBlock:^(int resultRet, NSDictionary *dict) {
        if (result) {
            result(resultRet,dict);
        }
    }];
}

- (char*)getMallocDataWithData:(NSData*)data{
    char* pSendData = NULL;
    int len = (int)data.length;
    if (len > 0) {
        pSendData = (char*)malloc(len);
        memcpy(pSendData,data.bytes,len);
    }
    return pSendData;
}

- (void)net_sendCBSRequestMsgType:(NSString*)type bodyData:(NSMutableDictionary*)data timeout:(int)timeout responseBlock:(CommandBlock)result{

    NSDictionary *cmdData = nil;

    if (_sessionID.length >0 ) {
        [data setObject:_sessionID forKey:@"SessionId"];
    }
    cmdData = @{@"MessageType":type, @"Body":data};

    NSData *reqData = [NSJSONSerialization dataWithJSONObject:cmdData options:0 error:nil];
    
    [self net_sendSyncRequestWithIP:getCBSIP port:getCBSPort data:reqData timeout:timeout responseBlock:^(int resultRet, NSDictionary *dict) {
        if (result) {
            result(resultRet,dict);
        }
    }];

}

- (void)net_sendCBSRequestWithData:(NSDictionary*)data timeout:(int)timeout responseBlock:(CommandBlock)result{

    if ([data[@"MessageType"]isEqualToString:@"LoginRequest"]) {
        _resultMPSCmd = result;
    }else{
        _resultCBSCmd = result;
    }
    NSMutableDictionary *dict = [data mutableCopy];
    if (_sessionID.length > 0) {
        
        NSMutableDictionary *bodyDict = [dict[@"Body"] mutableCopy];
        if (bodyDict) {
            [bodyDict setObject:_sessionID forKey:@"SessionId"];
            [dict setObject:bodyDict forKey:@"Body"];
        }
    }

    NSData *reqData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];

    
    [self net_sendSyncRequestWithIP:getCBSIP port:getCBSPort data:reqData timeout:timeout responseBlock:^(int resultRet, NSDictionary *dict) {
        if (result) {
            result(resultRet,dict);
        }
    }];
}

- (void)net_sendCMSRequestWithData:(NSDictionary*)data timeout:(int)timeout responseBlock:(CommandBlock)result{
    _resultCMSCmd = result;
    NSData *reqData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    char* pSendData = [self getMallocDataWithData:reqData];
    [self net_sendCmdWithData:pSendData length:(int)reqData.length handle:(int)_handleFromCMS timeout:timeout];
}


- (void)net_sendSyncRequestWithIP:(NSString*)ip port:(int)port data:(NSData*)data timeout:(int)millisecond responseBlock:(CommandBlock)resultBlock {
    char* pSendData = [self getMallocDataWithData:data];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        char *pRltbuf = NULL;
        int retDataLength = sizeof(pRltbuf);
        unsigned char *pkey;
        int length;
        if (self.criptkey) {
            NSData *scriptData = [self.criptkey dataUsingEncoding:NSUTF8StringEncoding];
            pkey = (unsigned char *)scriptData.bytes;
            length = (int)scriptData.length;
        }
        else{
            pkey = NULL;
            length = 0;
        }
      long ret = Net_S_BlockRequest(ip.UTF8String, port, pSendData, (int)data.length,millisecond, &pRltbuf,&retDataLength, pkey, (int)self.criptkey.length);
        //(const char*)data.bytes
//        long ret = Net_S_BlockRequest(ip.UTF8String, port, pSendData, (int)data.length,millisecond, &pRltbuf,&retDataLength);

        free(pSendData);
        if(ret == 0){
            NSDictionary *dict = [self net_getResponseDataWithBuffer:pRltbuf length:retDataLength];
            [self processResponseCmdDataWithData:dict eNetSDKErr:ret resultBlock:^(int result, NSDictionary *dict) {
                resultBlock(result, result==0?dict:nil);
            }];
        }else{
            resultBlock(ret,nil);
        }
        Net_S_BlockRequestFree(pRltbuf);
    });
}


//不需要加密接口
- (void)net_sendNoCriptSyncRequestWithIP:(NSString*)ip port:(int)port data:(NSData*)data timeout:(int)millisecond responseBlock:(CommandBlock)resultBlock {
    char* pSendData = [self getMallocDataWithData:data];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        char *pRltbuf = NULL;
        int retDataLength = sizeof(pRltbuf);
        long ret = Net_S_BlockRequest(ip.UTF8String, port, pSendData, (int)data.length,millisecond, &pRltbuf,&retDataLength, NULL, 0);
        free(pSendData);
        if(ret == 0){
            NSDictionary *dict = [self net_getResponseDataWithBuffer:pRltbuf length:retDataLength];
            [self processResponseCmdDataWithData:dict eNetSDKErr:ret resultBlock:^(int result, NSDictionary *dict) {
                if (resultBlock) {
                    resultBlock(result, result==0?dict:nil);
                }
            }];
        }else{
            resultBlock(ret,nil);
        }
        Net_S_BlockRequestFree(pRltbuf);
    });
}


- (void)net_queryDeviceVersionWithIP:(NSString*)ip port:(int)port data:(NSData*)data responseBlock:(CommandBlock)result{
    
    _resultUPSCmd = result;
    [self net_sendNoCriptSyncRequestWithIP:ip port:port data:data timeout:8000 responseBlock:^(int resultRet, NSDictionary *dict) {
        if (result) {
            result(resultRet,dict);
        }
    }];
}

//获取APP版本信息
- (void)net_queryAPPVersionWithIP:(NSString*)ip port:(int)port data:(NSDictionary *)dataDict responseBlock:(CommandBlock)result{
    
    NSMutableDictionary *dict = [dataDict mutableCopy];
    if (_sessionID.length > 0) {
        NSMutableDictionary *bodyDict = [dict[@"Body"] mutableCopy];
        if (bodyDict) {
            [bodyDict setObject:_sessionID forKey:@"SessionId"];
            [dict setObject:bodyDict forKey:@"Body"];
        }
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];

    _resultNewVersion = result;
    [self net_sendNoCriptSyncRequestWithIP:ip port:port data:data timeout:8000 responseBlock:^(int resultRet, NSDictionary *dict) {
        if (result) {
            result(resultRet,dict);
        }
    }];
}

/**
 获取CBSPort端口
 */
- (void)net_getCBSPortWithIP:(NSString*)ip port:(int)port data:(NSDictionary *)dataDict responseBlock:(CommandBlock)result{
    _resultCMSCmd = result;
    
    //置空加密key
    [self setcriptKey:@""];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict options:0 error:nil];
    [self net_sendSyncRequestWithIP:ip port:port data:data timeout:10000 responseBlock:^(int resultRet, NSDictionary *dict) {
        if (result) {
            result(resultRet,dict);
        }
    }];
}


- (void)net_sendCmdWithData:(const void *)pData length:(int)len handle:(int)handle timeout:(int)timeout{
    dispatch_async(self.cmdRequestQueue, ^{
        int nerror;
        long  i = Net_S_Exe_Cmd(handle, (const char*)pData, len ,0, timeout, &nerror,NULL,NULL);
        
        if(pData != NULL)
        {
            free((char*)pData);
        }
//        if (nerror == 0) {
//            
//        }
//        else if(nerror == NetSDKErr_LostConn){
//            //设备掉线
//            NSLog(@"设备掉线");
//        }
//        else if (nerror == NetSDKErr_NoSupport_BlockMode){
//            //不支持阻塞调用
//            NSLog(@"不支持阻塞调用");
//        }
//        else if (nerror == NetSDKErr_NoSupport_Req){
//            //SDK不支持该命令,请联系SDK负责人员进行添加支持
//            NSLog(@"SDK不支持该命令,请联系SDK负责人员进行添加支持");
//        }0->成功 ,-1 -> 失败,
        if (i==0) {
            NSLog(@"发送指令成功");
        }
        else if(i==-1){
            NSLog(@"发送指令失败");
        }
//        Net_S_Send(handle,(const char*) pData, len);
    });
}


static NetSDK *instance =nil;

+(id)sharedInstance{
    if (!instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = [[[self class] alloc] init];
            instance.handleFromCBS = -1;
            instance.handleFromUPS = -1;
            [instance net_init];
            getCBSIP = [[NSUserDefaults standardUserDefaults] objectForKey:@"kCBS_IP"];
            getCBSPort = [[[NSUserDefaults standardUserDefaults] objectForKey:@"CBS_PORT"] intValue];
            instance.resultBlockDict = [NSMutableDictionary dictionary];
        });
    }
    return instance;
}


-(dispatch_queue_t)cmdRequestQueue{
    if (!_cmdRequestQueue) {
        _cmdRequestQueue = dispatch_queue_create("cmd.request.serial", DISPATCH_QUEUE_SERIAL);
    }
    return _cmdRequestQueue;
}

#pragma mark - _发数据

-(NSDictionary *)requestCmdDataWithUID:(NSString*)UID sessionID:(NSString*)sessionID paramData:(NSDictionary*)data{
    
    NSDictionary *dict = @{@"MessageType":@"BypassParamRequest", @"Body":@{@"SessionId":sessionID, @"DeviceId":UID, @"DeviceParam":data}};
    return dict;
}




// 事件回调
long EventCallBackOC(long lHandle, eNetSDKEvent eParam, long lRet, void* pData, long dataLen, long lUserParam){
    if (eParam == NETSDK_EVENT_CONN_SUCCESS) {
        [instance processConnResultWithHandle:lHandle result:0];


        NSLog(@"__________________________CONN_SUCCESS");
    }
    else if (eParam == NETSDK_EVENT_CONN_ERR) {
        [instance processConnResultWithHandle:lHandle result:-1];

        NSLog(@"___________________________CONN_ERR");
    }
    else if (eParam == NETSDK_EVENT_GOS_RECV) {

        //请求成功
        [instance processResponseCmdDataWithData:[instance net_getResponseDataWithBuffer:pData length:dataLen] eNetSDKErr:lRet resultBlock:^(int result, NSDictionary *dict) {
            NSLog(@"EventCallBackOC_result:%d data:%@",result,dict);
        }];
    }

    return 0;
}

-(void) processConnResultWithHandle:(long)handle result:(int)result{
    if (handle == _handleFromCBS) {
        if (_connCBSResultBlock) {
            _connCBSResultBlock(result);
            _connCBSResultBlock = nil;
        }
    }else if (handle == _handleFromCMS){
        if (_connCMSResultBlock) {
            _connCMSResultBlock(result);
            _connCMSResultBlock = nil;
        }
    }else if (handle == _handleFromMPS){
        if (_connMPSResultBlock) {
            _connMPSResultBlock(result);
            _connMPSResultBlock = nil;
        }
    }else if (handle == _handleFromUPS){
        if (_connUPSResultBlock) {
            _connUPSResultBlock(result);
            _connUPSResultBlock = nil;
        }
    }
}

#pragma mark - 收数据 回调
-(NSDictionary*)net_getResponseDataWithBuffer:(const void *)pBuf length:(long)len{
    NSData *data = [NSData dataWithBytes:pBuf length:len];
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
}

//lret == eNetSDKErr类型
-(void )processResponseCmdDataWithData:(NSDictionary*)data eNetSDKErr:(long)lret resultBlock:(CommandBlock)resultBlock {
    
    if (!data) return;
    
    NSLog(@"\nRecvData:______________________________________lRet= %ld data=:%@\n",lret,data);
    
    int result = [data[@"ResultCode"] intValue];
    
    
    if (lret != 0) {
        //含错误码，默认作为超时处理 标识符为8888 eNetSDKErr类型
        result = 8888;
    }
    
    if ([data[@"MessageType"]isEqualToString:@"BypassParamResponse"])
    {
        NSDictionary *dict = data[@"Body"][@"DeviceParam"];
        NSNumber *cmdType = dict[@"CMDType"];
        NSString *cmdTypeStr = [NSString stringWithFormat:@"%d",cmdType.intValue -1];
        CommandBlock myCommandBlock = self.resultBlockDict[cmdTypeStr];
        if (myCommandBlock) {
            myCommandBlock(result,dict);
        }
        else{
            if (resultBlock) {
                resultBlock(result,dict);
            }
        }
    }
    else
    {
        if ([data[@"MessageType"]isEqualToString:@"LoginCGSAResponse"]) //LoginCBSResponse
        {
            if (resultBlock) {
                resultBlock(result,data);
            }

        }else if([data[@"MessageType"]isEqualToString:@"AppHeartResponse"]){
            //            _resultCBSCmd(result,data);
        }
        else if([data[@"MessageType"]isEqualToString:@"LoginResponse"]){
            if (_resultMPSCmd) {
                _resultMPSCmd(result,data);
            }
        }
        else if ([self responseFromUPSCMD:data[@"MessageType"]]){
            if (_resultUPSCmd) {
                _resultUPSCmd(result,data[@"Body"]);
            }
        }
        else if([self responseFromCMSCMD:data[@"MessageType"]]){
            if (_resultCMSCmd) {
                _resultCMSCmd(result,data[@"Body"]);
            }
        }
        else if([data[@"MessageType"]isEqualToString:@"NotifyDeviceStatus"]){
            
            [[NSNotificationCenter defaultCenter]postNotificationName:@"NotifyDeviceStatus" object:data];
            //{"Body":{"DeviceStatus":[{"DeviceId":"A9996100NR618DMYH2JZJ8ST111A","Status":1}],"SessionId":"5230"},"MessageType":"NotifyDeviceStatus"}
        }
        else if([data[@"MessageType"] isEqualToString:@"GetAppNewestFromUPSResponse"]){
            if (_resultNewVersion) {
                _resultNewVersion(result,data[@"Body"]);
            }
        }
        else if([data[@"MessageType"] isEqualToString:@"AppGetBSAddressResponse"]){
            if (_resultCBSPort) {
                _resultCBSPort(result,data[@"Body"]);
            }
        }
        else{
            resultBlock(result,data);
        }
    }
}

- (BOOL)responseFromUPSCMD:(NSString*)type{
    if ([type isEqualToString:@"QueryNewerVersionUPSResponse"]) {
        return YES;
    }
    return NO;
}

- (BOOL)responseFromCMSCMD:(NSString*)type{
    if ([type isEqualToString:@"GetAllAreaInfoResponse"]|| [type isEqualToString:@"AppGetBSAddressResponse"] ||[type isEqualToString:@"LoginGetCGSAAddressResponse"]) {
        return YES;
    }
    return NO;
}


- (void)setCBSAddress:(NSString *)address port:(int)port{
    getCBSIP = address;
    getCBSPort = port;
}

/**
 设置加密key，切换CMS地址要置空Key
 */
- (void)setcriptKey:(NSString *)mycriptKey{
    
    if (mycriptKey.length<=0) {
        self.criptkey = nil;
    }
    
    if ([mycriptKey isKindOfClass:[NSString class]] && mycriptKey.length > 0) {
        NSData *data = [mycriptKey dataUsingEncoding:NSUTF8StringEncoding];
         int keyLength = (int)data.length;
        unsigned char *pOutData = (unsigned char *)malloc(keyLength);
        unsigned int length = 0;
        unsigned char *pSrcData = (unsigned char *)data.bytes;
        Net_DecodeData(pSrcData, keyLength, &pOutData, &length);
        
        //短连接加密
        self.criptkey = [NSString stringWithCString:(const char *)pOutData encoding:NSUTF8StringEncoding];
    }
}


/**
 加密
 */
- (NSString *)encodePassword:(NSString *)password{
//    return password;
    if ([password isKindOfClass:[NSString class]] && password.length > 0) {
        NSData *data = [password dataUsingEncoding:NSUTF8StringEncoding];
        int keyLength = (int)data.length;
        unsigned char *pOutData = nullptr;
        unsigned int length = 0;
        unsigned char *pSrcData = (unsigned char *)data.bytes;
        Net_EncodeData(pSrcData, keyLength, &pOutData, &length);
        
        //加密字符串
       return [NSString stringWithCString:(const char *)pOutData encoding:NSUTF8StringEncoding];
    }
    return nil;
}

// 网络检测专用接口
- (void)checkNet:(NSString*)ip port:(int)port data:(NSDictionary *)dataDict responseBlock:(ResultBlock)result {
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict options:0 error:nil];
    
    char* pSendData = [self getMallocDataWithData:data];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        char *pRltbuf = NULL;
        int retDataLength = sizeof(pRltbuf);
        long ret = Net_S_BlockRequest(ip.UTF8String, port, pSendData, (int)data.length,8000, &pRltbuf,&retDataLength, NULL, 0);
        free(pSendData);
        
        if (ret == 0)
            result((int)ret);
        else
            result((int)ret);
        
        Net_S_BlockRequestFree(pRltbuf);
    });
}
@end

