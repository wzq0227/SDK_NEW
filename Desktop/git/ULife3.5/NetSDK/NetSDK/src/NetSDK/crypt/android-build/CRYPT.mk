CRYPT_PRJT := $(call my-dir)/..

CRYPT_INC :=
CRYPT_INC += $(NETPROSDK_PRJT)

CRYPT_MOD :=
CRYPT_MOD += $(NETPROSDK_PRJT)

CRYPT_SRC_FILES :=
#CRYPT_SRC_FILES += $(wildcard $(foreach EVERY_NETPROSDK_MOD,$(NETPROSDK_MOD),$(EVERY_NETPROSDK_MOD)/*.c $(EVERY_NETPROSDK_MOD)/*.cpp $(EVERY_NETPROSDK_MOD)/*.cxx $(EVERY_NETPROSDK_MOD)/*.cc $(EVERY_NETPROSDK_MOD)/*.s))
CRYPT_SRC_FILES += $(CRYPT_PRJT)/aes256.c
CRYPT_SRC_FILES += $(CRYPT_PRJT)/base64.c
CRYPT_SRC_FILES += $(CRYPT_PRJT)/encrypt.c
CRYPT_SRC_FILES += $(CRYPT_PRJT)/gen_rand.c
CRYPT_SRC_FILES += $(CRYPT_PRJT)/sha256.c