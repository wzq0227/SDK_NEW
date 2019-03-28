#APP_STL := stlport_shared
#APP_CPPFLAGS += -frtti

#APP_PLATFORM := android-10
#APP_STL := stlport_static
#STLPORT_FORCE_REBUILD := true

APP_STL := gnustl_static

#APP_CPPFLAGS += -fexceptions

#modified@2016-06-15:steve
#error: format not a string literal and no format arguments [-Werror=format-security]
APP_CFLAGS += -Wno-error=format-security

APP_ABI := armeabi armeabi-v7a
#APP_ABI := all
#APP_ABI := armeabi armeabi-v7a mips x86
