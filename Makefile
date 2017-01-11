
ifdef SIMULATOR
TARGET = simulator:clang
ARCHS = x86_64 i386
else
TARGET = iphone:latest
ARCHS = armv7 arm64
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppCenter
AppCenter_FILES = Tweak.xm SelectionPage.xm
AppCenter_PRIVATE_FRAMEWORKS = ControlCenterUI ControlCenterUIKit FrontBoardServices

ifdef SIMULATOR
AppCenter_INSTALL_PATH = /opt/simject
endif

include $(THEOS_MAKE_PATH)/tweak.mk

after-AppCenter-all::
	ldid -S $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT)

after-install::
	install.exec "killall -9 SpringBoard"
