TUTK_PRJT := $(call my-dir)/..

TUTK_INC :=
TUTK_INC += $(TUTK_PRJT)
TUTK_INC += $(TUTK_PRJT)/inc
TUTK_INC += $(TUTK_PRJT)/inc/P2PCam


TUTK_MOD :=
TUTK_MOD += $(TUTK_PRJT)

TUTK_SRC_FILES :=
TUTK_SRC_FILES += $(wildcard $(foreach EVERY_TUTK_MOD,$(TUTK_MOD),$(EVERY_TUTK_MOD)/*.c $(EVERY_TUTK_MOD)/*.cpp $(EVERY_TUTK_MOD)/*.cxx $(EVERY_TUTK_MOD)/*.cc $(EVERY_TUTK_MOD)/*.s))