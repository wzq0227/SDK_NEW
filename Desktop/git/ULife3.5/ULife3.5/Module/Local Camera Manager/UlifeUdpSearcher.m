//
//  UlifeUdpSearcher.m
//  GosGetAndSet
//
//  Created by yuanx on 13-3-4.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import "UlifeUdpSearcher.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <sys/ioctl.h>
#import <net/if.h>
#import <netdb.h>

@interface UlifeUdpSearcher (Private)

-(void)startListenThread;
-(void)stopListenThread;
-(void)listen;

-(int)broadcast;

-(void)gotBroadcast:(char*)buffer length:(long)len fromIp:(char*)ip port:(int)port;
-(void)timeIsUp;

@end

@implementation UlifeUdpSearcher
{
     NSString *_UID;
}
@synthesize isSearching = _isSearching;

#pragma mark - PUBLIC

-(void)startSearchWithTimeout:(int)timeout delegate:(id)delegate andUID:(NSString *)UID;
{
    _UID = UID;
	_isSearching = YES;
	[self stopListenThread];
	_nTimeout = timeout;
	_delegate = delegate;
	if (timeout > 0)
	{
		[self performSelector:@selector(timeIsUp) withObject:nil afterDelay:timeout];
	}
	[self startListenThread];
	[self broadcast];
}

-(void)stopSearch
{
    if (_nTimeout > 0)
	{
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeIsUp) object:nil];
	}
    if ([_delegate respondsToSelector:@selector(onUlifeUdpSearchDone)])
	{
		[_delegate onUlifeUdpSearchDone];
	}
	_delegate = nil;
    _nTimeout = 0;
	[self stopListenThread];
	_isSearching = NO;
}

-(BOOL)reBroadcast
{
	if (_bThreadIsRunning)
	{
		return [self broadcast];
	}
	else
	{
		return NO;
	}
}

#pragma mark - PRIVATE


-(void)timeIsUp
{
	[self stopListenThread];
}

-(void)startListenThread
{
	_bStopThread = NO;
	[NSThread detachNewThreadSelector:@selector(listen) toTarget:self withObject:nil];
}

-(void)stopListenThread
{
    _bStopThread = YES;
    usleep(1000);
//	while (_bThreadIsRunning)
//	{
////		NSLog(@"while (_bThreadIsRunning)");
//	}
//	_bStopThread = YES;
//	_delegate = nil;
//	_nTimeout = 0;
}

-(void)listen
{
	_bThreadIsRunning = YES;

	int nBufferLength = 1024 * 4;
	char* buf = malloc(nBufferLength);
	int sockfd;
	int tolen ;
	socklen_t fromlen = sizeof(struct sockaddr_in);
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
        NSLog(@"nRet = %d",nRet);
		if(nRet > 0)
		{
			memset(&buf, nBufferLength, 0);
            
			if((n = recvfrom(sockfd,buf,1024*10,0,(struct sockaddr *)&from_address,&fromlen)) > 0)
			{
//				NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>recv %s", buf);
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
	if ([_delegate respondsToSelector:@selector(onUlifeUdpSearchDone)])
	{
		[_delegate onUlifeUdpSearchDone];
	}
//	NSLog(@"监听线程结束");
	_bThreadIsRunning = NO;
}

-(int)broadcast
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
//		NSLog(@"setsockopt: errno: %d ret:%d", errno, ret1);
	}
	DeviceInfo_t info = {0};
	info.nCmd = GOSGET;
	strcpy(info.szPacketFlag,CMD_GET_FLAG);

	long ret2 = sendto(sockfd , &info , sizeof(DeviceInfo_t), 0 , (struct sockaddr *)&to_address , tolen);
	if (ret2 == sizeof(DeviceInfo_t))
	{
//		NSLog(@"broadcast success: %ld", sizeof(DeviceInfo_t));
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
    if (len == sizeof(DeviceInfo_t) && buffer && port == UDP_PORT_SEND )
    {
        DeviceInfo_t info = {0};
        memcpy(&info, buffer, sizeof(DeviceInfo_t));
        NSString *uid = [NSString stringWithCString:info.szCamSerial encoding:NSUTF8StringEncoding];
        NSLog(@"uid = %@",uid);
        if (_UID == nil) {
            return;
        }
        if (info.nCmd == RESPONDGOSGET)
        {
            if ([ uid rangeOfString:_UID].length!=0) {
                static NSString * serialStr;
                static NSString * deviceIPStr;
                serialStr = [NSString stringWithCString:info.szCamSerial encoding:NSUTF8StringEncoding];
                deviceIPStr = [NSString stringWithCString:info.szWiFiIP encoding:NSUTF8StringEncoding];
                NSArray *infoArr = @[serialStr,deviceIPStr];
                [[NSNotificationCenter defaultCenter] postNotificationName:LOCALDEVICEINFO object:infoArr];
            }
            if (_delegate&&[_delegate respondsToSelector:@selector(onUlifeUdpSearchGotInfo:fromHost:port:)]) {
                [_delegate onUlifeUdpSearchGotInfo:info fromHost:ip port:port];
            }
        }
    }
}


@end
