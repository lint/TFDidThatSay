ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = tfdidthatsay
tfdidthatsay_FILES = $(wildcard tweak/*.xm tweak/assets/*.m)
tfdidthatsay_CFLAGS = -fobjc-arc
tweak/Reddit.xm_CFLAGS = -fno-objc-arc
tweak/Apollo.xm_CFLAGS = -fno-objc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 Reddit"
	install.exec "killall -9 Apollo"
	install.exec "killall -9 narwhal"
	install.exec "killall -9 AlienBlue"
