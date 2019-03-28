#ifndef _DEBUG_PRINT_H_
#define _DEBUG_PRINT_H_

#include <stdio.h>


#ifdef __ANDROID__
#include <android/log.h>
#define ULIFE_SDI_LOG_TAG "ULIFE_WLAN_SDK"
#define pr_debug(...)	__android_log_print(ANDROID_LOG_DEBUG,ULIFE_SDI_LOG_TAG,__VA_ARGS__)
#elif WIN32
#define pr_debug(fmt,...) printf(fmt,##__VA_ARGS__)
#else
#define pr_debug(fmt,args...) printf(fmt,##args)
#endif
// #define pr_debug(fmt,args...) printf("\n"fmt,##args)
// #define pr_debug(fmt,args...) printf("\nFile:<%s> Fun:[%s] line:%d "fmt,__FILE__,__FUNCTION__,__LINE__,##args)


#endif