#cmake file for project association #��ʾע�� 
#author:	mr.liubing@gmail.com
#created:	2014-1-18 
PROJECT(UMment)

MESSAGE(STATUS "Project: UMment")

#set(CMAKE_CXX_COMPILER "aarch64-linux-android-g++")
#set(CMAKE_FIND_ROOT_PATH "/home/steve/tmp/ndk-aarch63-linux-android-4.9")
set(CMAKE_CXX_COMPILER "g++")
set(CMAKE_CXX_FLAGS "-g3 -Wall -fPIC")
set(CMAKE_C_FLAGS "-g3 -Wall -fPIC")
#set(CMAKE_CXX_FLAGS_DEBUG "-g3 -Wall -fPIC")
set(CMAKE_CXX_FLAGS_RELEASE "-O2 -Wall -fPIC")

set(LIBRARY_OUTPUT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../output/linux/lib")
set(GOSSDK_SDK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../userinterface")
set(GOSSDK_COMMON_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../common")
set(GOSSDK_PROTOCOL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../protocol")
#set(GOSSDK_PARAMCTRL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../paramconfig")
set(TINYXML_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../external/tinyxml")
#set(GOSSDK_AVMENT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../avmanagement")
#set(GOSSDK_DSMENT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../devicesearch")
set(GOSSDK_UMMENT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../usermanagement")

MESSAGE(STATUS "Project GOSSDK_UMMENT_DIR Directory: ${GOSSDK_UMMENT_DIR}")
MESSAGE(STATUS "Project TINYXML_DIR Directory: ${TINYXML_DIR}")
MESSAGE(STATUS "Project GOSSDK_COMMON_DIR Directory: ${GOSSDK_COMMON_DIR}")
#MESSAGE(STATUS "Project GOSSDK_AVMENT_DIR Directory: ${GOSSDK_AVMENT_DIR}")
#MESSAGE(STATUS "Project GOSSDK_DSMENT_DIR Directory: ${GOSSDK_DSMENT_DIR}")
MESSAGE(STATUS "Project LIBRARY_OUTPUT_PATH Directory: ${LIBRARY_OUTPUT_PATH}")
MESSAGE(STATUS "Project GOSSDK_PROTOCOL_DIR Directory: ${GOSSDK_PROTOCOL_DIR}")
MESSAGE(STATUS "Project GOSSDK_SDK_DIR Directory: ${GOSSDK_SDK_DIR}")

aux_source_directory(${GOSSDK_SDK_DIR}/Src GOSSDK_SDK_DIR_SRC)
aux_source_directory(${GOSSDK_COMMON_DIR}/Src GOSSDK_COMMON_DIR_SRC)
#aux_source_directory(${GOSSDK_AVMENT_DIR}/Src GOSSDK_AVMENT_DIR_SRC)
#aux_source_directory(${GOSSDK_DSMENT_DIR}/Src GOSSDK_DSMENT_DIR_SRC)
aux_source_directory(${GOSSDK_UMMENT_DIR}/Src GOSSDK_UMMENT_DIR_SRC)
aux_source_directory(${GOSSDK_PROTOCOL_DIR}/Src GOSSDK_PROTOCOL_DIR_SRC)
aux_source_directory(${TINYXML_DIR} TINYXML_DIR_SRC)
#aux_source_directory(${GOSSDK_PARAMCTRL_DIR}/Src GOSSDK_PARAMCTRL_DIR_SRC)


INCLUDE_DIRECTORIES(${GOSSDK_SDK_DIR}/Include)
INCLUDE_DIRECTORIES(${GOSSDK_PROTOCOL_DIR}/Include)
INCLUDE_DIRECTORIES(${GOSSDK_COMMON_DIR}/Include)
INCLUDE_DIRECTORIES(${TINYXML_DIR})
INCLUDE_DIRECTORIES(${GOSSDK_UMMENT_DIR}/Include)


list(APPEND GOSSDK_UMMENT_DIR_SRC ${TINYXML_DIR_SRC})
list(APPEND GOSSDK_UMMENT_DIR_SRC ${GOSSDK_COMMON_DIR_SRC})
list(APPEND GOSSDK_UMMENT_DIR_SRC ${GOSSDK_PROTOCOL_DIR_SRC})

ADD_LIBRARY(UMment_s STATIC ${GOSSDK_UMMENT_DIR_SRC})
#ADD_LIBRARY(Ntp SHARED ${DIR_SRCS})

SET_TARGET_PROPERTIES(UMment_s PROPERTIES OUTPUT_NAME "UMment")

#SET_TARGET_PROPERTIES(Ntp PROPERTIES LIBRARY_OUTPUT_DIRECTORY  "${LIBRARY_OUTPUT_PATH}")
SET_TARGET_PROPERTIES(UMment_s PROPERTIES ARCHIVE_OUTPUT_DIRECTORY  "${LIBRARY_OUTPUT_PATH}")


