
ifdef SIMULATOR
TARGET = simulator:clang
ARCHS = x86_64 i386
else
TARGET = iphone:latest
ARCHS = armv7 arm64
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppCenter
AppCenter_FILES = Tweak.xm SelectionPage.xm UIImage+Tint.m ManualLayout.xm

ifdef SIMULATOR
AppCenter_INSTALL_PATH = /opt/simject
AppCenter_PRIVATE_FRAMEWORKS = ControlCenterUI ControlCenterUIKit FrontBoardServices
else
AppCenter_LDFLAGS = -undefined dynamic_lookup
endif

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += appcenterprefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-AppCenter-all::
	ldid -S $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT)

after-install::
	install.exec "killall -9 SpringBoard"
