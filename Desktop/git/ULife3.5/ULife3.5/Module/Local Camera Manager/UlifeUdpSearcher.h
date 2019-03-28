//
//  UlifeUdpSearcher.h
//  GosGetAndSet
//
//  Created by yuanx on 13-3-4.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "DeviceInfoStruct.h"
#import "GVAP_deviceDiscover.h"

#define LOCALDEVICEINFO @"localdeviceInfo"
@interface UlifeUdpSearcher : NSObject
{
	id _delegate;
	int _nTimeout;
	BOOL _bStopThread, _bThreadIsRunning;
}
@property(nonatomic, readonly)BOOL isSearching;

/*!
 @method
 @abstract 搜索ulife摄像头
 @param timeout 超时时间
 @param delegate 回调函数指针
 @result BOOL 成功状态
 */
-(void)startSearchWithTimeout:(int)timeout delegate:(id)delegate andUID:(NSString *)UID;


/*!
 @method
 @abstract 在搜索的同时发送rebroudcast可再次发送搜索广播,提高搜索到所有摄像头机率.
 @result BOOL 成功状态
 */

-(BOOL)reBroadcast;


/*!
 @method
 @abstract 停止搜索.
 @result null
 */
-(void)stopSearch;


@end


@protocol UlifeUdpSearchDelegate <NSObject>

@optional
/*!
 @method
 @abstract 搜索结果回调
 @discussion 当搜索到摄像头时执行此回调
 @param info 参数结构体
 @param host 广播来自哪个主机
 @param port 广播来自哪个端口
 @result null
 */
-(void)onUlifeUdpSearchGotInfo:(DeviceInfo_t)info fromHost:(char*)host port:(int)port;

/*!
 @method
 @abstract 搜索结束
 @discussion
 @result null
 */
-(void)onUlifeUdpSearchDone;

@end



