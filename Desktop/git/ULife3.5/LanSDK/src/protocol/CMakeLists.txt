#cmake file for project association #±íÊ¾×¢ÊÍ 
#author:	mr.liubing@gmail.com
#created:	2014-1-18 
PROJECT(Ntp)

MESSAGE(STATUS "Project: Ntp")
MESSAGE(STATUS "Project Directory: ${Ntp_SOURCE_DIR}")

INCLUDE_DIRECTORIES(${poeU5802_SOURCE_DIR}/include)
INCLUDE_DIRECTORIES(${Sysctrl_SOURCE_DIR}/include)
INCLUDE_DIRECTORIES(${Iniparser_SOURCE_DIR}/include)
INCLUDE_DIRECTORIES(${Interface_SOURCE_DIR}/include)
INCLUDE_DIRECTORIES(${Hicommon_SOURCE_DIR}/include)
INCLUDE_DIRECTORIES(${Ntp_SOURCE_DIR}/include)
INCLUDE_DIRECTORIES(${GS_DEVICE_SDK_SOURCE_DIR}/include)

AUX_SOURCE_DIRECTORY(./src DIR_SRCS)

ADD_LIBRARY(Ntp_s STATIC ${DIR_SRCS})
#ADD_LIBRARY(Ntp SHARED ${DIR_SRCS})

SET_TARGET_PROPERTIES(Ntp_s PROPERTIES OUTPUT_NAME "Ntp")

#SET_TARGET_PROPERTIES(Ntp PROPERTIES LIBRARY_OUTPUT_DIRECTORY  "${poeU5802_SOURCE_DIR}/__install/lib")
SET_TARGET_PROPERTIES(Ntp_s PROPERTIES ARCHIVE_OUTPUT_DIRECTORY  "${poeU5802_SOURCE_DIR}/__install/lib")

#INSTALL(FILES 
#		${deviceSDk_SOURCE_DIR}/include/device_info.h  
#		${deviceSDk_SOURCE_DIR}/include/device_sdk.h  
#		${deviceSDk_SOURCE_DIR}/include/SDK_Defs.h 
#		DESTINATION "${my51c_platform_sdk_SOURCE_DIR}/__install/deviceSDk/include")

