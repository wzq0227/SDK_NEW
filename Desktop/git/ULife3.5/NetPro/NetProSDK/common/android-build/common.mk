COMMON_PRJT := $(call my-dir)/..

COMMON_INC :=
COMMON_INC += $(COMMON_PRJT)

COMMON_MOD :=
COMMON_MOD += $(COMMON_PRJT)

COMMON_SRC_FILES :=
COMMON_SRC_FILES += $(wildcard $(foreach EVERY_COMMON_MOD,$(COMMON_MOD),$(EVERY_COMMON_MOD)/*.c $(EVERY_COMMON_MOD)/*.cpp $(EVERY_COMMON_MOD)/*.cxx $(EVERY_COMMON_MOD)/*.cc $(EVERY_COMMON_MOD)/*.s))