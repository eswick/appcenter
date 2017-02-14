
ifdef SIMULATOR
TARGET = simulator:clang
ARCHS = x86_64
else
TARGET = iphone:latest
ARCHS = arm64
endif

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AppCenter
AppCenter_FILES = APCRootListController.m
AppCenter_INSTALL_PATH = /Library/PreferenceBundles
AppCenter_FRAMEWORKS = UIKit
ifdef SIMULATOR
AppCenter_PRIVATE_FRAMEWORKS = Preferences
else
AppCenter_LDFLAGS = -undefined dynamic_lookup
endif

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AppCenter.plist$(ECHO_END)
