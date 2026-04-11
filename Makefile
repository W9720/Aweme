#
#  DYYY
#
#  Copyright (c) 2024 huami. All rights reserved.
#  Channel: @huamidev
#  Created on: 2024/10/04
#
-include Makefile.local

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

# ==========================================================
# === 终极修复：动态切换 TARGET SDK 与 C++ 头文件路径 ===
# ==========================================================
ifeq ($(GITHUB_ACTIONS),true)
    # ☁️ CI 环境 (macOS + Xcode):
    # 必须使用 latest SDK，让 Xcode 原生 Clang 自动匹配它自己的 C++ 标准库 (Toolchain)
    TARGET = iphone:clang:latest:14.0
    
    DYYY_CXXFLAGS = -std=c++11 -stdlib=libc++
else
    # 💻 本地环境 (WSL / 旧版工具链):
    # 强制使用 14.5 SDK，并手动指定 C++ 标准库路径
    TARGET = iphone:clang:14.5:14.0
    
    ADDITIONAL_CFLAGS += -I$(THEOS)/sdks/iPhoneOS14.5.sdk/usr/include/c++/v1
    ADDITIONAL_OBJCFLAGS += -I$(THEOS)/sdks/iPhoneOS14.5.sdk/usr/include/c++/v1
    ADDITIONAL_CXXFLAGS += -stdlib=libc++
    ADDITIONAL_OBJCCXXFLAGS += -stdlib=libc++
    
    DYYY_CXXFLAGS = -std=c++11
endif
# ==========================================================

include $(THEOS)/makefiles/common.mk
TWEAK_NAME = DYYY

DYYY_FILES = DYYY.xm DYYYHook.xm DYYYFloatClearButton.xm DYYYFloatSpeedButton.m DYYYSettings.xm DYYYABTestHook.xm DYYYLongPressPanel.xm DYYYSettingsHelper.m DYYYImagePickerDelegate.m DYYYBackupPickerDelegate.m DYYYSettingViewController.m DYYYBottomAlertView.m DYYYCustomInputView.m DYYYOptionsSelectionView.m DYYYIconOptionsDialogView.m DYYYAboutDialogView.m DYYYKeywordListView.m DYYYFilterSettingsView.m DYYYConfirmCloseView.m DYYYToast.m DYYYManager.m DYYYUtils.m CityManager.m AWMSafeDispatchTimer.m DYYYAudioManager.m DYYYVoiceViewController.m DYYYVoiceChanger.m
DYYY_CFLAGS = -fobjc-arc -w

# 链接 C++ 标准库
DYYY_LDFLAGS = -lc++ -weak_framework AVFAudio

# 必须的 Frameworks
DYYY_FRAMEWORKS = UIKit Photos AVFoundation CoreGraphics CoreMedia CoreAudio

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
