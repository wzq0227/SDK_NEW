#ifndef _NETPRO_SDK_DEF_H_
#define _NETPRO_SDK_DEF_H_

#if (defined _WIN32) || (defined _WIN64)
#include "StdAfx.h"
#else
//typedef unsigned long       DWORD;
#ifndef	__stdcall
#define __stdcall
#endif
#endif


// ����Э������ begin
typedef enum
{
	NETPRO_USE_TUTK				= 0,	// TUTK Э��
	NETPRO_USE_4_0				= 1,	// 4.0
}eNetProType;
// ����Э������ end

// ����Э������ begin
typedef enum
{
	NETPRO_ENABLE_ALL			= 0,	// ��������
	NETPRO_ONLY_P2P,					// ֻ��
	NETPRO_ONLY_RELAY,					// ֻת��
}eNetProTransportProType;
// ����Э������ end

// �����豸�������� begin
typedef enum
{
	NETPRO_STREAM_HD			= 0x00,	// ����
	NETPRO_STREAM_SD			= 0x01,	// ����
}eNetVideoStreamType;
// �����豸�������� end

// �����豸�������� begin
typedef enum
{
	NETPRO_CONNECT_TUTK			= 0x01,	// TUTK
	NETPRO_CONNECT_4_0_P2P		= 0x02,	// 4.0 p2p
	NETPRO_CONNECT_4_0_TCP		= 0x03,	// 4.0 tcp
}eNetConnType;
// �����豸�������� end

// �����ȡ�豸������ begin
typedef enum
{
	NETPRO_STREAM_VIDEO			= 0x00,	// ��Ƶ��
	NETPRO_STREAM_AUDIO			= 0x01,	// ��Ƶ��
	NETPRO_STREAM_ALL			= 0x02,	// ����Ƶ��
	NETPRO_STREAM_LIVE			= 0x03, // ֱ���� 4.0
	NETPRO_STREAM_REC			= 0x04, // ��ʱ��
}eNetStreamType;
// �����ȡ�豸������ end

// ������ʷ������ begin
typedef enum
{
	NETPRO_RECSTREAM_PAUSE		= 0x00,	// ��ͣ
	NETPRO_RECSTREAM_RESUME		= 0x01,	// �ָ�����
	NETPRO_RECSTREAM_SEEK		= 0x02,	// ���㲥��
	NETPRO_RECSTREAM_STOP		= 0x03,	// ֹͣ����
}eNetRecCtrlType;
// ������ʷ�� end



// ��������������� begin
typedef enum 
{	
	// �¼�����  ********************************************
	NETPRO_EVENT_CONN_SUCCESS	= 0,	// �����豸�ɹ�

	NETPRO_EVENT_CONN_ERR,				// �����豸ʧ��

	NETPRO_EVENT_OPENSTREAM_RET,		// ����״̬

	NETPRO_EVENT_CLOSESTREAM_RET,		// �ر���״̬

	NETPRO_EVENT_REC_DOWNLOAD_RET,		// ��ʼ����״̬ �ص�lRet=0 ��ʼ���سɹ���lRet > 0���������ļ����ܳ��ȣ� else��Ӧ������:NetProErr_DOWNLOADERR ȡlDataֵ -1 û�и��ļ��� -2 �����û�����������

	NETPRO_EVENT_REC_DOWNLOADING,		// �����У��ص�lRet�������ؽ���

	NETPRO_EVENT_REC_DOWNLOAD_SUCCESS,	// �������

	NETPRO_EVENT_SET_STREAM,			// �л����� �ص�lRet����0 �ɹ�

	NETPRO_EVENT_DEL_REC,				// ɾ��¼���ļ� �ص�lRet����0 �ɹ�

	NETPRO_EVENT_TALK,					// �Խ�  lRet 0�򿪶Խ��ɹ�,  else��Ӧ������ 

	NETPRO_EVENT_TALK_SENDFILE_SUCCESS, // �Խ� �����ļ��ɹ��¼�

	NETPRO_EVENT_LOSTCONNECTION,		// �豸����

	NETPRO_EVENT_RET_DEVCHN_NUM,		// �����豸ͨ������ lRet ����ͨ������

	NETPRO_EVENT_CREATE_REC_PLAYCHN,	// ����¼��ط�ͨ���� lRet ����ͨ�� else��Ӧ������

	NETPRO_PARAM_CTRLT_NVR_REC,			// NVR¼������¼�  SMsgAVIoctrlPlayRecordResp
	
	NETPRO_EVENT_GET_LIGHTSTATE,		// �ŵ�״̬, lRet ���� 

	NETPRO_EVENT_UPLOAD_AUDIOFILE,		// (�ϴ��Զ��屨������)�����ϴ��ļ�����, lRet ���أ�С�� 0 ��Ӧ������

	
	// ��������  ********************************************  ���ò��� ͨ���ص�lRet�ж��Ƿ�ɹ� 0 �ɹ�
	NETPRO_PARAM_GET_ANDROIDALARM = 100,// ��׿��������		SMsgAVIoctrlSendAndriodAlarmMsg

	NETPRO_PARAM_GET_DEVCAP	,			// �豸������		�ص���lRet=101��һ��������SMsgAVIoctrlGetDeviceAbilityResp, lRet=102�ڶ���������T_SDK_DEVICE_ABILITY_INFO1, lRet=103������������T_SDK_DEVICE_ABILITY_INFO2

	NETPRO_PARAM_GET_DEVINFO,			// �豸��Ϣ			SMsgAVIoctrlGetAllParamResq

	NETPRO_PARAM_GET_DEVPWD,			// ��ȡ�豸����		SMsgAVIoctrlGetDeviceAuthenticationInfoResp

	NETPRO_PARAM_SET_DEVPWD,			// �����豸����		SMsgAVIoctrlGetDeviceAuthenticationInfoResp

	NETPRO_PARAM_PTZ,					// ��̨����			SMsgAVIoctrlPtzCmd

	NETPRO_PARAM_GET_STREAMQUALITY,		// ��ȡ��Ƶ����		�ص����� eNetVideoStreamType

	NETPRO_PARAM_SET_REC,				// ����¼��			SMsgAVIoctrlManualRecordReq

	NETPRO_PARAM_GET_VIDEOMODE,			// ��ȡ��Ƶģʽ		SMsgAVIoctrlSetVideoModeReq

	NETPRO_PARAM_SET_VIDEOMODE,			// ������Ƶģʽ		SMsgAVIoctrlSetVideoModeReq

	NETPRO_PARAM_GET_MOTIONDETECT,		// ��ȡ�ƶ����		SMsgAVIoctrlSetMotionDetectReq

	NETPRO_PARAM_SET_MOTIONDETECT,		// �����ƶ����		SMsgAVIoctrlSetMotionDetectReq

	NETPRO_PARAM_GET_PIRDETECT,			// ��ȡ�������		SMsgAVIoctrlSetPirDetectReq

	NETPRO_PARAM_SET_PIRDETECT,			// ���ú������		SMsgAVIoctrlSetPirDetectReq

	NETPRO_PARAM_SET_AUDIOALARM,		// ������������		SMsgAVIoctrlSetAudioAlarmReq   ��ȡ��ͨ������������

	NETPRO_PARAM_GET_ALARMCONTROL,		// ��ȡһ������		SMsgAVIoctrlSetAlarmControlReq

	NETPRO_PARAM_SET_ALARMCONTROL,		// ����һ������		SMsgAVIoctrlSetAlarmControlReq

	NETPRO_PARAM_GET_RECMONTHLIST,		// ��ȡ¼�������б� ������SMsgAVIoctrlGetMonthEventListReq�����أ�SMsgAVIoctrlGetMonthEventListResp

	NETPRO_PARAM_GET_RECLIST,			// ��ȡĳ��¼���б� ������SMsgAVIoctrlGetDayEventListReq�� ���أ�SMsgAVIoctrlGetDayEventListResp

	NETPRO_PARAM_GET_NVR_REC,			// ��ȡNVR¼��		������GOS_V_SearchFileRequest�� ���أ�GOS_V_FileCountInfo+GOS_V_FileInfo

	NETPRO_PARAM_GET_SDINFO,			// ��ȡSD����Ϣ		SMsgAVIoctrlGetStorageInfoResp

	NETPRO_PARAM_SET_SDFORMAT,			// ��ʽ��SD��		SMsgAVIoctrlFormatStorageReq

	NETPRO_PARAM_GET_WIFIINFO,			// ��ȡWIFI����		SMsgAVIoctrlGetWifiResp

	NETPRO_PARAM_SET_WIFIINFO,			// ����WIFI����		SMsgAVIoctrlSetWifiReq

	NETPRO_PARAM_GET_TEMPERATURE,		// ��ȡ�¶ȱ������� SMsgAVIoctrlGetTemperatureAlarmParamResp

	NETPRO_PARAM_SET_TEMPERATURE,		// �����¶ȱ������� SMsgAVIoctrlSetTemperatureAlarmParamReq

	NETPRO_PARAM_GET_TIMEINFO,			// ��ȡ�豸ʱ����� SMsgAVIoctrlGetTimeParamResp

	NETPRO_PARAM_SET_TIMEINFO,			// �����豸ʱ����� SMsgAVIoctrlSetTimeParamReq

	NETPRO_PARAM_SET_UPDATE,			// ��������  SMsgAVIoctrlSetUpdateReq

	NETPRO_PARAM_SET_LIGHT,				// ���õƿ���    SMsgAVIoctrlSetLightReq

	NETPRO_PARAM_GET_LIGHTTIME,			// ��ȡ����ʱ��	 SMsgAVIoctrlGetLightTimeResp

	NETPRO_PARAM_SET_LIGHTTIME,			// ���õ���ʱ��	 SMsgAVIoctrlSetLightTimeReq

	NETPRO_PARAM_DEV_RESET,				// �ָ���������  NULL

	NETPRO_PARAM_SET_MOBILE_CLENT_TYPE, // ��׿�ֻ��ͻ�����λ���� SMsgAVIoctrlSetAndriodAlarmMsgReq 

	NETPRO_PARAM_GET_CAMEREA_STATUS,	// ��ȡ����״̬

	NETPRO_PARAM_SET_LOCAL_STORE_CFG,	// �ƴ洢���ش洢���� SMsgAVIoctrlPlayRecordReq, ���أ�SMsgAVIoctrlPlayPreviewResp

	NETPRO_PARAM_SET_LOCAL_STORE_STOP,  // ֹͣԤ����ʷ������

	NETPRO_PRRAM_GET_AI_INFO,			// ��ȡAI���� SAiInfo

	NETPRO_PRRAM_TEST_AI_SERVER,
}eNetProParam;
// ��������������� end



// ��������� begin
typedef enum
{
	NetProErr_Success			= 0,			// �ɹ�
	NetProErr_Param				= -1000,		// ��������
	NetProErr_Init				= -1001,		// ��ʼ��ʧ��
	NetProErr_UnInit			= -1002,		// δ��ʼ��
	NetProErr_Pro				= -1003,		// Э�����
	NetProErr_GetChannel		= -1004,		// ��ȡ����ͨ������
	NetProErr_Conn				= -1005,		// ���Ӵ���
	NetProErr_NoConn			= -1006,		// δ�����豸
	NetProErr_OpenStream		= -1007,		// ����ʧ��
	NetProErr_CloseStream		= -1008,		// �ر���ʧ��
	NetProErr_PARAMTYPE			= -1009,		// �������ʹ���
	NetProErr_GETPARAM			= -1010,		// ��ȡ��������
	NetProErr_SETPARAM			= -1011,		// ���ò�������
	NetProErr_OPENFILE			= -1012,		// ����¼����ļ�ʧ��
	NetProErr_GETMODE			= -1013,		// ��ȡ���ӷ�ʽʧ��
	NetProErr_DOWNLOADTimeOut	= -1014,		// ��ʼ����¼��ʱ
	NetProErr_DOWNLOADERR		= -1015,		// ��ʼ����ʧ��
	NetProErr_DOWNLOADINGERR	= -1016,		// ������ʧ��
	NetProErr_DOWNLOADING		= -1017,		// �Ѿ�������¼��
	NetProErr_OPENTALKERR		= -1018,		// �򿪶Խ�ʧ��
	NetProErr_TALKERR			= -1019,		// �Խ�ʧ��
	NetProErr_OPENVIDEO			= -1020,		// ����Ƶʧ��
	NetProErr_OPENAUDIO			= -1021,		// ����Ƶʧ��
	NetProErr_UnKnowCHNNun		= -1022,		// δ֪ͨ����
	NetProErr_CreateCHN			= -1023,		// ����ͨ��ʧ��
	NetProErr_UseErrChn			= -1024,		// ʹ����δ��ͨͨ��
	NetProErr_CreateRecPlyChn	= -1025,		// ����¼��ط�ͨ��ʧ��,�������ļ����ִ������������
	NetProErr_NoFreeChannel		= -1026,		// ����¼��ط�ͨ��, û�п���ͨ��
	NetProErr_CtrlRecStream		= -1027,		// ��ʷ������ʧ��
	NetProErr_CreateRecPlyChnING= -1028,		// ���ڴ���¼��ط�ͨ��
	NetProErr_OpenStreamPwdErr	= -1029,		// �����������
	NetProErr_TransPortCreateErr= -1030,		// ����TURN������ʧ�ܻ�δ����
	NetProErr_TransPortCreate	= -1031,		// ����TURN������δ����
	NetProErr_HasConnect		= -1032,		// ������
	NetProErr_NoConnChn			= -1033,		// ͨ��δ����
	NetProErr_NotConnStreamServer=-1034,		// ������δ����
	NetProErr_SetAlarmAudio		 =-1035,		// ���ñ�������ʧ��
	NetProErr_TUTKMaxConn		 =-1036,		// tutk�����������
}eNetProErr;
// ��������� end

#endif