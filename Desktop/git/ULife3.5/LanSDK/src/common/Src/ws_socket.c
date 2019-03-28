#include "ws_socket.h"
#include <stdio.h>

#if defined(WIN32)
#include <winsock2.h>
#include <time.h>
#else
#include <time.h>
#include <sys/file.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <sys/time.h>
#include <errno.h>
#include<netinet/tcp.h>
#endif


#ifdef WIN32

int _WS_FDIsSet(int fd, fd_set FAR *set)
{
	return __WSAFDIsSet((SOCKET)(fd), (fd_set FAR *)(set));
}


#else

/* Removes the descriptor fd from set. */
void WS_FD_CLR(int fd, fd_set *set)
{
	FD_CLR(fd,(fd_set*)set);
}


/* Adds descriptor fd to set. */
void WS_FD_SET(int fd, fd_set *set) 
{
	FD_SET(fd,(fd_set*)set);
}


/* Initializes the set to the null set. */
void WS_FD_ZERO(fd_set *set)
{
	FD_ZERO((fd_set*)set);
}


/* Nonzero if fd is a member of the set. Otherwise, zero. */
int WS_FD_ISSET(int fd, fd_set *set)
{
	return FD_ISSET(fd,(fd_set*)set);
}

#endif

int WS_socket_init(void)
{
#ifdef WIN32
		WSADATA wsd;
		if( 0 != WSAStartup(MAKEWORD(2,2),&wsd))
		{
			printf("WSAStartup failed ! \n");
			return(-1);
		}
		return(0);

#else

		return 0;

#endif	
}

int WS_socket(int family,int type,int protocol)
{
#ifdef WIN32

	int		ret;
	if(SOCK_DGRAM == type || SOCK_STREAM == type)
	{
		ret =  socket(family,type,protocol);
	}
	else
	{
		ret = WSASocket(family,type,protocol,NULL,0,0);
	}
	return INVALID_SOCKET == ret ? -1:ret;

#else

	int ret;
	ret = socket(family,type,protocol);
	return ret;

#endif
}

int WS_bind(int s,WS_SOCKADDR * addr,int addrlen)
{
#ifdef WIN32

	return (bind(s,(struct sockaddr *)addr,addrlen) == SOCKET_ERROR) ? -1 : 0;

#else

	return (-1 == bind(s,(struct sockaddr *)addr,addrlen)) ? -1 : 0;

#endif
}

int WS_listen(int s,int backlog)
{
#ifdef WIN32

	return (0 == listen(s,backlog)) ? 0 : -1;

#else

	return -1 == listen (s,backlog) ? -1 : 0;

#endif
}

int WS_accept(int s,WS_SOCKADDR *addr,int  *addrlen)
{
#ifdef WIN32

	int ret ;
	ret = accept(s,(struct sockaddr *)addr,addrlen);
	return INVALID_SOCKET == ret ? -1 : ret;

#else

	int ret ;
	ret = accept(s,(struct sockaddr *)addr,(unsigned int *)addrlen);
	return -1 ==  ret ? -1 : ret;

#endif
}

int WS_connect(int s,WS_SOCKADDR * addr,int addrlen)
{
#ifdef WIN32

	return (0 == connect(s,(struct sockaddr *)addr,addrlen)) ? 0 : -1;

#else

	return -1 == connect(s,(struct sockaddr *)addr,addrlen) ? -1 : 0;

#endif
}

int WS_connectWithTimeout(int s,WS_SOCKADDR * addr,int addrlen,struct timeval *  timeVal)
{
	time_t begin_time,now,wait_time ;
	wait_time = timeVal->tv_sec*1000+timeVal->tv_usec/1000;
	time(&begin_time);
	while(1)
	{
		if(0 == connect(s,(struct sockaddr *)addr,addrlen))
		{
			return(0);
		}
		else
		{
			time(&now);
			if((now - begin_time)*1000 >= wait_time)
				return(-1);
			else
				continue;
		}
	}
	return -1;
}

int WS_sendto(int s,char* buf,int bufLen,int flags,WS_SOCKADDR * to,int tolen)
{
#ifdef WIN32

	int ret;
	ret = sendto(s,buf,bufLen,flags,(struct sockaddr *)to,tolen);
	return SOCKET_ERROR == ret ?  -1 : ret;

#else

	int ret;
	ret = sendto(s,buf,bufLen,flags,(struct sockaddr *)to,tolen);
	return ret;
#endif	
}

int WS_send(int s,char* buf,int bufLen, int flags)
{
#ifdef WIN32

	int ret ;
	ret = send(s,buf,bufLen,flags);
	return 	SOCKET_ERROR == ret ? -1 : ret;

#else

	int ret ;
	ret = send(s,buf,bufLen,flags);
	return 	ret;


#endif
}

int WS_recvfrom(int s,char *buf,int bufLen,int flags,WS_SOCKADDR *from,int *pFromLen)
{
#ifdef WIN32

	int ret;
	ret = recvfrom(s,buf,bufLen,flags,(struct sockaddr *)from,pFromLen);
	return 	SOCKET_ERROR == ret ? -1 : ret;

#else

	int ret;
	ret = recvfrom(s,buf,bufLen,flags,(struct sockaddr *)from,(unsigned int *)pFromLen);
	return 	ret;

#endif
}

int WS_recv(int s,char * buf,int bufLen,int flags)
{
#ifdef WIN32
	int ret;
	ret = recv(s,buf,bufLen,flags);
	return 	SOCKET_ERROR == ret ? -1 : ret;

#else

	int ret;
	ret = recv(s,buf,bufLen,flags);
	return 	ret;

#endif
}

int WS_setsockopt(int s,int level,int optname,char *optval,int optlen)
{

//#ifdef WIN32

	return 	(0 == setsockopt(s,level,optname,optval,optlen)) ? 0 : -1;

//#else
//	struct timeval tv_out;
//	tv_out.tv_sec = (*((int*)optval))/1000;
//	tv_out.tv_usec = 0;
//	return 	-1 == setsockopt(s,level,optname,(char*)&tv_out,sizeof(struct timeval)) ? -1 : 0;
//
//#endif	
}

int WS_getsockopt(int s,int level,int optname,char *optval,int *optlen)
{
#ifdef WIN32

	return 	(0 == getsockopt(s,level,optname,optval,optlen)) ? 0 : -1;

#else

	return 	-1 == getsockopt(s,level,optname,optval,(unsigned int *)optlen) ? -1 : 0;

#endif	
}

int WS_getsockname(int s,WS_SOCKADDR *addr,  int *addrlen)
{
#ifdef WIN32

	return 	(0 == getsockname(s,(struct sockaddr *)addr,addrlen)) ? 0 : -1;

#else

	return 	-1 == getsockname(s,(struct sockaddr *)addr,(unsigned int *)addrlen) ? -1 : 0;

#endif
}

int WS_getpeername(int s,WS_SOCKADDR *name,int *namelen)
{
#ifdef WIN32

	return 	(0 == getpeername(s,(struct sockaddr *)name,namelen)) ? 0 : -1;

#else

	return 	-1 == getpeername(s,(struct sockaddr *)name,(unsigned int *)namelen) ? -1 : 0;

#endif	
}

int WS_shutdown(int s,int how)
{
#ifdef WIN32

	return 	(SOCKET_ERROR  == shutdown(s,how)) ? -1 : 0;

#else

	return 	-1 == shutdown(s,how) ? -1 : 0;

#endif	
}

int WS_close(int fd)
{
#ifdef WIN32

	return 	(0 == closesocket(fd)) ? 0 : -1;

#else

	return -1 == close(fd) ? -1 : 0;

#endif
}

int WS_hostGetByName(char * hostname)
{
		struct hostent* host = gethostbyname(hostname);
       	return NULL == host ? -1 : ((WS_IN_ADDR*)(host->h_addr))->s_addr;
}

int WS_hostGetByAddr(int addr,char *name)
{
	    struct in_addr in;
		struct hostent *host = NULL;	
		in.s_addr = addr;		
		host = gethostbyaddr(inet_ntoa(in),sizeof(addr),AF_INET);
		if(host!=NULL)
		{
			memcpy(name,host->h_name,strlen(host->h_name));			
			return (0);
		}
		else
		{
			return (-1);
		}
}

// int WS_sethostname(char * name,int nameLen)
// {
// 
//     #if defined(WSSI_VXWORKS)  || defined(LINUX) || defined(WSSI_UNIX)  
// 
// 	  #if defined(ANDROID)
// 
// 	    return -1;
// 
//      #else
// 
// 		return (ERROR == sethostname(name,nameLen) ? -1:0);
//      #endif
// 
// 	#elif defined(WIN32)
// 
// 		return -1;
// 
// 	#else
// 
// 		#error "What is OS type?"
// 
// 	#endif
// }
// 
// 

int WS_gethostname(char * name,int nameLen)
{
#ifdef WIN32
	return(0 == gethostname(name,nameLen)) ? 0 : -1;

#else

	return(-1 == gethostname(name,nameLen) ? -1 : 0);

#endif
}

unsigned int WS_inet_addr(const char * inetString)
{

#ifdef WIN32
	unsigned int ret;
	ret = inet_addr(inetString);
	return INADDR_NONE == ret ?  -1: ret;

#else

	unsigned int ret;
	ret = inet_addr(inetString);
	return (unsigned int)-1 == ret ? (unsigned int)-1 : ret ;

#endif
}

// int WS_inet_lnaof(int inetAddress)
// {
// 
//     #if defined(WSSI_VXWORKS)  
// 
// 		return inet_lnaof(inetAddress);
// 
// 	#elif defined(WIN32)
// 
// 		return inetAddress & 0x00ffffff;
// 
// 	#elif defined(LINUX) || defined(WSSI_UNIX)
// 
// 	  #if defined(ANDROID)
// 	 	 return inetAddress & 0x00ffffff;
// 	  #else
// 
// 		struct in_addr addr;
// 		addr.s_addr = inetAddress;
// 		return inet_lnaof(addr);
// 	  #endif
// 	#else
// 
// 		#error "What is OS type?"
// 
// 	#endif
// }

char* WS_inet_ntoa(WS_IN_ADDR inetAddress)
{
#ifdef WIN32
	struct in_addr in;
	memcpy(&in, &inetAddress, sizeof(WS_IN_ADDR));
	//d		inetAddress.s_addr = htonl(inetAddress.s_addr);
	return inet_ntoa(in);

#else

	struct in_addr addr;
	memcpy(&addr,&inetAddress,sizeof(struct in_addr));
	return inet_ntoa(addr);

#endif
}

// int WS_inet_aton(char *pString)
// {
// 
//     #if defined(WSSI_VXWORKS)   
// 		WS_IN_ADDR inetAddress;
// 
// 		if(ERROR == inet_aton(pString,&inetAddress))
// 			return -1;
// 		else
// 			return inetAddress.s_addr;
// 
// 	#elif defined(WIN32)
// 
// 		WS_IN_ADDR inetAddress;
//         inetAddress.s_addr = inet_addr (pString);			
// 		return inetAddress.s_addr;
// // 		if(INADDR_NONE == inetAddress->s_addr)
// // 			return -1;
// 	//	inetAddress->s_addr = htonl(inetAddress->s_addr);
// // 		return 0;
// 
// 	#elif defined(LINUX) || defined(WSSI_UNIX)  
// 
// 		WS_IN_ADDR inetAddress;
// 		
// 		if(1 == inet_aton(pString,(struct in_addr *)&inetAddress))
// 			return inetAddress.s_addr;
// 		else
// 			return -1;
// 		
// 		//return 1 == inet_aton(pString,(struct in_addr *)&inetAddress) ? 0:-1; 
// 
// 	#else
// 
// 		#error "What is OS type?"
//  
// 	#endif	
// }
// 
// 
// 

int WS_select(int width,fd_set *pReadFds, fd_set *pWriteFds,fd_set *pExceptFds, struct timeval *pTimeOut)
{
#ifdef WIN32
	return select(width,(fd_set*)pReadFds,(fd_set*)pWriteFds,

		(fd_set*)pExceptFds,(struct timeval*)pTimeOut);

#else

	return select(width + 1,(fd_set*)pReadFds,(fd_set*)pWriteFds,
		(fd_set*)pExceptFds,(struct timeval*)pTimeOut);

#endif
}

unsigned short WS_htons(unsigned short host16bitVal)
{
	return(htons(host16bitVal));
}

unsigned int  WS_htonl(unsigned int  host32bitVal)
{
	return(htonl(host32bitVal));
}

unsigned short WS_ntohs(unsigned short net16bitVal)
{
	return(ntohs(net16bitVal)); 
}

unsigned int  WS_ntohl(unsigned int  net32bitVal)
{
	return(ntohl(net32bitVal));
}

unsigned int  WS_ioctl(unsigned int fd, unsigned int request, void *arg)
{
#ifdef WIN32

	return ioctlsocket(fd, request, arg);

#else

	return ioctl(fd, request, arg);

#endif
}

unsigned int  WS_getSocketErr()
{
#ifdef WIN32

	return GetLastError ();

#else

	return errno;

#endif
}

int WS_gethostbyname( const char* ipname,int port,struct sockaddr_in **saddr ,int *count)
{
#ifdef WIN32
	HOSTENT *pHost = NULL;
	if(saddr == NULL || *saddr != NULL)
		return -1;
	pHost = gethostbyname(ipname) ;
	*saddr = (struct sockaddr_in *)malloc(sizeof(struct sockaddr_in));
	if(pHost != NULL && *saddr)
	{
		memcpy(&((*saddr)->sin_addr),pHost->h_addr_list[0],4);
		*count = 1;
		return 0;
	}
#else
	if(saddr == NULL || *saddr != NULL)
		return -1;
	struct addrinfo hints;
	struct addrinfo *result, *rp;

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;    /* Allow IPv4 or IPv6 */
	hints.ai_socktype = SOCK_STREAM; /* Datagram socket */
	hints.ai_flags = 0;
	hints.ai_protocol = 0;          /* Any protocol */
	char pPort[20] = {0};
	sprintf(pPort,"%d",port);
	int s = getaddrinfo(ipname, pPort , &hints, &result);
	if (s != 0) {
		printf("getaddrinfo failed!\n");
		return -1;
	}
	int nCountaddr = 0;
	for (rp = result; rp != NULL; rp = rp->ai_next) {
		nCountaddr++;
	}
	*count = nCountaddr;
	*saddr = (struct sockaddr_in *)malloc(sizeof(struct sockaddr_in)*nCountaddr);
	if(*saddr == NULL)
	{
		freeaddrinfo(result); 
		return -1;
	}
	nCountaddr = 0;
	for (rp = result; rp != NULL; rp = rp->ai_next) {
		memcpy(*saddr+nCountaddr++,rp->ai_addr,sizeof(struct sockaddr));
	}
	freeaddrinfo(result); 
	printf("WS_gethostbyname end!\n");
	return 0;
// 	struct hostent *pHost = gethostbyname(ipname) ;
// 	if(pHost != NULL)
// 	{
// 		memcpy(&saddr->sin_addr,pHost->h_addr_list[0],4);
// // 		struct in_addr **addr_list = (struct in_addr **)pHost->h_addr_list;
// // 		saddr->sin_addr.s_addr = inet_addr(inet_ntoa(*addr_list[0]));
// 		return 0;
// 	}
#endif
	return -1;
}

int WS_setblocking( int sockfd,int bblocking )
{
#ifdef WIN32
	unsigned long noBlocking = 1;
	if(bblocking)
	{
		noBlocking = 0;
		return ioctlsocket(sockfd,FIONBIO,&noBlocking);
	}
	else
	{
		noBlocking = 1;
		return ioctlsocket(sockfd,FIONBIO,&noBlocking);
	}
#else
	if (bblocking)
	{
		if(fcntl(sockfd, F_SETFL, fcntl(sockfd,F_GETFD,0) & (~O_NONBLOCK)) == -1)
		{
			return -1;
		}
	}
	else
	{
		if(fcntl(sockfd, F_SETFL, fcntl(sockfd,F_GETFD,0) | O_NONBLOCK) == -1)
		{
			return -1;
		}
	}
#endif
	return 0;
}

int WS_settimeout(int sockfd,int level,int optname,int timeoutms)
{

#ifdef WIN32
    int temp = timeoutms;
    return 	(0 == setsockopt(sockfd,level,optname,(char*)&temp,sizeof(int))) ? 0 : -1;

#else
    	struct timeval tv_out;
    	tv_out.tv_sec = timeoutms/1000;
    	tv_out.tv_usec = timeoutms%1000;
    	return 	-1 == setsockopt(sockfd,level,optname,(char*)&tv_out,sizeof(struct timeval)) ? -1 : 0;
    

#endif
    
}




