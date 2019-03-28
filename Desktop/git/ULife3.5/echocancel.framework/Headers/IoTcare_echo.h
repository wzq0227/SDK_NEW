//
//  IoTcare_echo.h
//  echocancel
//
//  Created by icare_tank on 2017/11/1.
//  Copyright © 2017年 icare_tank. All rights reserved.
//
#import <AudioToolbox/AudioToolbox.h>
#import <sys/utsname.h>
#define ECHO_NOERR 0
#define ECHO_ERR_INVALID_APIKEY -1
#define ECHO_ERR_APIKEY_NO_AUTHENTICATION  -2
#define ECHO_ERR_BAD_PARAMETER -3
#define ECHO_ERR_API_HAVE_BEEN_ININTIALIZED -4
#define ECHO_ERR_NOT_ININTIALIZE -5
#define ECHO_ERR_APIKEY_HAVE_BEEN_EXPAIRED -6
#define ECHO_ERR_SAMPLERATE_NOT_SET -7
#define ECHO_ERR_INVALID_PACKAGE_NAME -8
#define ECHO_ERR_AGC_ENABLE_FAILED -9
#define ECHO_ERR_AGC_CONFIG_FAILED -10

@protocol IoTcareEchoDelegate <NSObject>

@optional

-(void)echo_outbuf:(const char *)audiobuf bufsize:(int)size;
/*此回调方法将消除回声的PCM音频数据返回出来，目前返回的audiobuf大小在320B~1280B，可以在此回调中调用音频格式编码接口和实际P2P发送音频数据的接口
 *audiobuf  消除回声的PCM数据
 *size      audiobuf的实际数据大小
 */

@end


@interface IoTcare_echo : NSObject

@property (nonatomic, weak) id<IoTcareEchoDelegate> delegate;


-(instancetype)init NS_DESIGNATED_INITIALIZER;
/*初始化对象调用此接口一次*/

-(int)IoTcare_echo_auth:(NSString*)apikey;
/*调用下面三个接口之前必须调用此接口一次
 *apikey    由我司提供回音消除库的使用授权
 *return    ECHO_ERR_BAD_PARAMETER
 *          ECHO_ERR_APIKEY_HAVE_BEEB_EXPAIRED
 *          ECHO_ERR_INVALID_APIKEY
 *          ECHO_NOERR
 */

-(int)IoTcare_echo_set_sampleRate:(int)rate BitsPerChannel:(int)bit ChannelsPerFrame:(int)channel;
/*在调用IoTcare_echo_start之前必须先设置音频格式
 *rate      音频采样率8000~16000
 *bit       音频采样深度16/32位
 *channel   音频声道 1:单声道  2:立体声
 *return    ECHO_ERR_NOT_ININTIALIZE
 *          ECHO_ERR_APIKEY_NO_AUTHENTICATION
 *          ECHO_ERR_BAD_PARAMETER
 *          ECHO_NOERR
 */
-(int)IoTcare_echo_start;
/*开始双向对讲的时候调用此接口,此方法底层实际实现已经包含mic音频采集，降噪，回音消除，增益(需要停用以前的录音的线程，以免冲突，消除回音的数据会通过echo_outbuf回调方法进行返回)
 *return    ECHO_ERR_NOT_ININTIALIZE
 *          ECHO_ERR_APIKEY_NO_AUTHENTICATION
 *          ECHO_NOERR
 */
-(int)IoTcare_echo_enable_agc:(int)sampleRate;
/* 这是一个回声消除AGC启用函数，如果需要对远端音频进行增益可调用此函数:
 * sampleRate      增益音频数据的采样率，支持8k/16K;
 * return:
 *              =0 启用成功;
 *              <0 返回错误码请参考errnotype中错误码定义:
 *                 ECHO_ERR_APIKEY_NO_AUTHENTICATION
 *                 ECHO_ERR_API_HAVE_BEEN_ININTIALIZED
 *                 ECHO_ERR_AGC_ENABLE_FAILED
 *              注意:请根据设备实际的系统资源足够的情况下，开启增益;
 */
-(int)IoTcare_echo_config_agc:(int)GainDB;
/* 这是一个音频增益参数设置函数，在IoTcare_echo_enable_agc之后调用:
 * GaindB          音频增益的大小,默认:9~20DB，默认9DB;
 * return:
 *              =0 设置成功;
 *              <0 返回错误码请参考errnotype中错误码定义:
 *                 ECHO_ERR_NOT_ININTIALIZE
 *                 ECHO_ERR_BAD_PARAMETER
 *                 ECHO_ERR_AGC_CONFIG_FAILED
 */

-(int)IoTcare_echo_agc:(const char *)inbuf insize:(int)size agcbuf:(char*)outbuf;
/* 这是一个回声消除音频增益处理函数，在近端声音播放之前调用:
 * inbuf        PCM音频数据;
 * size         inbuf数据的大小，必须为160B的倍数;
 * outbuf       数字增益的PCM音频数据;
 * return:
 *              =0 消除噪音成功;
 *              <0 返回错误码请参考errnotype中错误码定义:
 *                 ECHO_ERR_APIKEY_NO_AUTHENTICATION
 *                 ECHO_ERR_BAD_PARAMETER
 *                 ECHO_ERR_NOT_ININTIALIZE
 *              注意:必须调用IoTcare_echo_enable_agc(1);开启增益模块
 */
-(int)IoTcare_agc_destroy;
/*停止app播放的音频的时候调用此接口
 *return    ECHO_ERR_NOT_ININTIALIZE
 *          ECHO_ERR_APIKEY_NO_AUTHENTICATION
 *          ECHO_NOERR
 */

-(int)IoTcare_echo_outdata_size:(int)size;
/*设置echo_outbuf返回的buf的时候调用此接口
 *size      echo_outbuf的大小，默认为20ms数据的大小(8k:320B 16k:640B)
 *return    ECHO_ERR_NOT_ININTIALIZE
 *          ECHO_ERR_APIKEY_NO_AUTHENTICATION
 *          ECHO_ERR_BAD_PARAMETER
 *          ECHO_NOERR
 */



-(int)IoTcare_echo_destroy;
/*停止双向通话的时候调用此接口
 *return    ECHO_ERR_NOT_ININTIALIZE
 *          ECHO_ERR_APIKEY_NO_AUTHENTICATION
 *          ECHO_NOERR
 */
@end
