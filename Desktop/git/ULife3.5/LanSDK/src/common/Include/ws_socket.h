#ifndef __WS_SOCKET__H
#define __WS_SOCKET__H


#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifdef WIN32
	#include <winsock2.h>
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <assert.h>
#include <pthread.h>
#include <fcntl.h>
#include <netdb.h>
#endif

	typedef struct  WS_SOCKADDR {
		unsigned short sa_family;              /* address family */
		char    sa_data[14];            /* up to 14 bytes of direct address */
	}  WS_SOCKADDR;

#ifdef WIN32
	typedef struct ws_in_addr {
		union {
			struct { char s_b1,s_b2,s_b3,s_b4; } S_un_b;
			struct { unsigned short s_w1,s_w2; } S_un_w;
			unsigned int S_addr;
		} S_un;
#define s_addr  S_un.S_addr       /* can be used for most tcp & ip code */
#define s_host  S_un.S_un_b.s_b2        /* host on imp */
#define s_net   S_un.S_un_b.s_b1     /* network */
#define s_imp   S_un.S_un_w.s_w2     /* imp */
#define s_impno S_un.S_un_b.s_b4    /* imp # */
#define s_lh    S_un.S_un_b.s_b3
	}WS_IN_ADDR;
#else
	typedef struct ws_in_addr
	{
		unsigned int s_addr;
	}WS_IN_ADDR;

#endif

int WS_socket_init(void);
int WS_socket(int family,int type,int protocol);
int WS_bind(int s,WS_SOCKADDR * addr,int addrlen);
int WS_listen(int s,int backlog);
int WS_accept(int s,WS_SOCKADDR *addr,int  *addrlen);
int WS_connect(int s,WS_SOCKADDR * addr,int addrlen);
int WS_connectWithTimeout(int s,WS_SOCKADDR * addr,int addrlen,struct timeval *  timeVal);
int WS_sendto(int s,char* buf,int bufLen,int flags,WS_SOCKADDR * to,int tolen);
int WS_send(int s,char* buf,int bufLen, int flags);
int WS_recvfrom(int s,char *buf,int bufLen,int flags,WS_SOCKADDR *from,int *pFromLen);
int WS_recv(int s,char * buf,int bufLen,int flags);
int WS_setsockopt(int s,int level,int optname,char *optval,int optlen);
int WS_getsockopt(int s,int level,int optname,char *optval,int *optlen);
int WS_getsockopt(int s,int level,int optname,char *optval,int *optlen);
int WS_getsockname(int s,WS_SOCKADDR *addr,  int *addrlen);
int WS_getpeername(int s,WS_SOCKADDR *name,int *namelen);
int WS_shutdown(int s,int how);
int WS_close(int fd);
int WS_hostGetByName(char * hostname);
int WS_hostGetByAddr(int addr,char *name);
// int WS_sethostname(char * name,int nameLen);
int WS_gethostname(char * name,int nameLen);
// int WS_inet_lnaof(int inetAddress);
char* WS_inet_ntoa(WS_IN_ADDR inetAddress);
// int WS_inet_aton(char *pString);
int WS_select(int width,fd_set *pReadFds, fd_set *pWriteFds,fd_set *pExceptFds, struct timeval *pTimeOut);
unsigned short WS_htons(unsigned short host16bitVal);
unsigned int  WS_htonl(unsigned int  host32bitVal);
unsigned short WS_ntohs(unsigned short net16bitVal);
unsigned int  WS_ntohl(unsigned int  net32bitVal);
unsigned int  WS_ioctl(unsigned int fd, unsigned int request, void *arg);
unsigned int  WS_getSocketErr();
int WS_gethostbyname(const char* ipname,int port,struct sockaddr_in **saddr,int *count);
int WS_setblocking(int sockfd,int bblocking);
int WS_settimeout(int sockfd,int level,int optname,int timeoutms);

#ifdef __cplusplus
}
#endif
#endif

