/*
NetProSDKAPI.h		
2017.1.17		
wwei
��˹�����Ҿӿ�ƽ̨����Э��SDK API
*/
#ifndef	_NET_PRO_SDK_API_H_
#define _NET_PRO_SDK_API_H_

#if (defined _WIN32) || (defined _WIN64)
#ifdef NETPROSDK_EXPORTS
#define NETPROSDK_API __declspec(dllexport)
#else
#define NETPROSDK_API __declspec(dllimport)
#endif
#elif (defined __APPLE_CPP__) || (defined __APPLE_CC__)
#if defined(__arm__) //debug++
typedef unsigned long       DWORD;
#elif defined(__arm64__)
typedef unsigned int        DWORD;
#endif
#ifdef NETPROSDK_EXPORTS
#define NETPROSDK_API extern "C"
#else
#define NETPROSDK_API
#endif
#else
typedef unsigned long       DWORD; //debug++
#define NETPROSDK_API //extern "C"
#endif	
#define NETPROSDK_VERSION	"V1.0.3.8-20181218"

#include "NetProSDKDef.h"
#include "AVIOCTRLDEFs.h"

// �¼��ص�
typedef long (__stdcall* EventCallBack)(long lHandle, int nDevChn, eNetProParam eParam, long lRet, long lData, long lUserParam);

// ����Ƶ���ص�
typedef long (__stdcall* StreamCallBack)(long lHandle, int nDevChn, unsigned char* pStreamData, DWORD dwSize, long lUserParam);

// ��ʼ��
/*
	��ʼ��ʱ ȷ��Ҫ�õ�Э�飬 ���ߵ�¼������ʱ  ���ݷ�������ַ�Զ��жϸ�������Э��  ������
*/
NETPROSDK_API	long	NetPro_Init();

// ����ʼ��
NETPROSDK_API	long	NetPro_UnInit();

// pServerAddr���ؾ�����ɷ�������ַ�������ַ�Էֺż��
// ���� ������1:������1�˿�; ������2:������2�˿�, 192.168.0.1:9999; 192.168.0.2:9999;
NETPROSDK_API	long	NetPro_SetTransportProType(eNetProTransportProType eProType, char* pServerAddr);

// ��¼�������豸��nProjectType  0.Ĭ��  1.�ŵ���Ŀ 
NETPROSDK_API	long	NetPro_ConnDev(const char* pUID, const char* pUser, const char* pPwd, int nTimeOut, int nProjectType, eNetConnType eConnType, EventCallBack eventCB, long lUserParam);

// �ǳ� (�ر�����)
NETPROSDK_API	long	NetPro_CloseDev(long lConnHandle);

// ��ȡNVRͨ����
NETPROSDK_API	long	NetPro_GetDevChnNum(long lConnHandle);

// ΪNVR���� nNum��ͨ���� ���ش�����ͨ����
NETPROSDK_API	long	NetPro_CreateDevChn(long lConnHandle, int nNum);

// ����豸����  ����ֵ 0����  ��������
NETPROSDK_API	long	NetPro_CheckDevConn(long lConnHandle);

// ���ü���豸����״̬��ʱ���������룩  Ĭ��Ϊ15��
NETPROSDK_API	long	NetPro_SetCheckConnTimeinterval(long lConnHandle, int nMillisecond);

// ������Ƶ��(�Ƿ�ͬʱ����Ƶ����Ƶ��)
NETPROSDK_API	long	NetPro_OpenStream(long lConnHandle, int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam);

// �ر�����Ƶ��
NETPROSDK_API	long	NetPro_CloseStream(long lConnHandle, int nChannel, eNetStreamType eType);

// ��ͣ��������Ƶ���� nPasueFlag = 1 ��ͣ���գ� nPasueFlag = 0 �ָ�����
NETPROSDK_API	long	NetPro_PasueRecvStream(long lConnHandle, int nChannel, int nPasueFlag);

// �л�����
NETPROSDK_API	long	NetPro_SetStream(long lConnHandle, int nChannel, eNetVideoStreamType eType);

// ���ò���   �¼��ص����� ��ͬ���͵��¼�  �����¼�����Ӧ����
NETPROSDK_API	long	NetPro_SetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize);

// ��ȡ����
NETPROSDK_API	long	NetPro_GetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize);

// ¼������
NETPROSDK_API	long	NetPro_RecDownload(long lConnHandle, int nChannel, const char* pFileName, char *pSrcFileName);

// ֹͣ¼������
NETPROSDK_API	long	NetPro_StopDownload(long lConnHandle, int nChannel);

// ɾ��¼���ļ�
NETPROSDK_API	long	NetPro_DelRec(long lConnHandle, int nChannel, const char *pFileName);

// ��ʼ�Խ�
NETPROSDK_API	long	NetPro_TalkStart(long lConnHandle, int nChannel);

// �Խ� ������AAC�ļ��� nNoPlay �� 0 �Խ����� ���� 1 �Զ��屨������
NETPROSDK_API	long	NetPro_TalkSendFile(long lConnHandle, int nChannel, const char *pFileName, int nNoPlay);

// ���ͶԽ�����
NETPROSDK_API	long	NetPro_TalkSend(long lConnHandle, int nChannel, const char* pData, DWORD dwSize);

// �����Խ�
NETPROSDK_API	long	NetPro_TalkStop(long lConnHandle, int nChannel);

// ¼��ط� begin
NETPROSDK_API	long	NetPro_RecStreamPlay(long lConnHandle, const char *pRecName, int nRecNameLen);

// ��ʷ������
NETPROSDK_API	long	NetPro_RecStreamCtrl(long lConnHandle, int nChn, eNetRecCtrlType eCtrlType, long lData);

// ¼��ط� end

#endif





/*// �ͷ���ʷ���ط�ͨ��
NETPROSDK_API	long	NetPro_DeleteRecPlayChn(long lConnHandle, int nChn);*/