GOSCAM_PRJT := $(call my-dir)/..

GOSCAM_INC :=
GOSCAM_INC += $(GOSCAM_PRJT)



GOSCAM_MOD :=
GOSCAM_MOD += $(GOSCAM_PRJT)

GOSCAM_SRC_FILES :=
GOSCAM_SRC_FILES += $(wildcard $(foreach EVERY_GOSCAM_MOD,$(GOSCAM_MOD),$(EVERY_GOSCAM_MOD)/*.c $(EVERY_GOSCAM_MOD)/*.cpp $(EVERY_GOSCAM_MOD)/*.cxx $(EVERY_GOSCAM_MOD)/*.cc $(EVERY_GOSCAM_MOD)/*.s))