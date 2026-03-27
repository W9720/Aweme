#
#  DYYY
#
#  Copyright (c) 2024 huami. All rights reserved.
#  Channel: @huamidev
#  Created on: 2024/10/04
#
-include Makefile.local

# 强制使用 14.5 SDK 进行编译，以兼容 WSL 里的旧版 Clang 工具链
TARGET = iphone:clang:14.5:14.0
ARCHS = arm64 arm64e

# 根据参数选择打包方案
ifeq ($(SCHEME),roothide)
    export THEOS_PACKAGE_SCHEME = roothide
else ifeq ($(SCHEME),rootless)
    export THEOS_PACKAGE_SCHEME = rootless
else
    unexport THEOS_PACKAGE_SCHEME
endif

ifeq ($(GITHUB_ACTIONS),true)
    export INSTALL = 0
    export FINALPACKAGE = 1
endif

export DEBUG = 0
INSTALL_TARGET_PROCESSES = Aweme

GO_EASY_ON_ME = 1
export ERROR_ON_WARNINGS = 0
export TARGET_HAS_APPSnippets = 0
# --- 关键修复区域：移除 -fno-modules，改用正确的标准库路径 ---
# 我们需要告诉编译器，不要用 toolchain 里的破旧库，去用系统的标准库
ADDITIONAL_CFLAGS += -I$(THEOS)/sdks/iPhoneOS14.5.sdk/usr/include/c++/v1
ADDITIONAL_OBJCFLAGS += -I$(THEOS)/sdks/iPhoneOS14.5.sdk/usr/include/c++/v1
ADDITIONAL_CXXFLAGS += -stdlib=libc++
ADDITIONAL_OBJCCXXFLAGS += -stdlib=libc++
# -----------------------------------------------------------

include $(THEOS)/makefiles/common.mk
TWEAK_NAME = DYYY

DYYY_FILES = DYYY.xm DYYYFloatClearButton.xm DYYYFloatSpeedButton.m DYYYSettings.xm DYYYABTestHook.xm DYYYLongPressPanel.xm DYYYSettingsHelper.m DYYYImagePickerDelegate.m DYYYBackupPickerDelegate.m DYYYSettingViewController.m DYYYBottomAlertView.m DYYYCustomInputView.m DYYYOptionsSelectionView.m DYYYIconOptionsDialogView.m DYYYAboutDialogView.m DYYYKeywordListView.m DYYYFilterSettingsView.m DYYYConfirmCloseView.m DYYYToast.m DYYYManager.m DYYYUtils.m CityManager.m AWMSafeDispatchTimer.m DYYYAudioManager.m DYYYVoiceViewController.m
DYYY_CFLAGS = -fobjc-arc -w
DYYY_LDFLAGS = -weak_framework AVFAudio
DYYY_FRAMEWORKS = CoreAudio
CXXFLAGS += -std=c++11
CCFLAGS += -std=c++11

export THEOS_STRICT_LOGOS=0
export LOGOS_DEFAULT_GENERATOR=internal

include $(THEOS_MAKE_PATH)/tweak.mk

ifeq ($(shell whoami),huami)
    export THEOS_DEVICE_IP = 192.168.31.228
else
    export THEOS_DEVICE_IP = 192.168.15.105
endif
THEOS_DEVICE_PORT = 22

clean::
	@echo -e "\033[31m==>\033[0m Cleaning packages…"
	@rm -rf .theos packages obj

after-package::
	@echo -e "\033[32m==>\033[0m Packaging complete."
	@if [ "$(GITHUB_ACTIONS)" != "true" ] && [ "$(INSTALL)" = "1" ]; then \
		DEB_FILE=$$(ls -t packages/*.deb | head -1); \
		PACKAGE_NAME=$$(basename "$$DEB_FILE" | cut -d'_' -f1); \
		echo -e "\033[34m==>\033[0m Installing $$PACKAGE_NAME to device…"; \
		ssh root@$(THEOS_DEVICE_IP) "rm -rf /tmp/$${PACKAGE_NAME}.deb"; \
		scp "$$DEB_FILE" root@$(THEOS_DEVICE_IP):/tmp/$${PACKAGE_NAME}.deb; \
		ssh root@$(THEOS_DEVICE_IP) "dpkg -i --force-overwrite /tmp/$${PACKAGE_NAME}.deb && rm -f /tmp/$${PACKAGE_NAME}.deb"; \
	else \
		echo -e "\033[33m==>\033[0m Skipping installation (GitHub Actions environment or INSTALL!=1)"; \
	fi