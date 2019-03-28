//
//  NetPro.m
//  NetPro
//
//  Created by zhuochuncai on 9/2/17.
//  Copyright © 2017年 zhuochuncai. All rights reserved.
//

#import "NetPro.h"
#import "NetProSDKAPI.h"
#import "NetProSDKDef.h"
#import "AVIOCTRLDEFs.h"

@implementation NetPro

//流加密存储key
static NSString * const StreamPassWordKey    = @"StreamPassWordKey";

- (long)NetPro_InitWithType:(kNetProType) eType{
    //连接服务器
    long result = NetPro_Init()==NetProErr_Success;
    char *ip = (char *)"35.163.36.236:6001";
    NetPro_SetTransportProType(NETPRO_ENABLE_ALL,ip);
    NSLog(@"___________连接服务器4.0开始");
    return result;
}

// 反初始化
- (long)NetPro_UnInit{
    return NetPro_UnInit()==NetProErr_Success;
}

- (long)NetPro_ConnectP2P:(EventCallBackFunc)callBack{
    return 0;
//    char *ip = (char *)"192.168.20.49";
//   return NetPro_ConnServer(ip, 34780,  0, (EventCallBack)callBack, 0);
}

// 登录（连接设备）
- (long)NetPro_ConnDevWithDevID:(NSString*)pUID
                       username:(NSString*)pUser
                       password:(NSString*)pPwd
                        timeout:(int )nTimeOut
                        connType:(int )connType
                       callback:( EventCallBackFunc )eventCB
                      userParam:(long) lUserParam {
    eNetConnType type;
    if (pUID.length == 15) {
        //4.0设备
        NSString *devStr = [pUID substringWithRange:NSMakeRange(5, 1)];
        int devValue = devStr.intValue;
        if (devValue == 2) {
           type = NETPRO_CONNECT_4_0_P2P;
        }
        else{
            type = NETPRO_CONNECT_4_0_TCP;
        }
    }
    else{
        //TUTK设备
        type = NETPRO_CONNECT_TUTK;
    }
    return NetPro_ConnDev([pUID UTF8String], [pUser UTF8String], [pPwd UTF8String], nTimeOut,0,type, (EventCallBack)eventCB, lUserParam);
}

// 登出 (关闭连接)
- (long)NetPro_CloseDevWithHandle:(long) lConnHandle {
    return NetPro_CloseDev(lConnHandle)==NetProErr_Success;
}

// 打开音视频流(是否同时打开音频、视频流)
- (long)NetPro_OpenStreamWithHandle:(long) lConnHandle
                           deviceId:(NSString *) deviceId
                            channel:(long) nChannel
                         streamType:(kNetStreamType) eType
                            seconds:(long) seconds
                           timeZone:(long) zone
                           callback:(StreamCallBackFunc)streamCB
                          userParam:(long) lUserParam {
    
    //这个是默认密码
    NSString *pswd = @"user";
    
    NSMutableDictionary *passwordDict = [[NSUserDefaults standardUserDefaults] objectForKey:StreamPassWordKey];
    if (passwordDict) {
        //取本地缓存的密码
        if (passwordDict[deviceId]) {
            pswd = passwordDict[deviceId];
        }
    }
    return NetPro_OpenStream(lConnHandle, (int)nChannel, (char *)[pswd UTF8String],(eNetStreamType)eType, seconds,zone, streamCB, lUserParam)==NetProErr_Success;
}

// 关闭音视频流
- (long)NetPro_CloseStreamWithHandle:(long)lConnHandle channel:(int)nChannel streamType:(kNetStreamType) eType{
    
    return NetPro_CloseStream(lConnHandle, nChannel, (eNetStreamType)eType)==NetProErr_Success;
}

// 设置参数   事件回调返回 相同类型的事件  根据事件做对应处理
- (long)NetPro_SetParamWithHandle:(long)lConnHandle channel:(int)nChannel cmdParam:(kNetProParam) param data:( NSData*) lData {
    
    if (param == kNETPRO_EVENT_SET_STREAM) {
        SMsgAVIoctrlSetStreamCtrlReq *cmdCtrlReq = (SMsgAVIoctrlSetStreamCtrlReq*)lData.bytes;
        return NetPro_SetStream(lConnHandle, nChannel, (eNetVideoStreamType)(cmdCtrlReq->quality));
    }
    else if (param == kNETPRO_EVENT_DEL_REC){
        
        SMsgAVIoctrlDelRecordFileReq *cmdCtrlReq = (SMsgAVIoctrlDelRecordFileReq*)lData.bytes;
        return NetPro_DelRec(lConnHandle, nChannel, cmdCtrlReq->filename);
    }
    else return NetPro_SetParam(lConnHandle, nChannel, (eNetProParam)param, (void*)lData.bytes, (int)lData.length);
}

- (long)NetPro_SetSDParamWithHandle:(long)lConnHandle channel:(int)nChannel reqData:(NSData *) reqData{
    return NetPro_SetParam(lConnHandle, nChannel, NETPRO_PARAM_SET_LOCAL_STORE_CFG/*NETPRO_PARAM_GET_DEVCAP*/, (void *)reqData.bytes, (int)reqData.length);
}

- (long)NetPro_StopSDCardDataWithHandle:(long)lConnHandle channel:(int)nChannel reqData:(NSData *) reqData{
    return NetPro_SetParam(lConnHandle, nChannel, NETPRO_PARAM_SET_LOCAL_STORE_STOP/*NETPRO_PARAM_GET_DEVCAP*/, (void *)reqData.bytes, (int)reqData.length);
}

-(long)NetPro_StopDownloadWithHandle:(long)lConnHandle channel:(int)nChannel{
    
    return NetPro_StopDownload(lConnHandle, nChannel);
}

- (long)NetPro_checkSessionConnStateWithHandle:(long)lConnHandle channel:(int)nChannel{
    
    return NetPro_CheckDevConn(lConnHandle);
}

- (long)NetPro_SetCheckConnStateTimeIntervalWithHandle:(long)lConnHandle channel:(int)nChannel interval:(int)milliseconds{
    return NetPro_SetCheckConnTimeinterval(lConnHandle, milliseconds);
}

// 获取参数
- (long)NetPro_GetParamWithHandle:(long)lConnHandle channel:(int)nChannel cmdParam:(kNetProParam) param data:( NSData*) lData {
    return NetPro_GetParam(lConnHandle, nChannel, (eNetProParam)param, (void*)lData.bytes, (int)lData.length) ;
}

// 开始对讲
- (long)NetPro_TalkStartWithHandle:(long)lConnHandle channel:(int)nChannel{
    
    return NetPro_TalkStart(lConnHandle, nChannel);
    
}

// 发送对讲文件
- (long)NetPro_TalkSendWithHandle:(long)lConnHandle channel:(int)nChannel filePath:(NSString*) filePath{
    
    return NetPro_TalkSendFile(lConnHandle, nChannel, [filePath UTF8String],0);
}


// 发送对讲数据
- (long)NetPro_TalkSendWithHandle:(long)lConnHandle channel:(int)nChannel data:(NSData *)data {
    const char *dataBytes = (const char*)data.bytes;
    return NetPro_TalkSend(lConnHandle, nChannel, dataBytes, (DWORD)data.length);
}

// 结束对讲
- (long)NetPro_TalkStopWithHandle:(long)lConnHandle channel:(int)nChannel{
    return NetPro_TalkStop(lConnHandle, nChannel);
    
}

// 录像下载
- (long)NetPro_RecDownloadWithHandle:(long)lConnHandle channel:(int)nChannel localPath:(NSString *)path fileNameInServer:(NSString *)fileName {
    return NetPro_RecDownload(lConnHandle, nChannel, [path UTF8String], (char*)[fileName UTF8String]);
}

//暂停接收音视频数据 nPasueFlag = 1 暂停接收， nPasueFlag = 0 恢复接收
- (long)NetPro_PasueRecvStream:(long)lConnHandle channel:(int)nChannel nPasueFlag:(int)nPasueFlag{
    return NetPro_PasueRecvStream(lConnHandle, nChannel, nPasueFlag);
}



#pragma mark - NVR 相关
#pragma mark -- 获取设备支持的通道数
- (long)NetPro_GetNvrChannelNumWithHandle:(long)lConnHandle
{
    long channelNum = NetPro_GetDevChnNum(lConnHandle);
    return channelNum;
}


#pragma mark -- 创建 NVR 支持的 AV 通道
- (long)NetPro_CreateAVChannelWithHandle:(long)lConnHandle
                              channelNum:(int)channelNum
{
    return NetPro_CreateDevChn(lConnHandle, channelNum);
}


#pragma mark -- 获取 NVR 录像文件列表
/**
 获取 NVR 录像文件列表
 
 @param lConnHandle         设备操作句柄
 *  @param channelMask      查询的频道（0、1、2、3）
 *  @param date             查询的日期（2017-03-17）
 *  @param startTime        查询的起始时间（00:00）
 *  @param endTime          查询的结束时间(23:59)
 */
- (void)NetPro_GetNvrVideoListWithHandle:(long)lConnHandle
                             channelMask:(uint32_t)channelMask
                                typeMask:(uint32_t)typeMask
                                    date:(NSString *)date
                               startTime:(NSString *)startTime
                                 endTime:(NSString *)endTime
{
    if (!date || 0 >= date.length
        || !startTime || 0 >= startTime.length
        || !endTime || 0 >= endTime.length)
    {
        NSLog(@"无法获取 NVR 录像回放列表，channelMask = %d, date = %@ startTime = %@, endTime = %@", channelMask, date, startTime, endTime);
       
        return ;
    }
    GOS_V_SearchFileRequest searchFileParam;
    
    memset(&searchFileParam, 0, sizeof(GOS_V_SearchFileRequest));
    
    searchFileParam.channelMask = channelMask;
    searchFileParam.recordTypeMask = typeMask;
    searchFileParam.startTime = [self parseDateString:date
                                           timeString:startTime];
    searchFileParam.endTime = [self parseDateString:date
                                         timeString:endTime];
    
    NetPro_GetParam(lConnHandle, 0, NETPRO_PARAM_GET_NVR_REC, (void *)&searchFileParam, sizeof(searchFileParam));
}


#pragma mark -- 解析拼接时间串
- (GOS_DateTime)parseDateString:(NSString *)dateString
                     timeString:(NSString *)timeString
{
    GOS_DateTime searchDateTime;
    memset(&searchDateTime, 0, sizeof(searchDateTime));
    
    if (!dateString || 0 >= dateString.length
        || !timeString || 0 >= timeString.length)
    {
        NSLog(@"解析搜索录像时间出错，dateString = %@, timeString = %@", dateString, timeString);
        
        return searchDateTime;
    }
    NSString *searchDateStr = [NSString stringWithFormat:@"%@ %@", dateString, timeString];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSDate *searchDate = [dateFormatter dateFromString:searchDateStr];
    
    [dateFormatter setDateFormat:@"yyyy"];
    NSInteger searchYear = [[dateFormatter stringFromDate:searchDate] integerValue];
    
    [dateFormatter setDateFormat:@"MM"];
    NSInteger searchMonth = [[dateFormatter stringFromDate:searchDate] integerValue];
    
    [dateFormatter setDateFormat:@"dd"];
    NSInteger searchDay = [[dateFormatter stringFromDate:searchDate] integerValue];
    
    [dateFormatter setDateFormat:@"HH"];
    NSInteger searchHour = [[dateFormatter stringFromDate:searchDate] integerValue];
    
    [dateFormatter setDateFormat:@"mm"];
    NSInteger searchMinute = [[dateFormatter stringFromDate:searchDate] integerValue];
    
    searchDateTime.m_year   = (uint32_t)searchYear;
    searchDateTime.m_month  = (uint32_t)searchMonth;
    searchDateTime.m_day    = (uint32_t)searchDay;
    searchDateTime.m_hour   = (uint32_t)searchHour;
    searchDateTime.m_minute = (uint32_t)searchMinute;
    searchDateTime.m_second = 0;
    
    return searchDateTime;
}


#pragma mark -- 创建 NVR 录像回放 av 通道
- (long)NetPro_NvrStreamPlayWithHanle:(long)lConnHandle
                             filePath:(NSString *)filePath
{
    return NetPro_RecStreamPlay(lConnHandle, [filePath cStringUsingEncoding:NSUTF8StringEncoding], (int)filePath.length);
}


#pragma mark -- NVR 录像回放播放控制
- (void)NetPro_CtrlNvrRecordFileWithHandle:(long)lConnHandle
                                 avChannel:(int)avChannel
                              playCtrlType:(kNetRecCtrlType)netRecCtrlType
                                seekSecond:(long)seekSecond
{
    eNetRecCtrlType playCtrlType = NETPRO_RECSTREAM_PAUSE;
    switch (netRecCtrlType)
    {
        case kNETPRO_RECSTREAM_PAUSE:       // 暂停播放
        {
            playCtrlType = NETPRO_RECSTREAM_PAUSE;
        }
            break;
            
        case kNETPRO_RECSTREAM_RESUME:      // 恢复播放
        {
            playCtrlType = NETPRO_RECSTREAM_RESUME;
        }
            break;
            
        case kNETPRO_RECSTREAM_SEEK:        // 定点播放
        {
            playCtrlType = NETPRO_RECSTREAM_SEEK;
        }
            break;
            
        case kNETPRO_RECSTREAM_STOP:        // 停止播放
        {
            playCtrlType = NETPRO_RECSTREAM_STOP;
        }
            break;
            
        default:
        {
            
        }
            break;
    }
    NetPro_RecStreamCtrl(lConnHandle, avChannel, playCtrlType, seekSecond);
}

@end
