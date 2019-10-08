ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = tfdidthatsay
tfdidthatsay_FILES = $(wildcard tweak/*.xm)
tweak/Narwhal.xm_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Reddit"
	install.exec "killall -9 Apollo"
	install.exec "killall -9 narwhal"