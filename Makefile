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

# ==========================================================
# === 核心修复 1：仅在非 GitHub Actions 环境下注入旧版工具链头文件路径 ===
# ==========================================================
ifneq ($(GITHUB_ACTIONS),true)
    # 💻 本地 Windows (WSL) 环境下，手动喂饭指定 C++ 标准库路径
    ADDITIONAL_CFLAGS += -I$(THEOS)/sdks/iPhoneOS14.5.sdk/usr/include/c++/v1
    ADDITIONAL_OBJCFLAGS += -I$(THEOS)/sdks/iPhoneOS14.5.sdk/usr/include/c++/v1
    ADDITIONAL_CXXFLAGS += -stdlib=libc++
    ADDITIONAL_OBJCCXXFLAGS += -stdlib=libc++
endif
# ☁️ 如果是 GitHub Actions，上面这段会被跳过，使用 macOS 原生极度聪明的 Clang 寻址

include $(THEOS)/makefiles/common.mk
TWEAK_NAME = DYYY

DYYY_FILES = DYYY.xm DYYYFloatClearButton.xm DYYYFloatSpeedButton.m DYYYSettings.xm DYYYABTestHook.xm DYYYLongPressPanel.xm DYYYSettingsHelper.m DYYYImagePickerDelegate.m DYYYBackupPickerDelegate.m DYYYSettingViewController.m DYYYBottomAlertView.m DYYYCustomInputView.m DYYYOptionsSelectionView.m DYYYIconOptionsDialogView.m DYYYAboutDialogView.m DYYYKeywordListView.m DYYYFilterSettingsView.m DYYYConfirmCloseView.m DYYYToast.m DYYYManager.m DYYYUtils.m CityManager.m AWMSafeDispatchTimer.m DYYYAudioManager.m DYYYVoiceViewController.m

# ==========================================================
# === 核心修复 2：统一编译和链接标志 ===
# ==========================================================
DYYY_CFLAGS = -fobjc-arc -w

# 所有环境都适用的 C++ 标准声明
DYYY_CXXFLAGS = -std=c++11 -stdlib=libc++

# [必选项] 必须链接 -lc++，否则链接器找不到 C++ 标准库的实现
DYYY_LDFLAGS = -lc++ -weak_framework AVFAudio -Wl,-no_warn_incompatible_arm64e

# [必选项] 必须补齐所有依赖的框架，防止符号未定义 (Undefined symbols)
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
