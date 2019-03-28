
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
	//注册，用户名，密码，验证地址
	params:
		username:  user name to register
		password: password to register
		evidenceaddr: evidence address,email or phone number
	return:
		On success, 0 is returned. On error , error code is return, you can find it in error code list (EErrorCode)
	*/
	int UM_Register(const char* username,const char* password,const char* evidenceaddr);

	/*
	//登录
	params:
		username:  user name to login
		password: password to login
	return:
		On success, 0 is returned. On error , -1 is returned. the login status is notified by UserManagerMsgCallback
	*/
	int UM_Login(const char* username,const char* password);

	/*
	//验证
	params:
		authcode:  authcode to verify, the step is needed by register or login
	return:
		On success, 0 is returned. On error , error code is return, you can find it in error code list
	*/
	int UM_Verify(const char* authcode);

	/*
	//退出
	params:
		none
	return:
		On success, 0 is returned. On error , -1 is returned.
	*/
	int UM_Logout();

	/*
	//绑定设备
	params:
		devid : device id to bind by current user
	return:
		On success, 0 is returned. On error , error code is return, you can find it in error code list
	*/
	int UM_BindDevice(const char* devid);

	/*
	//解绑设备
	params:
		devid : device id to unbind by current user
	return:
		On success, 0 is returned. On error , error code is return, you can find it in error code list
	*/
	int UM_UnBindDevice(const char* devid);
	
	/*
	//获取设备总数
	params:
		none
	return:
		On success, return device total count. On error, -1 is returned.
	*/
	int UM_GetDeviceListCounts();

	/*
	//获取指定设备信息
	params:
		nIndex: the  index device
	return:
		On success, the specified device information by index is returned. On error, NULL is returned.
	*/
	DeviceInfo* UM_GetDevice(int nIndex);

	int UM_SetDeviceInfo(const char* devid,int cmd,void* param,int len);

//设备搜索模块
	//timeout:搜索超时时间，即函数返回时间，返回搜索到的设备总数
	//camType: 为NULL时，返回所有搜索到的设备类型,不为NULL时，从搜索到的设备中筛选该指定类型的设备返回
	//camType: NULL,"GD845H","5886f"...
	int LanSearchDevice(int timeout,const char* camType);//ms

	//通过索引获取单个设备信息
	DeviceInfo* LanGetDeviceBySearch(int index);

//参数控制模块
	/*
		//通过，IP地址，端口等信息，创建一条参数控制通道，返回可用的通信ID,返回错误的信息参见EErrorCode list
	params:
		addr: 设备ip地址，或服务器ip地址
		port: 通信端口
		devid: 设备ID
		username: 设备认证的用户名
		password: 设备认证的密码
	return: 
		返回可用通道ID，< 0表示错误，参见错误列表
	*/
	int PM_CreateChannel(const char* addr,int port,const char* devid,const char* username, const char* password,MsgCallback msgcallback,	void* popt);

	/*
		//通过通道iD摧毁通道并释放相应资源
	params:
		channelid: 通道ID
	return:
		返回0 表示成功，其他失败
	*/
	int PM_DestroyChannel(int channelid);

	/*
		//通过通道控制设备参数,cmd控制的命令，参见ulifedefines.h的定义；param为对应命令的参数,是结构体形式的
	params:
		channelid: 通道ID
		cmd: 命令，参见PARAM_CONTROL_CMD
		param: 参数，结构体形式
		len: 参数长度
	return:
		返回0 表示成功,其他表示失败
	*/
	int PM_CtrlParam(int channelid,int cmd,void* param,int len);

//获取音视频流模块
	/*
		//根据相关信息创建获取音视频的通道，返回可用通道ID,返回错误的信息参见EErrorCode list
	params:
		addr: 设备ip地址，或服务器ip地址
		port: 通信端口
		devid: 设备ID
		username: 设备认证的用户名
		password: 设备认证的密码
		datacallback: 音视频数据回调
		msgcallback: 消息回调
	return :
	返回通道ID,<0 表示创建失败
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
		//销毁通道，并释放相关资源
		params:
			channelid: 通道ID
		return:
			返回0 表示成功，其他失败
	*/
	int AM_DestroyChannel(int channelid);

	/*
		//打开视频
		params:
			channelid: 通道ID
		return:
			返回0 表示成功，其他失败
	*/
	int AM_OpenVideoStream(int channelid);

	/*
		//关闭视频
		params:
			channelid: 通道ID
		return:
			返回0 表示成功，其他失败
	*/
	int AM_CloseVideoStream(int channelid);

	/*
		//打开音频
		params:
			channelid: 通道ID
		return:
			返回0 表示成功，其他失败
	*/
	int AM_OpenAudioStream(int channelid);

	/*
	//关闭音频
	params:
		channelid: 通道ID
	return:
		返回0 表示成功，其他失败
	*/
	int AM_CloseAudioStream(int channelid);

	/*
	//切换标清,高清
	params:
	channelid: 通道ID
	hd: 1->高清, 0->标清
	return:
	返回0 表示成功，其他失败
	*/
	int AM_SwitchHdBd(int channelid,int hd);
#ifdef __cplusplus
}
#endif




#endif //_LIBULIFE_API_H__
