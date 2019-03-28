#include "QuickSocket.h"
#include "WlanDeviceSearch.h"
#include <string.h>
#include <ctype.h>

#if defined(WIN32)
#include <winsock2.h>
#include <time.h>
#else
#include "ws_socket.h"
#include <time.h>
#include <sys/file.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <errno.h>
#endif	

#define DEVICE_SETPORT_default 8628
#define DEVICE_GETPORT_default 8629
#define MAX_DEVICE_COUNTS 25

int m_udpserversock = -1;
int g_devicecounts = 0;
DeviceInfo* g_deviceinfo[MAX_DEVICE_COUNTS] = {0};
char g_camType[128] = {0};

DeviceInfo* FindIsInList(char* devID)
{
	int i = 0;
	for ( i = 0; i < g_devicecounts; i++)
	{
		if (g_deviceinfo[i] != NULL)
		{
			if(strcmp(devID,g_deviceinfo[i]->szDevID) == 0)
			return g_deviceinfo[i];
		}
	}
	return NULL;
}

void ToLower(char *psrc,char* pdst)
{
	int i = 0;
	if(psrc == NULL || pdst == NULL)
		return ;
	for(i = 0; i < strlen(psrc); i++)
		pdst[i] = tolower(psrc[i]);
}

void ClearList()
{
	int i = 0;
	for ( i = 0; i < MAX_DEVICE_COUNTS; i++)
	{
		if (g_deviceinfo[i] != NULL)
		{
			free(g_deviceinfo[i]);
			g_deviceinfo[i] = NULL;
		}
	}
	g_devicecounts = 0;
}

void Broadcast2SearchLanDevs()
{
	CamNetParam Infos={0} ;
	Infos.nCmd = 0x66 ;
	strcpy(Infos.szPacketFlag,"GosGet") ;
	QuickSendToUDP(DEVICE_SETPORT_default,(char *)&Infos,sizeof(CamNetParam),0,NULL) ;
	printf("Broadcast2SearchLanDevs complete!\n");
}

int WlanDevSearchInit(const char* camType)
{
	if (camType != NULL)
	{
		memset(g_camType,0,sizeof(g_camType));
		strcpy(g_camType,camType);
	}
	StartUpSock();
	m_udpserversock = QuickStartUDPServer(DEVICE_GETPORT_default,1);
	g_devicecounts = 0;
	return 0;
}

void WlanDevSearchUnInit()
{
	StopSocket(m_udpserversock);
	m_udpserversock = -1;
	g_devicecounts = 0;
	ClearList();
}

int WlanDevSearchSearch(int timeout)
{
	int i;
	if (m_udpserversock == -1)
	{
		m_udpserversock = QuickStartUDPServer(DEVICE_GETPORT_default,1);	
	}

	if (m_udpserversock == -1)
	{
		return -1;
	}

	ClearList();

	for (i = 0; i < 1; i++) //4=>1
	{
		Broadcast2SearchLanDevs();
	}

	while (1)
	{
		CamNetParam  info    = {0} ;
		struct sockaddr_in  AddrFrom = {0} ;
		char szAddrFrom[32]={0};

		memset(&info,0,sizeof(CamNetParam));
		memset(szAddrFrom,0,sizeof(struct sockaddr_in));
		if (ForceRecv(m_udpserversock,(char *)&info,sizeof(CamNetParam),timeout,1,&AddrFrom) > 0)
		{
			printf("WlanDevSearchSearch recv infos\n");
			if(0x67 == info.nCmd)			// 返回设备信息
			{
				DeviceInfo* pLDev = NULL;
				
				strcpy(szAddrFrom,inet_ntoa(AddrFrom.sin_addr));
				strcpy(info.szRemoteIP,szAddrFrom);

				if(strcmp(szAddrFrom,info.szWiFiIP) == 0)
					info.uNicType = 1;
				else if (strcmp(szAddrFrom,info.szDeviceIP)==0)
					info.uNicType = 0;
				else if (strcmp(szAddrFrom,"192.168.200.200")==0)
					info.uNicType = 1;
				else                   //lan dhcp fail
				{
					info.uNicType = 0;
				}
				
				if(strcmp(g_camType,"") != 0)
				{
					char pCamType[128] = {0};
					char pCmpCamType[128] = {0};
					ToLower(g_camType,pCmpCamType);
					ToLower(info.szDeviceType,pCamType);
					if (strcmp(pCmpCamType,pCamType) != 0)
					{
						continue;
					}
				}

				pLDev = FindIsInList(info.szDevID);
				if(pLDev == NULL)
				{
					pLDev= (DeviceInfo*)malloc(sizeof(DeviceInfo));
					if(pLDev)
					{
						memset(pLDev,0,sizeof(DeviceInfo));
						g_deviceinfo[g_devicecounts++] = pLDev;
					}
				}

				if(pLDev)
				{
					memset(pLDev,0,sizeof(DeviceInfo));
					pLDev->dwStatus = 2;
					pLDev->bIsGroup = 0;
					pLDev->nettype = info.uNicType;
					strcpy(pLDev->szSWVer,info.szCameraVer);
					strcpy(pLDev->szDevID,info.szDevID);
					strcpy(pLDev->szDeviceIP,szAddrFrom);
					strcpy(pLDev->szDevName,info.szDeviceName);
					strcpy(pLDev->szDeviceType,info.szDeviceType);
					memcpy(pLDev->szMacAddr_LAN,info.szMacAddr_LAN,sizeof(info.szMacAddr_LAN));
					strcpy(pLDev->szWiFiSSID,info.szWiFiSSID);
					strcpy(pLDev->szWiFiPwd,info.szWiFiPwd);
					printf("current recv ybind = %d\n",info.ybind);
					pLDev->ybindFlag = info.ybind;
				}
				if(g_devicecounts >= MAX_DEVICE_COUNTS)
					break;
			}
		}
		else
		{
			printf("WlanDevSearchSearch recv infos failed\n");		
			break;
		}
	}
	return g_devicecounts;
}

DeviceInfo* WlanDevSearchGetDeviceByIndex(int nIndex)
{
	if (nIndex < g_devicecounts)
	{
		return g_deviceinfo[nIndex];
	}
	else
	{
		return NULL;
	}
}
