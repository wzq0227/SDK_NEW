//
//  UlifeUdpModifier.m
//  GosGetAndSet
//
//  Created by yuanx on 13-3-4.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import "UlifeUdpModifier.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <sys/ioctl.h>
#import <net/if.h>
#import <netdb.h>

@interface UlifeUdpModifier (Private)


-(void)startListenThread;
-(void)stopListenThread;
-(void)listen;

-(int)sendSetBroadcast;

@end


@implementation UlifeUdpModifier

-(void)startModifyInfo:(DeviceInfo_t*)info timeout:(int)timeout delegate:(id)delegate
{
	
	_nTimeout = timeout > 1 ? timeout : 1;
	_delegate = delegate;
	[self stopListenThread];
	[self startListenThread];
	[self performSelector:@selector(stopListenThread) withObject:nil afterDelay:_nTimeout];
	if(info)
	{
		memcpy(&_targetInfo, info, sizeof(DeviceInfo_t));
		_targetInfo.nCmd = GOSSET;
		strcpy(_targetInfo.szPacketFlag, CMD_SET_INFO_FLAG);
		[self sendSetBroadcast];
	}
}

-(void)stopModify
{
	_delegate = nil;
	[self stopListenThread];
}

#pragma mark -

-(void)startListenThread
{
	_bStopThread = NO;
	[NSThread detachNewThreadSelector:@selector(listen) toTarget:self withObject:nil];
}
-(void)stopListenThread
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopListenThread) object:nil];
	while (_bThreadIsRunning)
	{
		_bStopThread = YES;
		usleep(5000);
	}
	_bStopThread = YES;
}
-(void)listen
{
	_bThreadIsRunning = YES;
	
	
	int nBufferLength = 1024 * 4;
	char* buf = malloc(nBufferLength);
	int sockfd;
	int tolen ;
	socklen_t fromlen;
	struct sockaddr_in local_address;
	struct sockaddr_in from_address ;
	
	sockfd = socket(AF_INET,SOCK_DGRAM,0);
	local_address.sin_family = AF_INET ;
	local_address.sin_addr.s_addr = INADDR_ANY;
	local_address.sin_port = htons(UDP_PORT_RECV) ;
	tolen = sizeof(local_address);
	bind(sockfd , (struct sockaddr *)&local_address , tolen);
	
	long n=0;
	while (!_bStopThread)
	{
		struct timeval timeout;
		timeout.tv_sec = 0;
		timeout.tv_usec = 200 * 1000;
		fd_set  fdR;
		FD_ZERO(&fdR);
		FD_SET(sockfd, &fdR);
		int nRet = select(sockfd + 1, &fdR, NULL, NULL, &timeout);
		if(nRet > 0)
		{
			memset(&buf, nBufferLength, 0);
			if((n = recvfrom(sockfd,buf,1024*10,0,(struct sockaddr *)&from_address,&fromlen)) > 0)
			{
				[self gotBroadcast:buf length:n fromIp:inet_ntoa(from_address.sin_addr) port:ntohs(from_address.sin_port)];
			}
		}
	}
	
	
Error:
	
	if (buf)
	{
		free(buf);
		buf = nil;
	}
	if (sockfd > 0)
	{
		close(sockfd);
		sockfd = 0;
	}
	
	if ([_delegate respondsToSelector:@selector(onUlifeUdpModifierDoneWithRet:newInfo:)])
	{
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           [_delegate onUlifeUdpModifierDoneWithRet:ModifierOnDeviceNoticeTimeout newInfo:nil];
                           _delegate = nil;
                       });
	}
	
	_bThreadIsRunning = NO;
}

-(int)sendSetBroadcast
{
	
	int sockfd = 0;;
	int tolen;
	struct sockaddr_in to_address;
	sockfd = socket(AF_INET,SOCK_DGRAM,0);		//第一个参数默认AF_INET	第二个参数, SOCK_DGRAM:UDP		SOCK_STREAM:TCP
	if (sockfd < 0)
	{
		return -1;
	}
	
	to_address.sin_family = AF_INET ;
	to_address.sin_addr.s_addr = INADDR_BROADCAST;
	//	to_address.sin_addr.s_addr = inet_addr("192.168.20.103");
	to_address.sin_port = htons(UDP_PORT_SEND) ;
	tolen = sizeof(to_address);
	
	
	int bEnabel = YES;
	int ret1 = setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST, &bEnabel, sizeof(bEnabel));
	if (ret1 < 0)
	{
		perror("setsockopt:");
		NSLog(@"setsockopt: errno: %d ret:%d", errno, ret1);
	}
	
	char* buffer = malloc(sizeof(DeviceInfo_t));
	memcpy(buffer, &_targetInfo, sizeof(DeviceInfo_t));
	
	long ret2 = sendto(sockfd , buffer , sizeof(DeviceInfo_t), 0 , (struct sockaddr *)&to_address , tolen);
	if (ret2 == sizeof(DeviceInfo_t))
	{
		NSLog(@"broadcast success: %ld", sizeof(DeviceInfo_t));
	}
	
	close(sockfd);
	sockfd = 0;
	if (ret1 < 0 || ret2 < 0)
	{
		return -1;
	}
	return 0;
}

-(void)gotBroadcast:(char*)buffer length:(long)len fromIp:(char*)ip port:(int)port
{
	if (buffer && len == sizeof(DeviceInfo_t) && [_delegate respondsToSelector:@selector(onUlifeUdpModifierDoneWithRet:newInfo:)])
	{
		__block DeviceInfo_t info = {0};
		memcpy(&info, buffer, sizeof(DeviceInfo_t));
		NSLog(@"收到广播: %s cmd: %d flag:%s", info.szCamSerial, info.nCmd, info.szPacketFlag);
		if (strcmp(info.szCamSerial, _targetInfo.szCamSerial) == 0)
		{
			ModifierOnDeviceNotice ret = ModifierOnDeviceNoticeFailed;
			
			if (info.nCmd == WRONGGOSSET)
			{
				ret = ModifierOnDeviceNoticePasswordUncorrect;
			}
			else if(info.nCmd == RIGHTGOSSET)
			{
				ret = ModifierOnDeviceNoticeSuccess;
			}
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               [_delegate onUlifeUdpModifierDoneWithRet:ret newInfo:&info];
                               [self stopModify];
                           });
		}
	}
}


@end              
