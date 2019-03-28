// JLThreadCtrl.h: interface for the CJLThreadCtrl class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_JLTHREADCTRL_H_JSOCK__E038D85C_E4D1_4414_B4B1_D78EA4273387__INCLUDED_)
#define AFX_JLTHREADCTRL_H_JSOCK__E038D85C_E4D1_4414_B4B1_D78EA4273387__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "EventLock.h"


#if (defined _WIN32) || (defined _WIN64)
	// CJLThreadCtrl 类相关的宏定义 begin
	#define	pthread_t	DWORD
	#define fJThRet		DWORD WINAPI
	typedef HANDLE PJHANDLE;
	// CJLThreadCtrl 类相关的宏定义 end
#else
	// CJLThreadCtrl 类相关的宏定义 begin
	#include <unistd.h>
	#define fJThRet		void*
	// CJLThreadCtrl 类相关的宏定义 end
#endif


typedef fJThRet fcbJThread (void *);

#define		THREAD_STATE_STOP		0x00000000	// 结束
#define		THREAD_STATE_W_STOP		0x00001000	// 等待结束
#define		THREAD_STATE_RUN		0x00000001	// 运行
#define		THREAD_STATE_W_RUN		0x00001001	// 等待运行
#define		THREAD_STATE_PAUSE		0x00000002	// 暂停

#define		THREAD_MAX_WAIT_RET		10			// 最大等待10次
#define		THREAD_PER_WAIT_TIME	40			// 每闪等待的毫秒数

#ifndef		J_DGB_NAME_LEN
#define		J_DGB_NAME_LEN			64
#endif

namespace JSocketCtrl
{
class CJLThreadCtrl  
{
public:
	CJLThreadCtrl(void* pOwner = NULL);
	virtual ~CJLThreadCtrl();

	// 开始线程函数
	HANDLE			StartThread(fcbJThread* pThreadFun);
	// 结束线程函数
	int				StopThread(bool bWaitRet/*=true*/);
	// 暂停线程函数
	int				PauseThread();
	// 继续线程函数
	int				ContinueThread();
	// 获取线程状态
	DWORD			GetThreadState();
	// 通知结束
	void			NotifyStop();

	// 返回下一次需的操作
	// THREAD_STATE_STOP:表示线程应该要结束了;
	// THREAD_STATE_RUN:表示正常运行;
	// THREAD_STATE_PAUSE:表示需要暂停
	DWORD			GetNextAction();

	// 获取相应的句柄
	pthread_t		GetHandle();

	// 设置本变量的参数,供线程函数中调用
	int				SetParam(void* pParam);
	// 获取本变量的参数,供线程函数中调用
	void*			GetParam();
	// 设置本变量的名称,供线程函数中调用
	int				SetName(LPCTSTR lpszName);

	// 设置本变量的所有者(在回调函数中使用)
	int				SetOwner(void* pParam);
	// 获取本变量的所有者(在回调函数中使用)
	void*			GetOwner();

	// 设置线程状态,注意:只是设置相应的状态值,并不做逻辑处理,一般只在线程函数中,设置结束状态
	void			SetThreadState(DWORD dwThreadState);

public:
	char			m_szName[J_DGB_NAME_LEN];	// 名称...调试用
protected:
	pthread_t		m_hThreadID;				// 线程ID
	HANDLE			m_hThread;					// 线程句柄
	DWORD			m_dwThreadState;			// 线程状态
	fcbJThread*		m_pThreadFun;				// 线程函数
	void*			m_pParam;					// 参数(在回调函数中使用)
	void*			m_pOwner;					// 所有者(在回调函数中使用)
//	CEventLock		m_eventStop;				// 停止事件
	CEventLock		m_eventPause;				// 暂停事件
};
}
using namespace JSocketCtrl;

#endif // !defined(AFX_JLTHREADCTRL_H_JSOCK__E038D85C_E4D1_4414_B4B1_D78EA4273387__INCLUDED_)
