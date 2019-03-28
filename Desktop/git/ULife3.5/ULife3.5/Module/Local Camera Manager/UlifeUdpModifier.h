//
//  UlifeUdpModifier.h
//  GosGetAndSet
//
//  Created by yuanx on 13-3-4.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GVAP_deviceDiscover.h"


/*
 
 监听
 发送set命令
 回调
 结束
 
 */

//typedef _tmDeviceInfo_t DeviceInfo_t;

typedef enum ModifierOnDeviceNotice
{
	ModifierOnDeviceNoticeSuccess,
	ModifierOnDeviceNoticeFailed,
	ModifierOnDeviceNoticePasswordUncorrect,
	ModifierOnDeviceNoticeTimeout,
	ModifierOnDeviceNoticeUnknownError
}
ModifierOnDeviceNotice;



@interface UlifeUdpModifier : NSObject
{
	DeviceInfo_t _targetInfo;
	id _delegate;
	int _nTimeout;
	BOOL _bStopThread, _bThreadIsRunning;
}


/*!
 @method
 @abstract 设置为新的参数
 @discussion
 @param info 新的参数结构体. 由搜索到的结构体修改而来.
 @param timeout 超时时间
 @param delegate 回调函数指针
 @result null
 */
-(void)startModifyInfo:(DeviceInfo_t*)info timeout:(int)timeout delegate:(id)delegate;

/*!
 @method
 @abstract 用于在超时前停止设置
 @discussion
 @result null
 */
-(void)stopModify;

@end



@protocol UlifeUdpModifierDelegate <NSObject>


/*!
 @method
 @abstract 设置结果回调. 无论是成功失败还是超时都由此回调.
 @discussion
 @param ret 成功状态
 @param info 新的结构体. 当失败时info为空.
 @result null
 */
-(void)onUlifeUdpModifierDoneWithRet:(ModifierOnDeviceNotice)ret newInfo:(DeviceInfo*)info;


@end
