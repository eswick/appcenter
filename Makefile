TARGET = simulator:clang:10.1
ARCHS = x86_64 i386

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppCenter
AppCenter_FILES = Tweak.xm
AppCenter_PRIVATE_FRAMEWORKS = ControlCenterUI
AppCenter_INSTALL_PATH = /opt/simject
AppCenter_USE_SUBSTRATE = 1
AppCenter_CFLAGS = -Iclassdefs

include $(THEOS_MAKE_PATH)/tweak.mk

after-AppCenter-all::
	ldid -S $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT)

after-install::
	install.exec "killall -9 SpringBoard"
