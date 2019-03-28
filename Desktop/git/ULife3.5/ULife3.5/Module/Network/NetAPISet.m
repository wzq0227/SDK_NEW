//
//  NetAPISet.m
//  NetProDemo
//
//  Created by zhuochuncai on 15/2/17.
//  Copyright © 2017年 zhuochuncai. All rights reserved.
//

#import "NetAPISet.h"
#import "NetPro.h"
#import <../../../ULife3.5/NetPro/NetProSDK/TUTK/inc/P2PCam/AVIOCTRLDEFs.h>
#import "ClientModel.h"
#import "PlayVideoViewController.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "HWLogManager.h"
#import "DeviceManagement.h"
#import "CloudSDCardViewController.h"

#define AVINDEXDEFAULT -100000
#define CONN_RUNNING      200
#define AUDIO_SPEAKER_CHANNEL 1
#define AUDIO_BUF_SIZE    1024
#define SPEKAK_BUF_SIZE  1024
#define VIDEO_BUF_SIZE    1000000
#define DOWNLOADCHANNAL 3
#define DOWLOADFILE_BUFSIZE 256
#define VIDEO_TIME_OUT 20000

/** NVR 设备队列总数 */
#define NVR_DEV_QUEUE_COUNT 100

/** NVR 命令请求超时时间（单位：秒）*/
#define NVR_CAM_TIMEOUT 5

NSString *const ADDeviceConnectStatusNotification = @"ADDeviceConnectStatusNotification";
NSString *const ADDevicePwdErrorNotification = @"ADDevicePwdErrorNotification";
//播放通知Key
static NSString *const PlayStatusNotification = @"PlayStatusNotification";
/** NVR 设备使用队列 */
static dispatch_queue_t nvrQueueArray[200];
static dispatch_queue_t queueArray[50];
static dispatch_queue_t cmdRequestQueue() {
    static dispatch_queue_t cmdRequestQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cmdRequestQueue =
        dispatch_queue_create("cmdRequestQueue.api.creation", DISPATCH_QUEUE_SERIAL);
    });
    return cmdRequestQueue;
}

//static dispatch_queue_t streamingQueue() {
//    static dispatch_queue_t openStreamingQueue;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        openStreamingQueue =
//        dispatch_queue_create("openStreamingQueue.api.creation", DISPATCH_QUEUE_CONCURRENT);
//    });
//    return openStreamingQueue;
//}


//static dispatch_queue_t closeStreamingQueue() {
//    static dispatch_queue_t closeStreamingQueue;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        closeStreamingQueue =
//        dispatch_queue_create("closeStreamingQueue.api.creation", DISPATCH_QUEUE_CONCURRENT);
//    });
//    return closeStreamingQueue;
//}

//static dispatch_queue_t videoQueue() {
//    static dispatch_queue_t videoQueue;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        videoQueue =
//        dispatch_queue_create("videoQueue.api.creation", DISPATCH_QUEUE_CONCURRENT);
//    });
//    return videoQueue;
//}

#if defined(__arm__) //debug++
typedef unsigned long       DWORD;
#elif defined(__arm64__)
typedef unsigned int      DWORD;
#endif

typedef struct gos_frame_head
{
    unsigned int    nFrameNo;            // 帧号
    unsigned int    nFrameType;            // 帧类型    gos_frame_type_t
    unsigned int    nCodeType;            // 编码类型 gos_codec_type_t
    unsigned int    nFrameRate;            // 视频帧率，音频采样率
    unsigned int    nTimestamp;            // 时间戳
    unsigned short    sWidth;                // 视频宽
    unsigned short    sHeight;            // 视频高
    unsigned int    reserved;            // 预留
    unsigned int    nDataSize;            // data数据长度
    char            data[0];
}gosFrameHead;

typedef struct GOSLightFrameData
{
    int            nLightFlag;        // 是否灯亮标志
    int            reserved[24];
}GOSLightFrameData;

typedef struct
{
    DWORD    nIFrame;    // 1,yes;    2,no
    DWORD    nAVType;    // 1,video;    2,audio
    DWORD    dwSize;        // audio or video data size
    DWORD    gs_frameRate_samplingRate;    // video frame rate or audio samplingRate
    DWORD    lTMStamp;
    DWORD    gs_video_cap;                // video's capability
    DWORD    gs_reserved;
}pFrameInfo;

@interface NetAPISet(){
}

@property (nonatomic, assign)  NSInteger    streamChannel;

@property (strong, nonatomic)  NSString     *test264FilePath;
@property (strong, nonatomic)  NSFileHandle *fileHandle;

@property (nonatomic,strong ) NetPro         *netPro;
@property (nonatomic,strong ) NSLock         *lock;
@property (nonatomic,assign ) long                          mHandle;

@property (nonatomic,assign ) int                           openStreamFailedTimes;
@property (nonatomic,assign ) int                           file_type;
@property (nonatomic,assign ) int                           downloadState;
@property (nonatomic,assign ) int                           stopdownloadState;
@property (nonatomic,assign ) BOOL                          voiceState;
@property (nonatomic,assign ) BOOL                          talkStarted;

@property (nonatomic, strong) NSTimer                       *timer;
@property (nonatomic, strong) NSOperationQueue              *queue;
@property (nonatomic, strong) NSMutableDictionary           *operations;
@property (nonatomic, strong) NSMutableDictionary           *uidHandleMapping;

@property (nonatomic,strong ) NSMutableArray                *videoArray;
@property (nonatomic,strong ) NSMutableArray<ClientModel*>  *uidArray;
@property (nonatomic,strong ) NSMutableArray                *flagArray;

@property (nonatomic,strong ) BlockCommandReqResult           lightSwitchBlock;
@property (nonatomic,strong ) BlockGetVideoData               blockGetVideoData;

@property (nonatomic,strong ) BlockDeviceInfoResult           blockDeviceInfo;
@property (nonatomic,strong ) BlockCommandReqResult         blockResult                    , blockReconnect;
@property (nonatomic,strong ) BlockCommandReqResult           blockSetTalkState;
@property (nonatomic,strong ) BlockSDInfoResult               blockSDInfoReuslt;
@property (nonatomic,strong ) BlockDeviceControlStateResult   blockDevCtrlStateResult;
@property (nonatomic,strong ) BlockDevicePWDReqResult         blockDevicePWDResult;
@property (nonatomic,strong ) BlockVideoStartDownLoad         blockVideoVideoStartDownLoad;//下载录像的请求BLOCK回调
@property (nonatomic,strong ) BlockVideoInfoResult            blockVideoInfoResult;
@property (nonatomic,strong ) BlockOneDayRecFileResult        blockOneDayRecFileResult;
@property (nonatomic,strong ) BlockGetDeviceAbilityResult2    blockGetDeviceAbilityResult2;
@property (nonatomic,strong ) BlockGetDeviceAbilityResult3    blockGetDeviceAbilityResult3;
@property (nonatomic,strong ) BlockGetDeviceAbilityResult     blockGetDeviceAbilityResult;
@property (nonatomic,strong ) BlockTemperatureAlarmStateReult blockTemperatureAlarmStateReult;
@property (nonatomic,strong ) BlockGetTimeParamResult         blockGetTimeParamResult;

@property (nonatomic, copy) NvrRecordListBlock                  nvrRecordListBlock;
@property (nonatomic, copy) NvrRecordPlayCtrlBlock              nvrRecPlayCtrlBlock;


//缓存
@property (nonatomic,strong)NSMutableDictionary *cacheQueueDict;
@property (nonatomic,assign)NSUInteger currentQueueIndex;

// NVR 相关
@property (nonatomic, strong) NSMutableDictionary *cacheNvrQueueDict;
@property (nonatomic, assign) NSUInteger currentNvrQueueIndex;
@property (nonatomic, strong) dispatch_semaphore_t nvrPlaybackSemaphore;

@end


@implementation NetAPISet

static NetAPISet * instance =nil;

+(instancetype)sharedInstance {
    
    static dispatch_once_t onceToken;
    
    if (!instance) {
        dispatch_once(&onceToken, ^{
            instance                  = [[NetAPISet alloc]init];
            instance.netPro           = [[NetPro alloc]init];
            instance.uidArray         = [[NSMutableArray alloc]initWithCapacity:1];
            instance.uidHandleMapping = [[NSMutableDictionary alloc]initWithCapacity:1];
            instance.lock             = [[NSLock alloc]init];
            [instance.netPro NetPro_InitWithType:0];
            [instance.netPro NetPro_ConnectP2P:netProEventCallbackFunc];
            instance.currentQueueIndex = 0;
            instance.cacheQueueDict = [NSMutableDictionary dictionary];
            //初始化五十个队列
            for (int i = 0; i < 50; i++) {
                NSString *queueStr = [NSString stringWithFormat:@"StreamingQueue.api.creation-%d",i];
                const char *queueCString = [queueStr UTF8String];
                queueArray[i] = dispatch_queue_create(queueCString, DISPATCH_QUEUE_SERIAL);
            }
            
            NSData *data;
            
            
            
            instance.currentNvrQueueIndex = 0;
            instance.cacheNvrQueueDict = [NSMutableDictionary dictionary];
            // 初始化 NVR 队列
            for (int i = 0; i < NVR_DEV_QUEUE_COUNT; i++)
            {
                NSString *nvrQueueStr = [NSString stringWithFormat:@"NvrStreamQueue.api.creation-%d",i];
                const char *queueCString = [nvrQueueStr UTF8String];
                nvrQueueArray[i] = dispatch_queue_create(queueCString, DISPATCH_QUEUE_SERIAL);
            }
            instance.nvrPlaybackSemaphore = dispatch_semaphore_create(1);
        });
    }
    return instance;
}


#pragma mark -- 更加 NVR 设备 ID 和 AV 通道号获取队列
- (dispatch_queue_t)getNvrQueueWithNvrID:(NSString *)nvrDevId
                                avCannel:(int)avChannel
{
    if (!nvrDevId || 0 >= nvrDevId.length
        || 0 > avChannel)
    {
        return nvrQueueArray[0];
    }
    @synchronized (self)
    {
        NSString *uidChannelStr = [NSString stringWithFormat:@"%@-%d",nvrDevId,avChannel];
        dispatch_queue_t nvrStreamQueue;
        NSNumber *cacheNvrQueueNumber = self.cacheNvrQueueDict[uidChannelStr];
        
        if ([cacheNvrQueueNumber isKindOfClass:[NSNumber class]])
        {
            int index = cacheNvrQueueNumber.intValue;
            // 存在对应队列
            nvrStreamQueue = nvrQueueArray[index];
        }
        else
        {
            if (self.currentNvrQueueIndex < NVR_DEV_QUEUE_COUNT)
            {
                // 小于100分配一个
                nvrStreamQueue = nvrQueueArray[self.currentNvrQueueIndex];
                NSNumber *tempNumber = [NSNumber numberWithInteger:self.currentNvrQueueIndex];
                [self.cacheNvrQueueDict setObject:tempNumber forKey:uidChannelStr];
            }
            else
            {
                //大于50 取第一个
                nvrStreamQueue = nvrQueueArray[0];
                NSNumber *tempNumber = [NSNumber numberWithInteger:0];
                [self.cacheNvrQueueDict setObject:tempNumber forKey:uidChannelStr];
            }
            self.currentNvrQueueIndex++;
        }
        return nvrStreamQueue;
    }
}

-(NSString*)test264FilePath{
    if (!_test264FilePath) {
        _test264FilePath = [mDocumentPath stringByAppendingPathComponent:@"test.264"];
        bool result = [mFileManager createFileAtPath:_test264FilePath contents:nil attributes:nil];
        NSLog(@"test264FilePath__________create_result:%d",result);
    }
    return _test264FilePath;
}

-(NSString *)getFormatedTimeFromStr:(NSString *)strTime;
{
    NSString *year = [strTime substringToIndex:4];
    NSString *month = [strTime substringWithRange:NSMakeRange(4, 2)];
    NSString *day = [strTime substringWithRange:NSMakeRange(6, 2)];
    
    NSString *time = [strTime substringWithRange:NSMakeRange(8, 2)];
    NSString *minute = [strTime substringWithRange:NSMakeRange(10,2)];
    NSString *seconds = [strTime substringWithRange:NSMakeRange(12,2)];
    NSString *dateTime = [NSString stringWithFormat:@"%@-%@-%@ %@:%@:%@",year,month,day,time,minute,seconds];
    return dateTime;
}

-(NSMutableArray *)downloadFileToFileModel:(NSArray *)listArray;
{
    if (!listArray || listArray.count==0) {
        return nil;
    }
    NSMutableArray *fileArray = [[NSMutableArray alloc]init];
    for (int i=0;i<listArray.count-1;i++)
    {
        NSString *fileStr = listArray[i];
        if (fileStr != nil)
        {
            NSArray *strArray = [fileStr componentsSeparatedByString:@"@"];
            if ([strArray count] > 0)
            {
                if ([strArray[0] length] > 14)
                {
                    NSString *dateStr = [strArray[0] substringWithRange:NSMakeRange(0,14)];
                    NSString *timeStr = [self getFormatedTimeFromStr:dateStr];
                    FileModel *model = [[FileModel alloc]init];
                    model.fileName = strArray[0];
                    model.fileTime = timeStr;
                    model.fileDownLoadState = NO;
                    if (_file_type == 0) {
                        model.fileType = File_mp4;
                        model.fileSizeName =  [NSString stringWithFormat:@"%@ MB",strArray[1]];
                        model.fileSize = [strArray[1] stringByTrimmingCharactersInSet:[NSCharacterSet  whitespaceAndNewlineCharacterSet]];
                    }
                    else
                    {
                        model.fileType = File_img;
                        model.fileSizeName = [NSString stringWithFormat:@"%@ KB",strArray[1]];
                        model.fileSize = strArray[1];
                    }
                    [fileArray addObject:model];
                }
            }
        }
    }
    return fileArray;
}


long  netProEventCallbackFunc(long lHandle,int nDevChn, kNetProParam eParam, long lRet, long lData, long lUserParam){
    
    NSString *uid = [instance getUIDFromDict:instance.uidHandleMapping withHandle:lHandle];
    NSLog(@"___________kNetProParam_____%d ________ret:%ld  lHandle:%ld  uid:%@",eParam, lRet, lHandle, uid);
    
    
    //    if (eParam==kNETPRO_EVENT_CONN_SUCCESS || eParam == kNETPRO_EVENT_CONN_ERR) {
    //        DeviceDataModel *devDataModel = [[DeviceManagement sharedInstance] getDevcieModelWithDeviceId:uid];
    //        if (GosDeviceNVR == devDataModel.DeviceType
    //            && kNETPRO_EVENT_CONN_SUCCESS == eParam)
    //        {
    //            NSLog(@"NVR 连接成功，开始请求支持通道数，deviceId = %@", uid);
    //            [instance.netPro NetPro_GetNvrChannelNumWithHandle:lHandle];
    //        }
    //        else
    //        {
    //            if (instance.isConnecting) {
    //                instance.connectingCount--;
    //                if (instance.connectingCount==0 && [instance.networkDelegate respondsToSelector:@selector(didFinishRefreshingOnlineStatus)]) {
    //                    [instance.networkDelegate didFinishRefreshingOnlineStatus];
    //                }
    //            }
    //            instance.isConnecting = instance.connectingCount!=0;
    //        }
    //    }
    
    if (eParam == kNETPRO_EVENT_CONN_SUCCESS )      // 连接 TUTK 成功
    {
        DeviceDataModel *devDataModel = [[DeviceManagement sharedInstance] getDevcieModelWithDeviceId:uid];
     
        
        NSLog(@"NVR 连接成功，开始请求支持通道数， %ld", [instance.netPro NetPro_GetNvrChannelNumWithHandle:lHandle]);

        if (GosDeviceNVR == devDataModel.DeviceType
            && kNETPRO_EVENT_CONN_SUCCESS == eParam)
        {
            NSLog(@"NVR 连接成功，开始请求支持通道数，deviceId = %@", uid);
            [instance.netPro NetPro_GetNvrChannelNumWithHandle:lHandle];
        }
        else
        {
            if (instance.isConnecting) {
                instance.connectingCount--;
                if (instance.connectingCount==0 && [instance.networkDelegate respondsToSelector:@selector(didFinishRefreshingOnlineStatus)]) {
                    [instance.networkDelegate didFinishRefreshingOnlineStatus];
                }
            }
            instance.isConnecting = instance.connectingCount!=0;
            
            if (instance.blockReconnect) {
                instance.blockReconnect(0,YES,0);
            }
            NSLog(@"AD-Test---------------回调成功");
            [[HWLogManager manager] logMessage:@"AD-Test-回调- 成功---"];
            [[HWLogManager manager] logMessage:uid];
            //设置连接成功
            [instance setClientModel:uid connectState:YES sid:0];
        }
    }else if (eParam == kNETPRO_EVENT_CONN_ERR)     // 连接 TUTK 失败
    {
        if (instance.isConnecting) {
            instance.connectingCount--;
            if (instance.connectingCount==0 && [instance.networkDelegate respondsToSelector:@selector(didFinishRefreshingOnlineStatus)]) {
                [instance.networkDelegate didFinishRefreshingOnlineStatus];
            }
        }
        instance.isConnecting = instance.connectingCount!=0;
        
        
        if (instance.blockReconnect) {
            instance.blockReconnect(-1,NO,0);
        }
        NSLog(@"AD-Test---------------回调失败");
        [[HWLogManager manager] logMessage:@"AD-Test-回调- 失败---"];
        [[HWLogManager manager] logMessage:uid];
        //登出该设备
        [instance.netPro NetPro_CloseDevWithHandle:lHandle];
        
        //设置状态为连接失败 离线状态
        [instance setClientModel:uid connectState:NO sid:-1];
        
        //从uidHanleMap中移除这个handle
        if (uid) {
            [instance.uidHandleMapping removeObjectForKey:uid];
        }
    }
    else if (eParam == kNETPRO_EVENT_OPENSTREAM_RET){
        NSString *uid = [instance getUIDFromDict:instance.uidHandleMapping withHandle:lHandle];
        if (lRet ==0) {
            instance.openStreamFailedTimes = 0;
            if ([instance.sourceDelegage respondsToSelector:@selector(sendDataTypeState:andUID: errno_ret:)]) {
                [instance.sourceDelegage sendDataTypeState:VideoBuffering andUID:uid errno_ret:0];
            }
        }else if(lRet == -1029){
            //摄像头密码不对 --发通知
            
            if (uid) {
                NSDictionary *dict = @{@"uid" : uid
                                       };
                
                [[NSNotificationCenter defaultCenter] postNotificationName:ADDevicePwdErrorNotification object:nil userInfo:dict];
            }
            //            instance.openStreamFailedTimes++;
            //            if (instance.openStreamFailedTimes>3) {
            //                [instance setClientModel:uid connectState:NO sid:-1];
            //            }else{
            ////                [instance.netPro NetPro_OpenStreamWithHandle:lHandle channel:0 callback:netProStreamCallBackFunc  userParam:_streamChannel];
            //            }
        }
    }
    else if (eParam == kNETPRO_EVENT_GET_LIGHTSTATE){ //阳光照明
        if (instance.lightSwitchBlock) {
            instance.lightSwitchBlock(0, lRet, kNETPRO_EVENT_GET_LIGHTSTATE);
        }
    }
    else if (eParam == kNETPRO_EVENT_LOSTCONNECTION){
        NSString *uid = [instance getUIDFromDict:instance.uidHandleMapping withHandle:lHandle];
        //离线也要停止连接
        [instance stopClientConnect:uid];
        [instance setClientModel:uid connectState:NO sid:-1];
        if(instance.blockVideoVideoStartDownLoad){
            instance.blockVideoVideoStartDownLoad(-3,-1,uid);
        }
    }
    else if ( eParam == kNETPRO_EVENT_TALK ){
        //开启或关闭对讲操作结果
        if (lRet !=0) {
            instance.talkStarted = !instance.talkStarted;
        }
        if (instance.blockSetTalkState) {
            instance.blockSetTalkState(0,lRet,kNETPRO_EVENT_TALK);
        }
        
        if ( lRet == kNetProErr_OPENTALKERR || lRet == kNetProErr_TALKERR){
            if ([instance.sourceDelegage respondsToSelector:@selector(sendDataTypeState:andUID: errno_ret:)]) {
                [instance.sourceDelegage sendDataTypeState:SpeakerSendDataFinish andUID:uid errno_ret:-1];
            }
        }
    }
    else if ( eParam == kNETPRO_EVENT_TALK_SENDFILE_SUCCESS ){
        if ([instance.sourceDelegage respondsToSelector:@selector(sendDataTypeState:andUID: errno_ret:)]) {
            [instance.sourceDelegage sendDataTypeState:SpeakerSendDataFinish andUID:uid errno_ret:0];
        }
    }
    else if (eParam == kNETPRO_PARAM_GET_DEVCAP) {
        if (lRet ==101) {
            SMsgAVIoctrlGetDeviceAbility *resp = (SMsgAVIoctrlGetDeviceAbility*)lData;
            if (instance.blockGetDeviceAbilityResult) {
                instance.blockGetDeviceAbilityResult(0,resp);
            }
        }else if (lRet==102){
            DEVICE_ABILITY_INFO1 *resp = (DEVICE_ABILITY_INFO1*)lData;
            if (instance.blockGetDeviceAbilityResult2) {
                instance.blockGetDeviceAbilityResult2( 0,resp);
            }
        }else if(lRet == 103 ){
            DEVICE_ABILITY_INFO2 *resp = (DEVICE_ABILITY_INFO2*)lData;
            if (instance.blockGetDeviceAbilityResult3) {
                instance.blockGetDeviceAbilityResult3( 0,resp);
            }
        }
    }else if (eParam == kNETPRO_PARAM_GET_RECMONTHLIST){
        
        SMsgAVIoctrlGetMonthEventListResp *Resp = (SMsgAVIoctrlGetMonthEventListResp*)lData;
        if (instance.blockVideoInfoResult) {
            if (Resp->result== 0) {
                NSString *list=[NSString stringWithFormat:@"%s",Resp->monthevent_list];
                NSArray * dateArray = [list componentsSeparatedByString:@"|"];
                NSMutableArray *aray = [[NSMutableArray alloc]init];
                for (int i=0;i<dateArray.count-1;i++){
                    NSString *dateStr = [dateArray[i] substringWithRange:NSMakeRange(0,8)];
                    [aray addObject: dateStr];
                }
                instance.blockVideoInfoResult(0,0,aray);
            }
            else{
                instance.blockVideoInfoResult(Resp->result,0,nil);
            }
        }
    }else if (eParam == kNETPRO_PARAM_GET_RECLIST){
        
        SMsgAVIoctrlGetDayEventListResp *Resp = (SMsgAVIoctrlGetDayEventListResp*)lData;
        if (Resp->result == 0) {
            NSString *list=[NSString stringWithFormat:@"%s",Resp->day_file_list];
            if (([list containsString:@".mp4"] &&instance.file_type==1) || ([list containsString:@".jpg"] &&instance.file_type==0)) {
                return 0;
            }
            NSArray * listArray = [list componentsSeparatedByString:@"|"];
            if (instance.blockOneDayRecFileResult){
                NSMutableArray *dataArray = [instance downloadFileToFileModel:listArray];
                instance.blockOneDayRecFileResult(0,Resp->total_num,Resp->curr_no,dataArray);
            }
        }
        else{
            instance.blockOneDayRecFileResult(Resp->result,0,0,nil);
        }
    }
    else if ( eParam == kNETPRO_EVENT_REC_DOWNLOAD_RET){
        
        if (lRet > 0 ) {
            instance.downloadFileSize = lRet;
        }else if(lRet < 0) {
            
            [instance.netPro NetPro_StopDownloadWithHandle:lHandle channel:0];
            int errorCode = 0;
            if (lRet == kNetProErr_DOWNLOADERR) {
                errorCode = (int)lData;
            }else{
                errorCode = -3;
            }
            if (instance.blockVideoVideoStartDownLoad) {
                instance.blockVideoVideoStartDownLoad(errorCode,0,uid);
            }
        }
    }
    else if (eParam == kNETPRO_EVENT_REC_DOWNLOADING){
        if (instance.blockVideoVideoStartDownLoad) {
            instance.blockVideoVideoStartDownLoad(0,lRet*1.0/100,uid);
        }
    }
    else if (eParam == kNETPRO_EVENT_REC_DOWNLOAD_SUCCESS){
        [instance.netPro NetPro_StopDownloadWithHandle:lHandle channel:0];
        if (instance.blockVideoVideoStartDownLoad) {
            instance.blockVideoVideoStartDownLoad(0,2.0,uid);
            instance.blockVideoVideoStartDownLoad = nil;
        }
    }
    else if (eParam == kNETPRO_PARAM_GET_SDINFO){
        SMsgAVIoctrlGetStorageInfoResp *Resp = (SMsgAVIoctrlGetStorageInfoResp*)lData;
        if (instance.blockSDInfoReuslt) {
            instance.blockSDInfoReuslt(Resp->result,Resp->total_size,Resp->used_size,Resp->free_size);
        }
    }else if (eParam == kNETPRO_PARAM_SET_SDFORMAT){
        SMsgAVIoctrlFormatStorageResp *Resp = (SMsgAVIoctrlFormatStorageResp*)lData;
        if (instance.blockResult) {
            instance.blockResult(0,Resp->result,0);
        }//
    }
    else if (eParam == kNETPRO_PARAM_GET_TIMEINFO){
        SMsgAVIoctrlGetTimeParamResp *Resp = (SMsgAVIoctrlGetTimeParamResp*)lData;
        if (instance.blockGetTimeParamResult) {
            instance.blockGetTimeParamResult(0,*(NETTimeParam*)Resp);
        }
    }else if (eParam == kNETPRO_PARAM_GET_STREAMQUALITY){
        if (instance.blockResult) {
            instance.blockResult(0,0,lData);
        }
    }else if (eParam == kNETPRO_PARAM_GET_DEVPWD){
        SMsgAVIoctrlGetDeviceAuthenticationInfoResp *Resp = (SMsgAVIoctrlGetDeviceAuthenticationInfoResp*)lData;
        if (instance.blockDevicePWDResult) {
            instance.blockDevicePWDResult(0,[NSString stringWithUTF8String:Resp->passwd],CmdModel_DEVICEPWD);
        }
    }else if (eParam == kNETPRO_PARAM_GET_TEMPERATURE){
        SMsgAVIoctrlGetTemperatureAlarmParamResp *Resp = (SMsgAVIoctrlGetTemperatureAlarmParamResp*)lData;
        if (instance.blockTemperatureAlarmStateReult) {
            instance.blockTemperatureAlarmStateReult(0,Resp->alarm_enale,Resp->temperature_type,Resp->curr_temperature_value,Resp->max_alarm_value,Resp->min_alarm_value);
        }
    }else if (eParam == kNETPRO_PARAM_GET_DEVINFO){
        SMsgAVIoctrlGetAllParamResq *Resp = (SMsgAVIoctrlGetAllParamResq*)lData;
        if (instance.blockDevCtrlStateResult) {
            instance.blockDevCtrlStateResult(0,Resp->video_mirror_mode,Resp->manual_record_switch,Resp->motion_detect_sensitivity,Resp->pir_detect_switch,Resp->video_quality,Resp->audio_alarm_sensitivity);
        }
        NSString *devId     = [NSString stringWithUTF8String:Resp->device_id];
        NSString *macAddres = [NSString stringWithUTF8String:Resp->macaddr];
        NSString *softVer   = [NSString stringWithUTF8String:Resp->soft_ver];
        NSString *firmVer   = [NSString stringWithUTF8String:Resp->firm_ver];
        NSString *modelNum  = [NSString stringWithUTF8String:Resp->model_num];
        NSString *wifi      = [NSString stringWithUTF8String:Resp->wifi_ssid];
        
        if (instance.blockDeviceInfo) {
            instance.blockDeviceInfo(0,devId,macAddres,softVer,firmVer,modelNum,wifi);
        }
    }else if (eParam == kNETPRO_PARAM_SET_TIMEINFO){
        SMsgAVIoctrlSetTimeParamResp *Resp = (SMsgAVIoctrlSetTimeParamResp*)lData;
        if (instance.blockResult) {
            instance.blockResult(0,Resp->result,cmdModel_SET_TimeParam);
        }
    }else if (eParam == kNETPRO_PARAM_SET_WIFIINFO){
        SMsgAVIoctrlSetWifiResp *Resp = (SMsgAVIoctrlSetWifiResp*)lData;
        if (instance.blockResult) {
            instance.blockResult(0,Resp->result,IOTYPE_USER_IPCAM_SETWIFI_RESP);
        }
    }else if (eParam == kNETPRO_PARAM_SET_TEMPERATURE){
        SMsgAVIoctrlSetTemperatureAlarmParamResp *Resp = (SMsgAVIoctrlSetTemperatureAlarmParamResp*)lData;
        if (instance.blockResult) {
            instance.blockResult(0,Resp->result,cmdModel_SET_TEMPERATUREDATA);
        }
    }else if (eParam == kNETPRO_PARAM_SET_DEVPWD){
        SMsgAVIoctrlSetDeviceAuthenticationInfoResp *Resp = (SMsgAVIoctrlSetDeviceAuthenticationInfoResp*)lData;
        if (instance.blockResult) {
            instance.blockResult(0,Resp->result,CmdModel_DEVICEPWD);
        }
    }
    else if (eParam == kNETPRO_PARAM_SET_REC){
        SMsgAVIoctrlManualRecordResp *Resp = (SMsgAVIoctrlManualRecordResp*)lData;
        if (instance.blockResult) {
            instance.blockResult(Resp->result,0,IOTYPE_USER_IPCAM_SETRECORD_RESP);
        }
    }
    else if (eParam == kNETPRO_PARAM_SET_VIDEOMODE){
        SMsgAVIoctrlSetVideoModeResp *Resp = (SMsgAVIoctrlSetVideoModeResp*)lData;
        if (instance.blockResult) {
            instance.blockResult(0,Resp->result,0);
        }
    }
    else if (eParam == kNETPRO_PARAM_SET_PIRDETECT){
        SMsgAVIoctrlSetPirDetectResp *Resp = (SMsgAVIoctrlSetPirDetectResp*)lData;
        if (instance.blockResult) {
            instance.blockResult(0,Resp->result,0);
        }
    }
    else if (eParam == kNETPRO_PARAM_GET_PIRDETECT) {
        SMsgAVIoctrlGetPirDetectResp *Resp = (SMsgAVIoctrlGetPirDetectResp*)lData;
        if (instance.blockResult) {
            instance.blockResult(0, Resp->pir_switch, 0);
        }
    }
    else if (eParam == kNETPRO_PARAM_SET_MOTIONDETECT){
        SMsgAVIoctrlSetMotionDetectResp *Resp = (SMsgAVIoctrlSetMotionDetectResp*)lData;
        if (instance.blockResult) {
            instance.blockResult(0,Resp->result,0);
        }
    }
    else if (eParam == kNETPRO_EVENT_DEL_REC){
        if (instance.blockResult) {
            instance.blockResult(0,lRet,0);
        }
    }
    else if (eParam == kNETPRO_EVENT_SET_STREAM){
        if (instance.blockResult) {
            instance.blockResult(0,lRet,0);
        }
    }
    else if (eParam == kNETPRO_PARAM_SET_AUDIOALARM){
        if (instance.blockResult) {
            instance.blockResult(0,lRet,0);
        }
    }
    else if (eParam == kNETPRO_PARAM_SET_UPDATE){
        if (instance.blockResult) {
            instance.blockResult(0,lRet,0);
        }
    }
    else if (kNETPRO_EVENT_RET_DEVCHN_NUM == eParam)    // 返回 NVR 支持通道数
    {
        NSLog(@"NVR 支持通道数回调：%ld", lRet);
        NSLog(@" ==== 发送创建 NVR 支持的 AV 通道请求！");
        // 实时流 AV 通道
        long avChannelNum = [instance.netPro NetPro_CreateAVChannelWithHandle:lHandle
                                                                   channelNum:(int)lRet];
        NSString *nvrDevId = [instance getUIDFromDict:instance.uidHandleMapping
                                           withHandle:lHandle];
        NSLog(@"成功创建 NVR 支持的 AV 通道数：%ld，deviceId = %@", avChannelNum, nvrDevId);
        DeviceDataModel *devDataModel = [[DeviceManagement sharedInstance] getDevcieModelWithDeviceId:nvrDevId];
        devDataModel.avChnnelNum = avChannelNum;
        
        if (instance.isConnecting)
        {
            instance.connectingCount--;
            if (0 == instance.connectingCount
                && instance.networkDelegate
                && [instance.networkDelegate respondsToSelector:@selector(didFinishRefreshingOnlineStatus)])
            {
                [instance.networkDelegate didFinishRefreshingOnlineStatus];
            }
        }
        instance.isConnecting = instance.connectingCount!=0;
        
        if (instance.blockReconnect)
        {
            instance.blockReconnect(0, YES, 0);
        }
        NSLog(@"AD-Test---------------回调成功");
        [[HWLogManager manager] logMessage:@"AD-Test-回调- 成功---"];
        [[HWLogManager manager] logMessage:uid];
        //设置连接成功
        [instance setClientModel:uid connectState:YES sid:0];
    }
    else if (kNETPRO_PARAM_GET_NVR_REC == eParam)   // NVR 录像应答
    {
        GOS_V_FileCountInfo *nvrVideoResp = (GOS_V_FileCountInfo *)lData;   // 文件数解析
        NSLog(@"fileTotalCount = %d, getDataTimes = %d. fileNumEachTime = %d, currentTime = %d", nvrVideoResp->size, nvrVideoResp->times, nvrVideoResp->length, nvrVideoResp->curTime);
        if (0 >= nvrVideoResp->size && instance.nvrRecordListBlock)
        {
            instance.nvrRecordListBlock(YES, nil, nil, nil, nil, 0, 0, 0, 0, 0);
        }
        
        GOS_V_FileInfo *nvrVideoFileData = (GOS_V_FileInfo *)(lData + sizeof(GOS_V_FileCountInfo));     // 文件解析
        for (int i = 0; i < nvrVideoResp->length; i++)
        {
            NSString *deviceId  = [NSString stringWithFormat:@"%d", nvrVideoFileData[i].deviceId];
            NSString *fileName  = [NSString stringWithUTF8String:nvrVideoFileData[i].fileName];
            NSString *startTime = getTimeStrWithStruct(nvrVideoFileData[i].startTime);
            NSString *endTime   = getTimeStrWithStruct(nvrVideoFileData[i].endTime);
            uint32_t length     = nvrVideoFileData[i].length;
            uint32_t frames     = nvrVideoFileData[i].frames;
            uint16_t channel    = nvrVideoFileData[i].channel;
            uint16_t recordType = nvrVideoFileData[i].recordType;
            
            if (instance.nvrRecordListBlock)
            {
                instance.nvrRecordListBlock(YES,
                                            deviceId,
                                            fileName,
                                            startTime,
                                            endTime,
                                            length,
                                            frames,
                                            channel,
                                            recordType,
                                            nvrVideoResp->size);
            }
        }
    }
    else if (kNETPRO_PARAM_CTRLT_NVR_REC == eParam)     // 历史流播放控制
    {
        SMsgAVIoctrlPlayRecordResp *Resp = (SMsgAVIoctrlPlayRecordResp *)lData;
        
        unsigned int avIndex = Resp->result;
        
        NVRRecordFilePlayType nvrRecordFilePlayType = NVRRecordFilePlayStart;
        if (AVIOCTRL_RECORD_PLAY_START == Resp->command)            // 开始播放
        {
            nvrRecordFilePlayType = NVRRecordFilePlayStart;
        }
        else if (AVIOCTRL_RECORD_PLAY_PAUSE == Resp->command)       // 暂停播放
        {
            nvrRecordFilePlayType = NVRRecordFilePlayPause;
        }
        else if (AVIOCTRL_RECORD_PLAY_RESUME == Resp->command)      // 恢复播放
        {
            nvrRecordFilePlayType = NVRRecordFilePlayResume;
        }
        else if (AVIOCTRL_RECORD_PLAY_STOP == Resp->command)        // 停止播放
        {
            nvrRecordFilePlayType = NVRRecordFilePlayStop;
        }
        else if (AVIOCTRL_RECORD_PLAY_SEEKTIME == Resp->command)    // 定点播放
        {
            nvrRecordFilePlayType = NVRRecordFilePlaySeek;
        }
        else if (AVIOCTRL_RECORD_PLAY_END == Resp->command)         // 播放结束、播放出错
        {
            nvrRecordFilePlayType = NVRRecordFilePlayEnd;
        }
        
        NSLog(@"NVR 录像回放文件播放操作应答, nvrRecordFilePlayType = %ld", (long)nvrRecordFilePlayType);
        if (instance && instance.nvrRecPlayCtrlBlock)
        {
            instance.nvrRecPlayCtrlBlock(YES, nvrRecordFilePlayType, avIndex);
        }
    }
    //blockResult
    
    return 0;
}

- (void)stopPlayWithUID:(NSString *)UID  streamType:(kNetStreamType)streamType{
    [self net_closeStreamWithHandle:[self handleFromUID:UID] channel:0 streamType:streamType];
}

- (void)net_closeStreamWithHandle:(long)lConnHandle channel:(int)nChannel streamType:(kNetStreamType)streamType{
    NSString *uid = [self getUIDFromDict:_uidHandleMapping withHandle:lConnHandle];
    [[HWLogManager manager] logMessage:@"关流操作- 开始---"];
    NSLog(@"关流操作- 开始---");
    [[HWLogManager manager] logMessage:uid];
    __weak typeof(self) weakSelf = self;
    dispatch_async([self getQueueWithUID:uid], ^{
        if (![self isStreamOpenedWithUID:uid]) {
            [[HWLogManager manager] logMessage:@"关流操作-流未打开return -- uid"];
            [[HWLogManager manager] logMessage:uid];
            return;
        }
        if (![self isDeviceConnectedWithUID:uid]) {
            [[HWLogManager manager] logMessage:@"关流操作-设备未连接return -- uid"];
            [[HWLogManager manager] logMessage:uid];
            return;
        }
        bool result = 0;
        for (int i = 0; i < 3; ++i) {
            result = [weakSelf.netPro NetPro_CloseStreamWithHandle:lConnHandle channel:0 streamType:streamType];
            if (result != 0)
                break;
        }
        
        [[HWLogManager manager] logMessage:@"关流操作-回调return -- uid"];
        [[HWLogManager manager] logMessage:uid];
        if (result) {
            [[HWLogManager manager] logMessage:@"关流操作-关流成功 -- uid"];
            [[HWLogManager manager] logMessage:uid];
            [weakSelf setStreamStateWithUID:uid opened:NO];
            NSLog(@"______________NetPro_CloseStream(close)__________succeeded:%d ___________handle:%ld ______deviceId = %@",result,lConnHandle, uid);
        }
        else{
            [[HWLogManager manager] logMessage:@"关流操作-关流失败 -- uid"];
            [[HWLogManager manager] logMessage:uid];
        }
        
    });
}


- (void)net_openFailCloseStreamWithHandle:(long)lConnHandle channel:(int)nChannel{
    NSString *uid = [self getUIDFromDict:_uidHandleMapping withHandle:lConnHandle];
    [[HWLogManager manager] logMessage:@"开流失败--关流操作- 开始---"];
    [[HWLogManager manager] logMessage:uid];
    
    bool result = [self.netPro NetPro_CloseStreamWithHandle:lConnHandle channel:0 streamType:kNETPRO_STREAM_ALL];
    [[HWLogManager manager] logMessage:@"开流失败--关流操作-回调return -- uid"];
    [[HWLogManager manager] logMessage:uid];
    if (result) {
        [[HWLogManager manager] logMessage:@"开流失败--关流操作-关流成功 -- uid"];
        [[HWLogManager manager] logMessage:uid];
        [self setStreamStateWithUID:uid opened:NO];
        NSLog(@"______________NetPro_CloseStream(openFail)__________succeeded:%d ___________handle:%ld ______deviceId = %@",result,lConnHandle, uid);
    }
    else{
        [[HWLogManager manager] logMessage:@"开流失败--关流操作-关流失败 -- uid"];
        [[HWLogManager manager] logMessage:uid];
    }
}

//添加设备进入uidArray，并连接
- (long )addClient:(NSString *)UID andpassword:(NSString *)password{
    
    //这是个线程安全的函数
    @synchronized (self) {
        if (!UID) {
            return -1;
        }
        
        //正在连接的uid退出
        BOOL isconnecting = [self isDeviceConnectingWithUID:UID];
        if (isconnecting) {
            
            ClientModel *model = [self getClientModelWithUID:UID];
            if (model) {
                NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
                if (model.lastConnectTimeInterval > 0) {
                    if ((currentTime - model.lastConnectTimeInterval) > 10) {
                        
                        [[HWLogManager manager] logMessage:@"连接时候该uid超过10s未回调，重新连接"];
                        [[HWLogManager manager] logMessage:UID];
                        
                        //移除这个handle key
                        [_uidHandleMapping removeObjectForKey:UID];
                        
                        //超过10s没回调的model 直接连接 刷新连接时间
                        model.lastConnectTimeInterval = currentTime;
                    }
                    else{
                        //正在连接
                        return -1;
                    }
                }
                else{
                    //正在连接
                    return -1;
                }
            }
            else{
                //正在连接
                return -1;
            }
            
            
        }
        
        if( ![self uidArrayContainsUId:UID] ){
            ClientModel *model = [ClientModel initClientModelClass:UID andpwd:password andSID:CONN_RUNNING andAvIndex:AVINDEXDEFAULT andSessionID:-1 andConnectState:NO andReconnection:1 andretry_time:2];
            model.isConnecting = YES;
            NSTimeInterval connectTime = [[NSDate date] timeIntervalSince1970];
            model.lastConnectTimeInterval = connectTime;
            [_uidArray addObject:model];
        }
        else{
            ClientModel *model = [self getClientModelWithUID:UID];
            //更新下连接状态
            model.isConnecting = YES;
            NSTimeInterval connectTime = [[NSDate date] timeIntervalSince1970];
            model.lastConnectTimeInterval = connectTime;
        }
        [self.networkDelegate ConnectState:UID stateFlag:NotificationTypeRunning error_ret:1];
        long handle = [self net_connDevWithDevID:UID userName:@"admin" pwd:@"goscam123" timeout:5 connType:1 callback:netProEventCallbackFunc userParam:_streamChannel];
        
        if (handle >=0) {
            //连接成功 获取到handle
            [_netPro NetPro_SetCheckConnStateTimeIntervalWithHandle:handle channel:0 interval:5000];
            [_uidHandleMapping setObject:@(handle) forKey: UID];
        }
        else{
            //连接失败 --这个不用管
            //            [self net_closeDevConnWithUID:UID handle:handle];
        }
        return handle;
        
    }
}

- (ClientModel *)getClientModelWithUID:(NSString *)uid{
    for (ClientModel *model in _uidArray) {
        if ([model.uidStr isEqualToString:uid]) {
            return model;
        }
    }
    return nil;
}

-(long)net_connDevWithDevID:(NSString*)UID userName:(NSString*)userName pwd:(NSString*)pwd timeout:(int)timeout connType:(int)connType callback:(EventCallBackFunc)callback userParam:(int)param{
    __block long result = -1;
    
    result = [_netPro NetPro_ConnDevWithDevID:UID username:userName password:pwd timeout:timeout connType:connType  callback:callback userParam:param];
    
    return result;
}

- (long)handleFromUID:(NSString*)uid{
    if (uid.length>20) {
        uid = [uid substringFromIndex:uid.length-20];
    }
    //    if (uid.length<20) {
    //        return -1;
    //    }
    
    long handle = -1;
    if (![[_uidHandleMapping allKeys]containsObject:uid]) {
        return handle;
    }else{
        return [_uidHandleMapping[uid] longValue];
    }
}

- (NSString*)getUIDFromDict:(NSDictionary*)dict withHandle:(long)handle {
    
    __block NSString* tempUID=0;
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, NSNumber*  _Nonnull obj, BOOL * _Nonnull stop) {
        if ( [obj intValue]==handle)  {
            tempUID= key;
            *stop = YES;
        }
    }];
    return tempUID;
}

- (void)refreshConnectStateWithUID:(NSString *)UID state:(BOOL)State sid:(int)sid
{
    @synchronized(self) {
        for (int i = 0; i < _uidArray.count; i++) {
            if ([_uidArray[i].uidStr isEqualToString:UID]) {
                _uidArray[i].connectState = State;
                _uidArray[i].sid = sid;
                break;
            }
        }
    }
}

- (void)setClientModel:(NSString *)UID connectState:(BOOL)State sid:(int)sid
{
    @synchronized(self) {
        for (int i = 0; i < _uidArray.count; i++) {
            if ([_uidArray[i].uidStr isEqualToString:UID]) {
                _uidArray[i].connectState = State;
                _uidArray[i].sid = sid;
                //将是否正在连接状态改成NO
                _uidArray[i].isConnecting = NO;
                break;
            }
        }
        
        //改成发通知的方式
        int stateInteger = State?NotificationTypeConnected:NotificationTypeDisconnect;
        
        if ([UID isKindOfClass:[NSString class]] && UID) {
            NSNumber *connectNumber = [NSNumber numberWithInt:stateInteger];
            NSDictionary *postDict = @{@"UID" : UID,
                                       @"State" : connectNumber
                                       };
            [[NSNotificationCenter defaultCenter] postNotificationName:ADDeviceConnectStatusNotification object:nil userInfo:postDict];
        }
        
        [self.networkDelegate ConnectState:UID stateFlag:State?NotificationTypeConnected:NotificationTypeDisconnect error_ret:0];
    }
}

- (void)setStreamStateWithUID:(NSString*)uid opened:(BOOL)opened{
    @synchronized(self) {
        for (int i = 0; i < _uidArray.count; i++) {
            if ([_uidArray[i].uidStr isEqualToString:uid]) {
                _uidArray[i].streamOpened = opened;
                break;
            }
        }
    }
}

- (bool)isStreamOpenedWithUID:(NSString*)uid{
    
    @synchronized(self) {
        for (int i = 0; i < _uidArray.count; i++) {
            if ([_uidArray[i].uidStr isEqualToString:uid]) {
                return _uidArray[i].streamOpened;
            }
        }
    }
    return NO;
}

- (bool)isDeviceConnectedWithUID:(NSString*)uid{
    for (int i = 0; i < _uidArray.count; i++) {
        if ([_uidArray[i].uidStr isEqualToString:uid]) {
            return _uidArray[i].connectState;
        }
    }
    return NO;
}

- (bool)isDeviceConnectingWithUID:(NSString*)uid{
    //线程安全函数
    @synchronized (self) {
        for (int i = 0; i < _uidArray.count; i++) {
            if ([_uidArray[i].uidStr isEqualToString:uid]) {
                return _uidArray[i].isConnecting;
            }
        }
        return NO;
    }
}

- (void)stopAllConnect{
    for (int i = 0; i < _uidArray.count; i++) {
        if (_uidArray[i].connectState) {
            [self stopClientConnect:_uidArray[i].uidStr];
        }
    }
}

- (bool)uidArrayContainsUId:(NSString*)uid{
    for (int i=0; i<_uidArray.count; i++) {
        if ([_uidArray[i].uidStr isEqualToString:uid]) {
            return YES;
        }
    }
    return NO;
}

// 对摄像头列表逐个检查其状态
-(void)CheckState{
    
    for (ClientModel *model in _uidArray) {
        
        if (model.sid == CONN_RUNNING) {
            [self.networkDelegate ConnectState:model.uidStr stateFlag:NotificationTypeRunning error_ret:1];
        }else if(model.sid == -1){
            [self.networkDelegate ConnectState:model.uidStr stateFlag:NotificationTypeDisconnect error_ret:1];
        }
        else{
            [self checkSessionConnStateWithUID:model.uidStr];
        }
    }
}

- (void)checkSessionConnStateWithUID:(NSString*)uid{
    
    int result = [_netPro NetPro_checkSessionConnStateWithHandle:[self handleFromUID:uid] channel:0];
    if (result!=0) {
        [self stopClientConnect:uid];
    }
    [self setClientModel:uid connectState:result==0 sid:result==0?0:-1];
}


/**
 *  打开调试日志开关
 *
 *  @param logState YES:打开,NO:关闭
 */

-(void)setOpenDebugLog:(BOOL)logState{
    
}


/**
 *  删除指定的UID
 *
 *  @param UID UID description
 */
-(void)DeleteClient:(NSString *)UID {
    
    [self stopClientConnect:UID];
    for (int i=_uidArray.count-1; i>=0; i--) {
        if([_uidArray[i].uidStr isEqualToString:UID]){
            [_uidArray removeObjectAtIndex:i];
            break;
        }
    }
}

/**
 *  停止某个设备的连接
 *
 *  @param UID 设备UID
 */
-(long)stopClientConnect:(NSString *)UID {
    
    //如果UID为空 return
    if (!UID) {
        [[HWLogManager manager] logMessage:@"停止设备连接- UID不存在return---"];
        return YES;
    }
    
    dispatch_async([self getQueueWithUID:UID], ^{
        //未连接成功的设备
        if (![self isDeviceConnectedWithUID:UID]) {
            [[HWLogManager manager] logMessage:@"停止设备连接- 没有连接的设备---"];
            [[HWLogManager manager] logMessage:UID];
            return;
        }
        
        //没有handle设备
        if (![[_uidHandleMapping allKeys]containsObject:UID]) {
            [[HWLogManager manager] logMessage:@"停止设备连接- 没有Handle的设备---"];
            [[HWLogManager manager] logMessage:UID];
            return;
        }
        NSInteger oldHandle = [self handleFromUID:UID];
        
        //关闭流
        [self net_closeStreamWithHandle:oldHandle channel:0 streamType:kNETPRO_STREAM_ALL];
        
        [[HWLogManager manager] logMessage:@"停止设备连接- 关闭流---"];
        [[HWLogManager manager] logMessage:UID];
        
        //关闭设备连接
        [self net_closeDevConnWithUID:UID handle:oldHandle];
        [[HWLogManager manager] logMessage:@"停止设备连接- 关闭设备连接---"];
        [[HWLogManager manager] logMessage:UID];
    });
    
    
    return true;
}

-(long)ReconnectAndCloseOldStreamLaterWithUID:(NSString *)uid resultBlock:(BlockCommandReqResult)resultBlock{
    
    if (![self isDeviceConnectedWithUID:uid]) {
        return YES;
    }
    
    _blockReconnect = resultBlock;
    NSInteger oldHandle = -1;
    oldHandle = [self handleFromUID:uid];
    [self net_closeStreamWithHandle:oldHandle channel:0 streamType:kNETPRO_STREAM_ALL];
    [self net_closeDevConnWithUID:uid handle: oldHandle];
    
    //是否正在连接
    //    BOOL isConnecting = [self isDeviceConnectingWithUID:uid];
    
    //重新连接
    [self addClient:uid andpassword:[self getPasswordWithUID:uid]];
    
    //    if (!isConnecting) {
    //        [self addClient:uid andpassword:[self getPasswordWithUID:uid]];
    //    }
    //    else{
    //        //重连失败
    //        _blockReconnect(-1,0,0);
    //    }
    
    
    return YES;
}

- (BOOL)net_closeDevConnWithUID:(NSString*)uid handle:(long)handle{
    
    if (![self isDeviceConnectedWithUID:uid]) {
        return YES;
    }
    if (![[_uidHandleMapping allKeys]containsObject:uid]) {
        return YES;
    }
    
    bool result = [_netPro NetPro_CloseDevWithHandle:handle];
    if (result) {
        [self refreshConnectStateWithUID:uid state:NO sid:-1];
        [_uidHandleMapping removeObjectForKey:uid];
        NSLog(@"AD--------登出设备成功----------");
    }
    else{
        NSLog(@"AD--------登出设备失败----------");
    }
    
    //    NSLog(@"NetPro_CloseDev_______________________________________________________result:%d",result);
    return result;
}

- (void)stopConnect{
    for (ClientModel *model in _uidArray) {
        [self stopClientConnect:model.uidStr];
    }
}

- (void)reconnect:(NSString *)uid andBlock:(BlockCommandReqResult)result {
    //uid不存在return
    if (!uid) {
        [[HWLogManager manager] logMessage:@"重连操作- uid不存在return---"];
        return;
    }
    
    _blockResult = result;
    dispatch_async([self getQueueWithUID:uid], ^{
        //要保证从上而下执行
        [[HWLogManager manager] logMessage:@"重连操作- 开始---"];
        [[HWLogManager manager] logMessage:uid];
        NSLog(@"reconnect_________________________________________________________uid:%@",uid);
        //        if([self stopClientConnect:uid]){
        //            [[HWLogManager manager] logMessage:@"重连操作- 停止设备连接成功---"];
        //            [[HWLogManager manager] logMessage:uid];
        //            _blockReconnect = result;
        //            [self addClient:uid andpassword:[self getPasswordWithUID:uid]];
        //        }else{
        //            [[HWLogManager manager] logMessage:@"重连操作- 停止设备连接失败---"];
        //            [[HWLogManager manager] logMessage:uid];
        //            NSLog(@"stopClientConnect_________________________________________failed________________");
        //            _blockReconnect = result;
        //            [self addClient:uid andpassword:[self getPasswordWithUID:uid]];
        //        }
        
        //未连接成功的设备
        BOOL isConnected = [self isDeviceConnectedWithUID:uid];
        BOOL ishasHandle = [[_uidHandleMapping allKeys]containsObject:uid];
        BOOL isStreamOpen = [self isStreamOpenedWithUID:uid];
        if (!isConnected) {
            [[HWLogManager manager] logMessage:@"重连停止设备连接- 没有连接的设备---"];
            [[HWLogManager manager] logMessage:uid];
        }
        
        //没有handle设备
        if (!ishasHandle) {
            [[HWLogManager manager] logMessage:@"重连停止设备连接- 没有Handle的设备---"];
            [[HWLogManager manager] logMessage:uid];
        }
        
        if (!isStreamOpen) {
            [[HWLogManager manager] logMessage:@"重连停止设备连接- 没有openStream的设备---"];
            [[HWLogManager manager] logMessage:uid];
        }
        
        
        if (isConnected && ishasHandle && isStreamOpen) {
            NSInteger oldHandle = [self handleFromUID:uid];
            [[HWLogManager manager] logMessage:@"重连停止设备连接- 关闭流---"];
            [[HWLogManager manager] logMessage:uid];
            
            //关闭流
            bool result = [self.netPro NetPro_CloseStreamWithHandle:oldHandle channel:0 streamType:kNETPRO_STREAM_ALL];
            [[HWLogManager manager] logMessage:@"重连关流操作-回调return -- uid"];
            [[HWLogManager manager] logMessage:uid];
            if (result) {
                [[HWLogManager manager] logMessage:@"重连关流操作-关流成功 -- uid"];
                [[HWLogManager manager] logMessage:uid];
                [self setStreamStateWithUID:uid opened:NO];
                NSLog(@"______________NetPro_CloseStream(reconnect)__________succeeded:%d ___________handle:%ld ______deviceId = %@",result,oldHandle, uid);
            }
            else{
                [[HWLogManager manager] logMessage:@"重连关流操作-关流失败 -- uid"];
                [[HWLogManager manager] logMessage:uid];
            }
        }
        
        
        //不管关流有没有成功，这里都设置流关闭 -- 因为会重新更换句柄
        [self setStreamStateWithUID:uid opened:NO];
        
        if (isConnected && ishasHandle) {
            NSInteger oldHandle = [self handleFromUID:uid];
            //关闭设备连接
            [self net_closeDevConnWithUID:uid handle:oldHandle];
            [[HWLogManager manager] logMessage:@"重连停止设备连接- 关闭设备连接---"];
            [[HWLogManager manager] logMessage:uid];
        }
        
        [[HWLogManager manager] logMessage:@"重连停止设备连接- 重新连接TUTK--"];
        [[HWLogManager manager] logMessage:uid];
        //重新连接
        [self addClient:uid andpassword:[self getPasswordWithUID:uid]];
        
    });
}

- (NSString*)getPasswordWithUID:(NSString*)uid{
    NSString *pwd;
    for (ClientModel *model in _uidArray) {
        if ([model.uidStr isEqualToString:uid]) {
            return model.password;
        }
    }
    return pwd;
}

-(BOOL)startSendVideoData:(NSString *)UID andBlock:(BlockCommandReqResult)resultBlock{
    if (![self isDeviceConnectedWithUID:UID]) {
        resultBlock(-1,0,0);
        return false;
    }else{
        resultBlock(0,0,0);
    }
    time_t seconds = time((time_t *)NULL);
    NSInteger timeOff = [[NSTimeZone systemTimeZone] secondsFromGMT];
    long timeZone = (timeOff/3600)+24;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(cmdRequestQueue(), ^{
        bool result = [weakSelf.netPro NetPro_OpenStreamWithHandle:[weakSelf handleFromUID:UID] deviceId:UID channel:_streamChannel streamType:kNETPRO_STREAM_ALL seconds:seconds timeZone:timeZone callback:netProStreamCallBackFunc  userParam:_streamChannel];
        [weakSelf setStreamStateWithUID:UID opened:result];
        
        if ([weakSelf.sourceDelegage respondsToSelector:@selector(sendDataTypeState:andUID: errno_ret:)]) {
            
            [weakSelf.sourceDelegage sendDataTypeState:result?VideoBuffering:VideoDataTimeout andUID:UID errno_ret:0];
        }
        
        NSLog(@"NetPro__OpenStreamWithHandle___________________________succeeded:%d  _______uid:%@",result,UID);
    });
    return true;
}



-(void)startAudioData:(NSString *)UID andBlock:(BlockCommandReqResult)result{
    
}



-(int)stopAudioData:(NSString *)UID andBlock:(BlockCommandReqResult)result{
    return 0;
}



-(void)stopSendVideoData:(NSString *)UID andBlock:(BlockCommandReqResult)result{
    
    if (![self isStreamOpenedWithUID:UID]) {
        result(0,0,0);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(cmdRequestQueue(), ^{
        bool ret= [weakSelf.netPro NetPro_CloseStreamWithHandle:[weakSelf handleFromUID:UID] channel:0 streamType:kNETPRO_STREAM_ALL];
        [weakSelf setStreamStateWithUID:UID opened:NO];
        result(ret,0,0);
    });
    
}


-(bool)setSpeakState:(BOOL)SpeakState withUID:(NSString*)uid resultBlock:(BlockCommandReqResult)result{
    
//    if( SpeakState == _talkStarted ){
//        return YES;
//    }else{
//        _talkStarted = SpeakState;
//    }
    _blockSetTalkState = result;
    __weak typeof(self) weakself = self;
    dispatch_async([self getQueueWithUID:uid], ^{
        
        if (SpeakState) {
            [weakself.netPro NetPro_TalkStartWithHandle:[self handleFromUID:uid] channel:(int)weakself.streamChannel ];
        }else{
            [weakself.netPro NetPro_TalkStopWithHandle:[self handleFromUID:uid] channel:(int)weakself.streamChannel ];
        }
    });
    return 0;
}

-(void)sendTalkDataWithUID:(NSString*)UID data:(NSData*)data{
    [_netPro NetPro_TalkSendWithHandle:[self handleFromUID:UID] channel:0 data:data];
}

-(void)startSpeakThread:(NSString *)UID andFilePath:(NSString *)filePath{
    [_netPro NetPro_TalkSendWithHandle:[self handleFromUID:UID] channel:0 filePath:filePath];
}

-(void)startAudioFile:(NSString *)UID andFilePath:(NSString *)filePath andBlock:(BlockCommandReqResult)result{
    
}

- (void)setStreamChannel:(int)channel{
    _streamChannel = channel;
}


- (void)startGettingVideoDataWithUID:(NSString*)uid videoType:(int)videoType resultBlock:(BlockGetVideoData)videoDataBlock {
    if (![self isDeviceConnectedWithUID:uid]) {
        videoDataBlock(-1,0);
        return;
    }
    time_t seconds = time((time_t *)NULL);
    NSInteger timeOff = [[NSTimeZone systemTimeZone] secondsFromGMT];
    long timeZone = (timeOff/3600)+24;
    
    _blockGetVideoData = videoDataBlock;
    __weak typeof(self) weakSelf = self;
    dispatch_async([self getQueueWithUID:uid], ^{
        //先检测是否在拉流
        if ([weakSelf isStreamOpenedWithUID:uid]) {
            [[HWLogManager manager] logMessage:@"开流操作前上一次未关流 -- uid"];
            [[HWLogManager manager] logMessage:uid];
            //如果流是打开的 --先关闭
            [weakSelf net_closeStreamWithHandle:[weakSelf handleFromUID:uid] channel:0 streamType:kNETPRO_STREAM_ALL];
            [[HWLogManager manager] logMessage:@"开流操作前上一次未关流 关流回调 -- uid"];
            [[HWLogManager manager] logMessage:uid];
        }
        
        [[HWLogManager manager] logMessage:@"开流操作-开始 -- uid"];
        [[HWLogManager manager] logMessage:uid];
        bool result = [weakSelf.netPro NetPro_OpenStreamWithHandle:[weakSelf handleFromUID:uid] deviceId:uid channel:_streamChannel streamType:videoType seconds:seconds timeZone:timeZone callback:netProStreamCallBackFunc  userParam:_streamChannel];
        [[HWLogManager manager] logMessage:@"开流操作-回调 -- uid"];
        [[HWLogManager manager] logMessage:uid];
        if (result == YES) {
            [[HWLogManager manager] logMessage:@"开流操作-成功 -- uid"];
            [[HWLogManager manager] logMessage:uid];
            //打开流成功
            [weakSelf setStreamStateWithUID:uid opened:result];
            videoDataBlock(0,0);
            NSLog(@"NetPro__OpenStreamWithHandle___________________________succeeded:%d  _______uid:%@",result,uid);
        }
        else{
            [[HWLogManager manager] logMessage:@"开流操作-失败 -- uid"];
            [[HWLogManager manager] logMessage:uid];
            videoDataBlock(-1,0);
            //打开流失败需要关流
            [weakSelf net_openFailCloseStreamWithHandle:[weakSelf handleFromUID:uid] channel:0];
        }
        if ([weakSelf.sourceDelegage respondsToSelector:@selector(sendDataTypeState:andUID: errno_ret:)]) {
            //这里mark一下
            if ([weakSelf.sourceDelegage isKindOfClass:[PlayVideoViewController class]]) {
                __weak PlayVideoViewController *player = (PlayVideoViewController *)weakSelf.sourceDelegage;
                if ([player.deviceId isEqualToString:uid]) {
                    [weakSelf.sourceDelegage sendDataTypeState:result?VideoBuffering:VideoDataTimeout andUID:uid errno_ret:0];
                }else{
                    //关闭流 -- 因为视频不在播放
                    //                        [weakSelf net_closeStreamWithHandle:[weakSelf handleFromUID:uid] channel:0];
                    //                      BOOL result = [weakSelf.netPro NetPro_CloseStreamWithHandle:[weakSelf handleFromUID:uid] channel:0 streamType:kNETPRO_STREAM_ALL];
                    //                        [weakSelf setStreamStateWithUID:uid opened:NO];
                }
            }
        }else{
            //这里关闭流
            if ([weakSelf.sourceDelegage isKindOfClass:[CloudSDCardViewController class]]
                || [weakSelf.sourceDelegage isKindOfClass:NSClassFromString(@"GosTFCardPlayViewController")]
                || [weakSelf.sourceDelegage isKindOfClass:NSClassFromString(@"GosTFCardViewController")]) {
                return;
            }
            [weakSelf net_closeStreamWithHandle:[weakSelf handleFromUID:uid] channel:0 streamType:kNETPRO_STREAM_ALL];
        }
    });
}

- (int)sendSDCardControlWithType:(int)type deviceId:(NSString *)uid sudId:(NSString*)subId startTime:(unsigned int)startTime duration:(int)duration{
    long handle = [self handleFromUID:uid];
    size_t len = sizeof(SMsgAVIoctrlPlayRecordReq);
    void *pCmd = calloc(1, len);
    ((SMsgAVIoctrlPlayRecordReq*)(pCmd))->utctime = startTime;
    ((SMsgAVIoctrlPlayRecordReq*)(pCmd))->type = type;
    ((SMsgAVIoctrlPlayRecordReq*)(pCmd))->duration = duration;
    ((SMsgAVIoctrlPlayRecordReq*)(pCmd))->nChannel = _streamChannel;
    
    if (subId.length > 0) {
        strcpy(((SMsgAVIoctrlPlayRecordReq*)(pCmd))->childID, subId.UTF8String);
    }
    printf("daniel: startTime:%d\n", startTime);

    NSData *data = [NSData dataWithBytes:pCmd length:len];
    int ret = [self.netPro NetPro_SetSDParamWithHandle:handle channel:0 reqData:data];
    free(pCmd);
    pCmd = NULL;
    return ret;
    
}
- (int)sendStopSDCardCammand:(NSString *)uid{
    long handle = [self handleFromUID:uid];
    int ret = [self.netPro NetPro_StopSDCardDataWithHandle:handle channel:0 reqData:nil];
    return ret;
    
}

- (int)pasueRecvStream:(int)nPasueFlag deviceId:(NSString *)uid{
    long handle = [self handleFromUID:uid];
    return [self.netPro NetPro_PasueRecvStream:handle channel:0 nPasueFlag:nPasueFlag];
}



- (dispatch_queue_t)getQueueWithUID:(NSString *)uid{
    
    @synchronized (self) {
        
        if (!uid) {
            return queueArray[0];
        }
        
        dispatch_queue_t streamingQueue;
        NSNumber *cacheQueueNumber = self.cacheQueueDict[uid];
        if ([cacheQueueNumber isKindOfClass:[NSNumber class]]) {
            int index = cacheQueueNumber.intValue;
            //存在对应队列
            streamingQueue = queueArray[index];
        }
        else{
            if (_currentQueueIndex < 50) {
                //小于50分配一个
                streamingQueue = queueArray[_currentQueueIndex];
                NSNumber *tempNumber = [NSNumber numberWithInteger:_currentQueueIndex];
                [self.cacheQueueDict setObject:tempNumber forKey:uid];
            }
            else{
                //大于50 取第一个
                streamingQueue = queueArray[0];
                NSNumber *tempNumber = [NSNumber numberWithInteger:0];
                [self.cacheQueueDict setObject:tempNumber forKey:uid];
            }
            _currentQueueIndex++;
        }
        return streamingQueue;
    }
}

//- (void)net_openStreamWithHandle:(long)handle c
//{
//    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
//    NSData *pFileData = [fileHandle readDataToEndOfFile];
//
//    unsigned char *pOutBuffer;
//    int outLen = 0;
//    NSData *pFileOutData = nil;
//    [_decoder encodePCM2G711AWithSample:8000 channel:1 inputBuf:(unsigned  char *)pFileData.bytes inputLen:(int)pFileData.length outBuf:&pOutBuffer outLen: &outLen];
//
//    NSString *g711FilePath = [NSTemporaryDirectory() stringByAppendingPathComponent: talkFileG711];
//
//    if (pOutBuffer!=NULL) {
//        //        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:g711FilePath];
//        pFileOutData = [NSData dataWithBytes:pOutBuffer length:outLen];
//        bool writeResult = [pFileOutData writeToFile:g711FilePath atomically:YES];
//        if (writeResult) {
//            pFileOutData = nil;
//            free(pOutBuffer);
//        }
//    }
//    [fileHandle closeFile];
//    filePath = g711FilePath;
//}
static NSData *tempData;
static int tempCnt =0;
long netProStreamCallBackFunc(long lHandle, int nDevChn,unsigned char* pStreamData, DWORD dwSize, long lUserParam){
    
    gosFrameHead *info = (gosFrameHead*)pStreamData;
    fflush(stdout);
    printf("daniel: ______________________________________________________2____pBuf:%p\n",pStreamData);
    
    
    //    if (!instance.fileHandle) {
    //        instance.fileHandle = [NSFileHandle fileHandleForWritingAtPath: instance.test264FilePath];
    ////        [instance.fileHandle ];
    //    }else{
    //        tempCnt++;
    //
    //        if (tempCnt<150) {
    //            tempData = [NSData dataWithBytes:pStreamData length:dwSize];
    //            [instance.fileHandle writeData:tempData];
    //        }else{
    //            [instance.fileHandle closeFile];
    //            NSLog(@"file____________full+++++++++++++++++++++++++++++++");
    //        }
    //    }
    
    NSString *uid = [instance getUIDFromDict:instance.uidHandleMapping withHandle:lHandle];
    
    if (info->nFrameType == 100) { //阳光照明特殊帧
        //
    }
    else if(info->nFrameType >=50) {//音频 G711A(=>pcm=>aac)
        if (instance && [instance.sourceDelegage respondsToSelector:@selector(sendAudioData:len:framNo:andUID:frameType:)])
        {
            if (info->nCodeType == gos_audio_G711A) {
                [instance.sourceDelegage sendAudioData:pStreamData len:dwSize framNo:info->nFrameNo andUID:uid frameType:gos_audio_G711A];
            }else{
                [instance.sourceDelegage sendAudioData:pStreamData len:dwSize framNo:info->nFrameNo andUID:uid frameType:gos_audio_AAC];
            }
        }
    }
    else {//视频
        if (instance && [instance.sourceDelegage respondsToSelector:@selector(getVideoData:dataLength:timeStamp:framNo:frameRate:isIFrame:deviceID:avChannel:)])
        {
            if (info->nFrameType == gos_video_rec_start_frame) {
                //这里是SD卡录像音频起始帧
                //类型是20
                NSDictionary *notifyData = @{@"nPort" : [NSNumber numberWithLong:0],
                                             @"eventRec" : [NSNumber numberWithInt:20],
                                             @"lData" : [NSNumber numberWithLong:0],
                                             @"lUserParam" : [NSNumber numberWithLong:0],
                                             @"Decode" : @"",
                                             };
                [[NSNotificationCenter defaultCenter] postNotificationName:PlayStatusNotification object:nil userInfo:notifyData];
            }
            
            [instance.sourceDelegage getVideoData:pStreamData
                                       dataLength:dwSize
                                        timeStamp:info->nTimestamp
                                           framNo:info->nFrameNo
                                        frameRate:info->nFrameRate
                                         isIFrame:info->nFrameType==1
                                         deviceID:uid
                                        avChannel:nDevChn];
        }
    }
    return 0;
}

- (ENUM_PTZCMD)getPTZCMDTypeWithCameraCommand:(int)CameraCommand {
    
    ENUM_PTZCMD ptzCmd;
    if (CameraCommand == Camera_PtzCommand_TURN_TO_LEFT)    //云台向左
    {
        ptzCmd = AVIOCTRL_PTZ_RIGHT;
    }
    else if(CameraCommand == Camera_PtzCommand_TURN_TO_RIGHT)   //云台向右
    {
        ptzCmd = AVIOCTRL_PTZ_LEFT;
    }
    else if(CameraCommand == Camera_PtzCommand_TURN_TO_UP)  //云台向上
    {
        ptzCmd = AVIOCTRL_PTZ_DOWN;
    }
    else if(CameraCommand == Camera_PtzCommand_TURN_TO_DOWN)    //云台向上
    {
        ptzCmd = AVIOCTRL_PTZ_UP;
    }
    else if(CameraCommand == Camera_PtzCommand_TURN_TO_KEEP_LEFT)   //云台连续向左
    {
        ptzCmd = AVIOCTRL_PTZ_KEEP_RIGHT;
    }
    else if(CameraCommand == Camera_PtzCommand_TURN_TO_KEEP_RIGHT)//云台连续向右
    {
        ptzCmd = AVIOCTRL_PTZ_KEEP_LEFT;
    }
    else if(CameraCommand == Camera_PtzCommand_TURN_TO_KEEP_STOP)   // 停止
    {
        ptzCmd =AVIOCTRL_PTZ_STOP;
    }
    else if(CameraCommand == Camera_PtzCommand_TURN_TO_KEEP_DOWN)   //云台连续向下
    {
        ptzCmd = AVIOCTRL_PTZ_KEEP_UP;
    }
    else if(CameraCommand == Camera_PtzCommand_TURN_TO_KEEP_UP) //云台连续向上
    {
        ptzCmd = AVIOCTRL_PTZ_KEEP_DOWN;
    }
    return ptzCmd;
}

-(int)sendCmd:(CmdModelType)cmdModel andParam:(CameraCommandType )type andUID:(NSString *)UID andChannel:(int)channel andBlock:(BlockCommandReqResult)result{
    
    _blockResult = result;
    NSData *data=nil;
    kNetProParam netProCmd;
    int dataSize = 0;
    void *pCmd = [self getCmdReqDataWithCMD:cmdModel dataSize:&dataSize];
    
    if (cmdModel == CmdModel_Camera_PtzCommand_TYPE) {
        
        ((SMsgAVIoctrlPtzCmd*)(pCmd))->control = [self getPTZCMDTypeWithCameraCommand:type];
        netProCmd = kNETPRO_PARAM_PTZ;
    }
    else if (cmdModel == CmdModel_Camera_FORMAT_STORAGE) {
        netProCmd = kNETPRO_PARAM_SET_SDFORMAT;
    }
    else if (cmdModel == CmdModel_Camera_MOVEMONITOR) {
        ((SMsgAVIoctrlSetMotionDetectReq*)(pCmd))->sensitivity = type==0?100:30*(4-type);
        netProCmd = kNETPRO_PARAM_SET_MOTIONDETECT;
    }
    else if(cmdModel == CmdModel_Camera_MANUAL_RECORD){
        ((SMsgAVIoctrlManualRecordReq*)(pCmd))->operate_value = type;
        netProCmd = kNETPRO_PARAM_SET_REC;
    }
    else if (cmdModel == CmdModel_Camera_VIDEOMODE){
        ((SMsgAVIoctrlSetVideoModeReq*)(pCmd))->mode = type-Camera_VIDEOMODE_NORMAL;
        netProCmd = kNETPRO_PARAM_SET_VIDEOMODE;
    }
    else if (cmdModel == CmdModel_Camera_PIR_DETECT_SWITCH){
        ((SMsgAVIoctrlSetPirDetectReq*)(pCmd))->pir_switch = type?5:0;
        netProCmd = kNETPRO_PARAM_SET_PIRDETECT;
        
    }
    else if (cmdModel == CmdModel_Camera_VIDEOQUALITY){
        ((SMsgAVIoctrlSetStreamCtrlReq*)(pCmd))->quality = type==Camera_VIDEOQUALITY_MAX?0:1;
        netProCmd = kNETPRO_EVENT_SET_STREAM;
        NSLog(@"_________________________________setStreamQuality______________________________:%d",type);
    }
    
    data = [NSData dataWithBytes:pCmd length:dataSize];
    
    [self net_setParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:netProCmd data:data];
    free(pCmd);
    pCmd = NULL;
    return 0;
}

-(void *)getCmdReqDataWithCMD:(CmdModelType)cmdModel dataSize:(int *)size {
    
    size_t len =28;
    
    if (cmdModel == CmdModel_Camera_PtzCommand_TYPE) {
        len = sizeof(SMsgAVIoctrlPtzCmd);
        
    }else if (cmdModel == CmdModel_Camera_FORMAT_STORAGE) {
        len = sizeof(SMsgAVIoctrlFormatStorageReq);
        
    }else if (cmdModel == CmdModel_Camera_MOVEMONITOR) {
        len = sizeof(SMsgAVIoctrlSetMotionDetectReq);
        
    }else if(cmdModel == CmdModel_Camera_MANUAL_RECORD){
        len = sizeof(SMsgAVIoctrlManualRecordReq);
        
    }else if (cmdModel == CmdModel_Camera_VIDEOMODE){
        len = sizeof(SMsgAVIoctrlSetVideoModeReq);
        
    }else if (cmdModel == CmdModel_Camera_PIR_DETECT_SWITCH){
        len = sizeof(SMsgAVIoctrlSetPirDetectReq);
        
    }else if (cmdModel == CmdModel_Camera_VIDEOQUALITY){
        len = sizeof(SMsgAVIoctrlSetStreamCtrlReq);
    }
    
    *size = len;
    return calloc(1,len);
}

-(void)setPtzMove:(CmdModelType)cmdModel andParam:(CameraCommandType )CameraCommand andUID:(NSString *)UID andBlock:(BlockCommandReqResult)result{
    
}

- (void)net_setParamWithHandle:(long)handle channel:(int)channel cmdParam:(kNetProParam)cmd data:(NSData*)data{
    dispatch_async(cmdRequestQueue(), ^{
        NSString *uid = [self getUIDFromDict:self.uidHandleMapping withHandle:handle];
        if (!uid) {
            return ;
        }
        [_netPro NetPro_SetParamWithHandle:handle channel:0 cmdParam:cmd data:data];
    });
}

- (void)net_getParamWithHandle:(long)handle channel:(int)channel cmdParam:(kNetProParam)cmd data:(NSData*)data{
    dispatch_async(cmdRequestQueue(), ^{
        NSString *uid = [self getUIDFromDict:self.uidHandleMapping withHandle:handle];
        if (!uid) {
            return ;
        }
        [_netPro NetPro_GetParamWithHandle:handle channel:0 cmdParam:cmd data:data];
    });
}

//- (void)net_openStreamWithHandle:

//设置视频的播放模式
-(void)getVideoQuality:(NSString *)UID andBlock:(BlockCommandReqResult)result{
    
    _blockResult = result;
    [self net_getParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_GET_STREAMQUALITY data:nil];
}

/**
 *  获取设备的详细信息以及对应控制操作状态
 *
 *  @param result   返回控制状态
 *  @param devInfoResult   返回设备的详细信息
 *
 */
-(void)getDeviceAll:(CmdModelType)cmdModel andUID:(NSString *)UID andBlock:(BlockDeviceControlStateResult)result andDevice:(BlockDeviceInfoResult)devInfoResult {
    
    _blockDeviceInfo = devInfoResult;
    _blockDevCtrlStateResult = result;
    
    [self net_getParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_GET_DEVINFO data:nil];
}




-(void)setDevicePassWord:(CmdModelType)cmdModel andPWD:(NSString *)pwd andUID:(NSString *)UID andBlock:(BlockCommandReqResult)result{
    
    _blockResult = result;
    SMsgAVIoctrlSetDeviceAuthenticationInfoReq req;
    memset( &req, 0, sizeof(req));
    strcpy(req.passwd,[pwd UTF8String]);
    
    NSData *data = [NSData dataWithBytes:&req length:sizeof(req)];
    [self net_setParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_SET_DEVPWD data:data];
}


-(void)setTemperatureData:(CmdModelType)cmdModel andalarm_enale:(int )alarm_enale andtemperature_type:(int)temperature_type   andmax_alarm_value:(double)max_alarm_value andmin_alarm_value:(double)min_alarm_value andUID:(NSString *)UID andBlock:(BlockCommandReqResult)result{
    
    _blockResult = result;
    SMsgAVIoctrlSetTemperatureAlarmParamReq req;
    memset( &req, 0, sizeof(req));
    req.alarm_enale = alarm_enale;
    req.temperature_type = temperature_type;
    req.max_alarm_value  = max_alarm_value;
    req.min_alarm_value  = min_alarm_value;
    
    NSData *data = [NSData dataWithBytes:&req length:sizeof(req)];
    [self net_setParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_SET_TEMPERATURE data:data];
    
}




-(void)getDevicePassWord:(CmdModelType)cmdModel andUID:(NSString *)UID andBlock:(BlockDevicePWDReqResult)result{
    
    _blockDevicePWDResult = result;
    [self net_getParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_GET_DEVPWD data:nil];
}

-(void)getDeviceability:(CmdModelType)cmdModel andUID:(NSString *)UID andBlock:(BlockGetDeviceAbilityResult)result andNewBlock:(BlockGetDeviceAbilityResult2)NewResult newerBlock:(BlockGetDeviceAbilityResult3)abilityResultBlock3{
    
    _blockGetDeviceAbilityResult = result;
    _blockGetDeviceAbilityResult2 = NewResult;
    _blockGetDeviceAbilityResult3 = abilityResultBlock3;
    
    [self net_getParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_GET_DEVCAP data:nil];
}

-(void)getEveryDayVideoList:(CmdModelType)cmdModel andParam:(CameraCommandType )CameraCommand andUID:(NSString *)UID andBlock:(BlockVideoInfoResult)result{
    
    _blockVideoInfoResult = result;
    SMsgAVIoctrlGetMonthEventListReq req;
    memset(&req, 0, sizeof(req));
    NSData *data = [NSData dataWithBytes:&req length:sizeof(req)];
    
    [self net_getParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_GET_RECMONTHLIST data:data];
}

-(void)getOneDayVideoFileList:(CmdModelType)cmdModel andParam:(CameraCommandType )CameraCommand andUID:(NSString *)UID withDayVideo:(NSString*)dayvideo withType:(int)type andBlock:(BlockOneDayRecFileResult)result{
    
    _blockOneDayRecFileResult = result;
    _file_type = type;
    
    SMsgAVIoctrlGetDayEventListReq cmdCtrlReq;
    memset( &cmdCtrlReq, 0, sizeof(cmdCtrlReq));
    cmdCtrlReq.file_type= type;
    strcpy(cmdCtrlReq.dayevent_date,[dayvideo UTF8String]);
    
    NSData *data = [NSData dataWithBytes:&cmdCtrlReq length:sizeof(cmdCtrlReq)];
    
    [self net_getParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_GET_RECLIST data:data];
}


/*
 *  请求开始下载录像
 *  @param filename   传入下载的文件名
 *  @param filePath   传入文件路径
 *  @param result     返回结果
 *
 *  @return 0
 */

-(void)StartVideoListFileDownload:(CmdModelType)cmdModel andParam:(CameraCommandType )CameraCommand andUID:(NSString *)UID andFileName:(NSString *)filename andFilePath:(NSString *)filePath andBlock:(BlockVideoStartDownLoad)result{
    
    _blockVideoVideoStartDownLoad = result;
    
    if (UID.length>20) {
        UID = [UID substringFromIndex:UID.length-20];
    }
    if (![[_uidHandleMapping allKeys] containsObject:UID] ) {
        if (_blockVideoVideoStartDownLoad) {
            _blockVideoVideoStartDownLoad(-3,-1,UID);
        }
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        int result =
        [_netPro NetPro_RecDownloadWithHandle:[self handleFromUID:UID] channel:0 localPath:filePath fileNameInServer:filename];
        NSLog(@"NetPro_RecDownloadWithHandle___________result:%d",result);
    });
}

-(long)StopVideoListFileDownload:(CmdModelType)cmdModel andParam:(CameraCommandType )CameraCommand andUID:(NSString *)UID{
    
    self.blockVideoVideoStartDownLoad=nil;
    //SMsgAVIoctrlGetRecordFileStopReq
    return [_netPro NetPro_StopDownloadWithHandle:[self handleFromUID:UID] channel:0];
}

-(void)deleteVideoListFileName:(CmdModelType)cmdModel andParam:(CameraCommandType )CameraCommand andUID:(NSString *)UID withFileName:(NSString *)filename andBlock:(BlockCommandReqResult)result{
    
    _blockResult = result;
    SMsgAVIoctrlDelRecordFileReq cmdCtrlReq;
    memset(&cmdCtrlReq, 0, sizeof(cmdCtrlReq));
    strcpy(cmdCtrlReq.filename, [filename UTF8String]);
    NSData *data = [NSData dataWithBytes:&cmdCtrlReq length:sizeof(cmdCtrlReq)];
    
    [self net_setParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_EVENT_DEL_REC data:data];
}


-(void)getStorageInfoWithUID:(NSString *)UID andBlock:(BlockSDInfoResult)result{
    
    _blockSDInfoReuslt = result;
    [self net_getParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_GET_SDINFO data:nil];
}


-(void)SetWifiReqWithUID:(NSString *)UID andSSID:(NSString *)SSID andPassWord:(NSString *)Password andBlock:(BlockCommandReqResult)result{
    
    _blockResult = result;
    SMsgAVIoctrlSetWifiReq cmdCtrlReq;
    memset(&cmdCtrlReq, 0, sizeof(cmdCtrlReq));
    strcpy(cmdCtrlReq.password, [Password UTF8String]);
    strcpy(cmdCtrlReq.ssid, [SSID UTF8String]);
    
    NSData *data = [NSData dataWithBytes:&cmdCtrlReq length:sizeof(cmdCtrlReq)];
    [self net_setParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_SET_WIFIINFO data:data];
    
}


-(void)getDeviceTemperatureData:(CmdModelType)cmdModel andUID:(NSString *)UID andBlock:(BlockTemperatureAlarmStateReult)result{
    _blockTemperatureAlarmStateReult = result;
    [self net_getParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_GET_TEMPERATURE data:nil];
}


-(void)getDeviceTimeParamData:(CmdModelType)cmdModel andUID:(NSString *)UID andBlock:(BlockGetTimeParamResult)result{
    
    _blockGetTimeParamResult = result;
    [self net_getParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_GET_TIMEINFO data:nil];
}

-(void)setDeviceTimeParamData:(CmdModelType)cmdModel and:(NETTimeParam)req  andUID:(NSString *)UID andBlock:(BlockCommandReqResult)result{
    
    _blockResult = result;
    
    SMsgAVIoctrlSetTimeParamReq cmdCtrlReq;
    memset(&cmdCtrlReq, 0, sizeof(cmdCtrlReq));
    
    cmdCtrlReq.AppTimeSec = req.AppTimeSec;
    cmdCtrlReq.EuroTime=req.EuroTime;
    cmdCtrlReq.NtpOpen=req.NtpOpen;
    cmdCtrlReq.NtpPort=req.NtpPort;
    cmdCtrlReq.NtpRefTime=req.NtpRefTime;
    strcpy(cmdCtrlReq.NtpServer, req.NtpServer);
    cmdCtrlReq.TimeZone=req.TimeZone;
    
    NSData *data = [NSData dataWithBytes:&cmdCtrlReq length:sizeof(cmdCtrlReq)];
    [self net_setParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_SET_TIMEINFO data:data];
}

-(void)setVoiceDetection:(CmdModelType)cmdModel andun_switch:(int)un_switch andUID:(NSString *)UID andBlock:(BlockCommandReqResult)result{
    
    _blockResult = result;
    
    SMsgAVIoctrlSetAudioAlarmReq cmdCtrlReq;
    memset(&cmdCtrlReq, 0, sizeof(cmdCtrlReq));
    cmdCtrlReq.un_switch = un_switch;
    
    NSData *data = [NSData dataWithBytes:&cmdCtrlReq length:sizeof(cmdCtrlReq)];
    [self net_setParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_SET_AUDIOALARM data:data];
}

- (void)updateDeviceWithUID:(NSString*)UID IP:(NSString *)ip Port:(int)port resultBlock:(BlockCommandReqResult)result{
    _blockResult = result;
    
    SMsgAVIoctrlSetUpdateReq cmdCtrlReq;
    memset(&cmdCtrlReq, 0, sizeof(cmdCtrlReq));
    memset(cmdCtrlReq.ip_addr, '\0', sizeof(cmdCtrlReq.ip_addr));
    strcpy(cmdCtrlReq.ip_addr, ip.UTF8String);
    cmdCtrlReq.port = port;
    
    NSData *data = [NSData dataWithBytes:&cmdCtrlReq length:sizeof(cmdCtrlReq)];
    [self net_setParamWithHandle:[self handleFromUID:UID] channel:0 cmdParam:kNETPRO_PARAM_SET_UPDATE data:data];
}


- (void)getLightSwitchStateWithDeviceId:(NSString *)deviceID resultBlock:(BlockCommandReqResult)result{
    _lightSwitchBlock = result;
}


#pragma mark - NVR 相关
#pragma mark -- 获取 nvr 视频流数据
- (void)nvrStartGetVideoDataWithDeviceId:(NSString*)deviceId
                               avChannel:(long)avChannel
                             playViewNum:(long)playViewNum
                    nvrGetVideoDataBlock:(NvrGetVideoDataBlock)nvrGetVideoDataBlock
{
    if (!deviceId || 0 >= deviceId.length
        || 0 > avChannel)
    {
        NSLog(@"=== NetAPISet === 无法获取 nvr 视频流数据， nvrDeviceId = %@, avChannel = %ld", deviceId, avChannel);
        if (nvrGetVideoDataBlock)
        {
            nvrGetVideoDataBlock(NvrGetDataParamError, deviceId, avChannel);
        }
        return;
    }
    if (![self isDeviceConnectedWithUID:20 >= deviceId.length ? deviceId : [deviceId substringFromIndex:8]])
    {
        NSLog(@"=== NetAPISet === NVR 没有连接，无法获取视频流, avChannel = %ld", avChannel);
        if (nvrGetVideoDataBlock)
        {
            nvrGetVideoDataBlock(NvrGetDataConnFailure, deviceId, avChannel);
        }
        return;
    }
    
    if ([self isStreamOpenedWithUID:deviceId])
    {
        //如果流是打开的 --先关闭
        [self net_closeStreamWithHandle:[self handleFromUID:deviceId]
                                channel:(int)avChannel streamType:kNETPRO_STREAM_ALL];
    }
    
    //    time_t seconds    = time((time_t *)NULL);
    NSInteger timeOff = [[NSTimeZone systemTimeZone] secondsFromGMT];
    long timeZone     = (timeOff/3600) + 24;
    
    dispatch_async([self getNvrQueueWithNvrID:deviceId
                                     avCannel:(int)avChannel], ^{
        
        NSLog(@"=== NetAPISet === 发送获取 nvr 视频流数据请求, avChannel = %ld，queue = %@", avChannel, [self getNvrQueueWithNvrID:deviceId
                                                                                                              avCannel:(int)avChannel]);
        long result = [self.netPro NetPro_OpenStreamWithHandle:[self handleFromUID:deviceId]
                                                      deviceId:deviceId
                                                       channel:avChannel
                                                    streamType:kNETPRO_STREAM_VIDEO
                                                       seconds:playViewNum
                                                      timeZone:timeZone
                                                      callback:netProStreamCallBackFunc
                                                     userParam:_streamChannel];
        if (1 == result)
        {
            NSLog(@"=== NetAPISet === 发送获取 nvr 视频流数据请求,成功了, avChannel = %ld", avChannel);
            [self setStreamStateWithUID:deviceId opened:YES];
            if (nvrGetVideoDataBlock)
            {
                nvrGetVideoDataBlock(NvrGetDataSuccess, deviceId, avChannel);
            }
        }
        else
        {
            [self setStreamStateWithUID:deviceId opened:NO];
            NSLog(@"=== NetAPISet === 发送获取 nvr 视频流数据请求,失败了，avChannel = %ld", avChannel);
            if (nvrGetVideoDataBlock)
            {
                nvrGetVideoDataBlock(NvrGetDataFailure, deviceId, avChannel);
            }
        }
    });
}



#pragma mark -- 停止 nvr 视频流数据
- (void)nvrStopGetVideoDataWithDeviceId:(NSString*)deviceId
                              avChannel:(long)avChannel
                  nvrStopVideoDataBlock:(NvrStopVideoDataBlock)nvrStopVideoDataBlock
{
    if (!deviceId || 0 >= deviceId.length
        || 0 > avChannel)
    {
        NSLog(@"=== NetAPISet === 无法停止 nvr 视频流数据， nvrDeviceId = %@, avChannel = %ld", deviceId, avChannel);
        if (nvrStopVideoDataBlock)
        {
            nvrStopVideoDataBlock(NO, deviceId, avChannel);
        }
        return;
    }
    if (![self isDeviceConnectedWithUID:20 >= deviceId.length ? deviceId : [deviceId substringFromIndex:8]])
    {
        NSLog(@"=== NetAPISet === NVR 没有连接，无法停止视频, avChannel = %ld", avChannel);
        if (nvrStopVideoDataBlock)
        {
            nvrStopVideoDataBlock(NO, deviceId, avChannel);
        }
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async([self getNvrQueueWithNvrID:deviceId
                                     avCannel:(int)avChannel], ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"=== NetAPISet === 对象丢失，无法停止 nvr 视频流数据, avChannel = %ld", avChannel);
            
            return ;
        }
        NSLog(@"=== NetAPISet === 发送停止 nvr 视频流数据请求, avChannel = %ld, queue = %@", avChannel, [self getNvrQueueWithNvrID:deviceId
                                                                                                               avCannel:(int)avChannel]);
        long result = [strongSelf.netPro NetPro_CloseStreamWithHandle:[strongSelf handleFromUID:deviceId]
                                                              channel:(int)avChannel
                                                           streamType:kNETPRO_STREAM_VIDEO];
        if (1 == result)
        {
            NSLog(@"=== NetAPISet === 发送停止 nvr 视频流数据请求,成功了, avChannel = %ld", avChannel);
            if (nvrStopVideoDataBlock)
            {
                nvrStopVideoDataBlock(YES, deviceId, avChannel);
            }
        }
        else
        {
            NSLog(@"=== NetAPISet === 发送停止 nvr 视频流数据请求,失败了，avChannel = %ld", avChannel);
            if (nvrStopVideoDataBlock)
            {
                nvrStopVideoDataBlock(NO, deviceId, avChannel);
            }
        }
    });
}


#pragma mark -- 删除 NVR 设备
- (BOOL)nvrDeleteWithDeviceId:(NSString *)nvrDeviceId
                 avChannelNum:(long)avChannelNum
{
    if (!nvrDeviceId || 0 >= nvrDeviceId.length)
    {
        NSLog(@"无法删除 NVR 设备， nvrDeviceId = %@", nvrDeviceId);
        
        return NO;
    }
    
    for (int i = 0 ; i < avChannelNum; i++)
    {
        [self nvrStopGetVideoDataWithDeviceId:nvrDeviceId
                                    avChannel:i
                        nvrStopVideoDataBlock:^(BOOL isSuccess,
                                                NSString *nvrDeviceId,
                                                long avChannel) {
                            
                            NSLog(@"删除 NVR 设备，停止视频流结果：%d", isSuccess);
                        }];
    }
    
    NSInteger devHandle = [self handleFromUID:nvrDeviceId];
    
    BOOL ret = [self net_closeDevConnWithUID:nvrDeviceId handle:devHandle];
    if (YES == ret)
    {
        for (int i = 0; i < _uidArray.count; i++)
        {
            if ([_uidArray[i].uidStr isEqualToString:nvrDeviceId])
            {
                [_uidArray removeObjectAtIndex:i];
            }
        }
        return YES;
    }
    
    return NO;
}


#pragma mark -- 获取 NVR 录像列表
- (void)nvrGetVideoListWithDeviceId:(NSString *)nvrDeviceId
                        channelMask:(uint32_t)channelMask
                           typeMask:(uint32_t)typeMask
                               date:(NSString *)date
                          startTime:(NSString *)startTime
                            endTime:(NSString *)endTime
                        resultBlock:(NvrRecordListBlock)recordListBlock
{
    if (!nvrDeviceId || 0 >= nvrDeviceId.length)
    {
        NSLog(@"无法获取 NVR 录像列表， nvrDeviceId = %@", nvrDeviceId);
        
        return;
    }
    self.nvrRecordListBlock = nil;
    self.nvrRecordListBlock = recordListBlock;
    __weak typeof(self) weakSelf = self;
    dispatch_async([self getNvrQueueWithNvrID:nvrDeviceId
                                     avCannel:(int)channelMask], ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法获取 NVR 录像列表！");
            
            return ;
        }
        NSLog(@" ==== 发送获取 NVR 录像列表请求, channelMask = %d", channelMask);
        [strongSelf.netPro NetPro_GetNvrVideoListWithHandle:[strongSelf handleFromUID:nvrDeviceId]
                                                channelMask:channelMask
                                                   typeMask:typeMask
                                                       date:date
                                                  startTime:startTime
                                                    endTime:endTime];
    });
}


#pragma mark -- 开启 NVR 录像回放
- (void)nvrPBPlayWithDevId:(NSString *)nvrDeviceId
                  filePath:(NSString *)filePath
             playCtrlBlock:(NvrRecordPlayCtrlBlock)playCtrlBlock
{
    if (!nvrDeviceId || 0 >= nvrDeviceId.length
        || !filePath || 0 >= filePath.length)
    {
        NSLog(@"无法创建 NVR 录像回放 av 通道， nvrDeviceId = %@, filePath = %@", nvrDeviceId, filePath);
        
        return;
    }
    self.nvrRecPlayCtrlBlock = nil;
    self.nvrRecPlayCtrlBlock = playCtrlBlock;
    __weak typeof(self) weakSelf = self;
    dispatch_semaphore_wait(self.nvrPlaybackSemaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法创建 NVR 录像回放 av 通道！");
            
            return ;
        }
        NSLog(@"=== NetAPISet === 发送开启 NVR 录像回放请求, filePath = %@", filePath);
        long resut = [strongSelf.netPro NetPro_NvrStreamPlayWithHanle:[strongSelf handleFromUID:nvrDeviceId]
                                                             filePath:filePath];
        NSLog(@"=== NetAPISet === 发送开启 NVR 录像回放请求结果, resut = %ld", resut);
        dispatch_semaphore_signal(strongSelf.nvrPlaybackSemaphore);
    });
}


#pragma mark -- NVR 录像回放播放控制
- (void)nvrRecordPlayCtrlWithDeviceId:(NSString *)nvrDeviceId
                            avChannel:(int)avChannel
                         playCtrlType:(kNetRecCtrlType)netRecCtrlType
                           seekSecond:(long)seekSecond
{
    if (!nvrDeviceId || 0 >= nvrDeviceId.length
        || 0 > avChannel)
    {
        NSLog(@"无法控制 NVR 录像回放播放， nvrDeviceId = %@, avChannel = %d", nvrDeviceId, avChannel);
        
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async([self getNvrQueueWithNvrID:nvrDeviceId
                                     avCannel:(int)avChannel], ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法控制 NVR 录像回放播放！");
            
            return ;
        }
        NSLog(@" ==== 发送控制 NVR 录像回放播放请求, avChannel = %d, netRecCtrlType = %d, seekSecond = %ld", avChannel, netRecCtrlType, seekSecond);
        [strongSelf.netPro NetPro_CtrlNvrRecordFileWithHandle:[strongSelf handleFromUID:nvrDeviceId]
                                                    avChannel:avChannel
                                                 playCtrlType:netRecCtrlType
                                                   seekSecond:seekSecond];
    });
}


#pragma mark -- 根据返回的时间结构体解析时间串
NSString *getTimeStrWithStruct(GOS_DateTime gosDateTime)
{
    NSString *year   = nil;
    NSString *month  = nil;
    NSString *day    = nil;
    NSString *hour   = nil;
    NSString *minute = nil;
    NSString *second = nil;
    
    year = [NSString stringWithFormat:@"%d", gosDateTime.m_year];
    
    if (1 <= gosDateTime.m_month && 9 >= gosDateTime.m_month)
    {
        month = [NSString stringWithFormat:@"0%d", gosDateTime.m_month];
    }
    else
    {
        month = [NSString stringWithFormat:@"%d", gosDateTime.m_month];
    }
    
    if (1 <= gosDateTime.m_day && 9 >= gosDateTime.m_day)
    {
        day = [NSString stringWithFormat:@"0%d", gosDateTime.m_day];
    }
    else
    {
        day = [NSString stringWithFormat:@"%d", gosDateTime.m_day];
    }
    
    if (9 >= gosDateTime.m_hour)
    {
        hour = [NSString stringWithFormat:@"0%d", gosDateTime.m_hour];
    }
    else
    {
        hour = [NSString stringWithFormat:@"%d", gosDateTime.m_hour];
    }
    
    if (9 >= gosDateTime.m_minute)
    {
        minute = [NSString stringWithFormat:@"0%d", gosDateTime.m_minute];
    }
    else
    {
        minute = [NSString stringWithFormat:@"%d", gosDateTime.m_minute];
    }
    
    if (9 >= gosDateTime.m_second)
    {
        second = [NSString stringWithFormat:@"0%d", gosDateTime.m_second];
    }
    else
    {
        second = [NSString stringWithFormat:@"%d", gosDateTime.m_second];
    }
    
    // "2017-03-17 19:11:58"
    NSString *timeStr = [NSString stringWithFormat:@"%@-%@-%@ %@:%@:%@", year, month, day, hour, minute, second];
    
    return timeStr;
}




@end

