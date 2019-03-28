
#ifndef _LIBULIFE_API_H__
#define _LIBULIFE_API_H__

#ifdef __cplusplus
extern "C"{
#endif
#include "UlifeDefines.h"

	int Init_Sdk();
	int Release_Sdk();
//user management
	/*
	params:
		msgcallback: message callback function
	return:
		On success, 0 is returned. On error , -1 is returned
	*/
	int UM_SetCallbak(UMMsgCallback msgcallback);

	/*
	//ע�ᣬ�û��������룬��֤��ַ
	params:
		username:  user name to register
		password: password to register
		evidenceaddr: evidence address,email or phone number
	return:
		On success, 0 is returned. On error , error code is return, you can find it in error code list (EErrorCode)
	*/
	int UM_Register(const char* username,const char* password,const char* evidenceaddr);

	/*
	//��¼
	params:
		username:  user name to login
		password: password to login
	return:
		On success, 0 is returned. On error , -1 is returned. the login status is notified by UserManagerMsgCallback
	*/
	int UM_Login(const char* username,const char* password);

	/*
	//��֤
	params:
		authcode:  authcode to verify, the step is needed by register or login
	return:
		On success, 0 is returned. On error , error code is return, you can find it in error code list
	*/
	int UM_Verify(const char* authcode);

	/*
	//�˳�
	params:
		none
	return:
		On success, 0 is returned. On error , -1 is returned.
	*/
	int UM_Logout();

	/*
	//���豸
	params:
		devid : device id to bind by current user
	return:
		On success, 0 is returned. On error , error code is return, you can find it in error code list
	*/
	int UM_BindDevice(const char* devid);

	/*
	//����豸
	params:
		devid : device id to unbind by current user
	return:
		On success, 0 is returned. On error , error code is return, you can find it in error code list
	*/
	int UM_UnBindDevice(const char* devid);
	
	/*
	//��ȡ�豸����
	params:
		none
	return:
		On success, return device total count. On error, -1 is returned.
	*/
	int UM_GetDeviceListCounts();

	/*
	//��ȡָ���豸��Ϣ
	params:
		nIndex: the  index device
	return:
		On success, the specified device information by index is returned. On error, NULL is returned.
	*/
	DeviceInfo* UM_GetDevice(int nIndex);

	int UM_SetDeviceInfo(const char* devid,int cmd,void* param,int len);

//�豸����ģ��
	//timeout:������ʱʱ�䣬����������ʱ�䣬�������������豸����
	//camType: ΪNULLʱ�������������������豸����,��ΪNULLʱ�������������豸��ɸѡ��ָ�����͵��豸����
	//camType: NULL,"GD845H","5886f"...
	int LanSearchDevice(int timeout,const char* camType);//ms

	//ͨ��������ȡ�����豸��Ϣ
	DeviceInfo* LanGetDeviceBySearch(int index);

//��������ģ��
	/*
		//ͨ����IP��ַ���˿ڵ���Ϣ������һ����������ͨ�������ؿ��õ�ͨ��ID,���ش������Ϣ�μ�EErrorCode list
	params:
		addr: �豸ip��ַ���������ip��ַ
		port: ͨ�Ŷ˿�
		devid: �豸ID
		username: �豸��֤���û���
		password: �豸��֤������
	return: 
		���ؿ���ͨ��ID��< 0��ʾ���󣬲μ������б�
	*/
	int PM_CreateChannel(const char* addr,int port,const char* devid,const char* username, const char* password,MsgCallback msgcallback,	void* popt);

	/*
		//ͨ��ͨ��iD�ݻ�ͨ�����ͷ���Ӧ��Դ
	params:
		channelid: ͨ��ID
	return:
		����0 ��ʾ�ɹ�������ʧ��
	*/
	int PM_DestroyChannel(int channelid);

	/*
		//ͨ��ͨ�������豸����,cmd���Ƶ�����μ�ulifedefines.h�Ķ��壻paramΪ��Ӧ����Ĳ���,�ǽṹ����ʽ��
	params:
		channelid: ͨ��ID
		cmd: ����μ�PARAM_CONTROL_CMD
		param: �������ṹ����ʽ
		len: ��������
	return:
		����0 ��ʾ�ɹ�,������ʾʧ��
	*/
	int PM_CtrlParam(int channelid,int cmd,void* param,int len);

//��ȡ����Ƶ��ģ��
	/*
		//���������Ϣ������ȡ����Ƶ��ͨ�������ؿ���ͨ��ID,���ش������Ϣ�μ�EErrorCode list
	params:
		addr: �豸ip��ַ���������ip��ַ
		port: ͨ�Ŷ˿�
		devid: �豸ID
		username: �豸��֤���û���
		password: �豸��֤������
		datacallback: ����Ƶ���ݻص�
		msgcallback: ��Ϣ�ص�
	return :
	����ͨ��ID,<0 ��ʾ����ʧ��
	*/
	int AM_CreateChannel(	const char* addr,
															int port,
															const char* devid,
															const char* username, 
															const char* password,
															AvDataCallback datacallback,
															MsgCallback msgcallback,
															void* popt);

	/*
		//����ͨ�������ͷ������Դ
		params:
			channelid: ͨ��ID
		return:
			����0 ��ʾ�ɹ�������ʧ��
	*/
	int AM_DestroyChannel(int channelid);

	/*
		//����Ƶ
		params:
			channelid: ͨ��ID
		return:
			����0 ��ʾ�ɹ�������ʧ��
	*/
	int AM_OpenVideoStream(int channelid);

	/*
		//�ر���Ƶ
		params:
			channelid: ͨ��ID
		return:
			����0 ��ʾ�ɹ�������ʧ��
	*/
	int AM_CloseVideoStream(int channelid);

	/*
		//����Ƶ
		params:
			channelid: ͨ��ID
		return:
			����0 ��ʾ�ɹ�������ʧ��
	*/
	int AM_OpenAudioStream(int channelid);

	/*
	//�ر���Ƶ
	params:
		channelid: ͨ��ID
	return:
		����0 ��ʾ�ɹ�������ʧ��
	*/
	int AM_CloseAudioStream(int channelid);
#ifdef __cplusplus
}
#endif




#endif //_LIBULIFE_API_H__