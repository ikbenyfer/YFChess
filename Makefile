# Makefile voor Theos - YF Schaak
# iphone:clang:<SDK-versie>:<minimale iOS-versie>
# SDK 14.5 bevat nog armv7. De minimale versie blijft iOS 9.0, en
# -Werror=unguarded-availability laat het bouwen mislukken zodra code
# een functie gebruikt die nieuwer is dan iOS 9.0.
TARGET := iphone:clang:14.5:9.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = YFChess

YFChess_FILES = $(wildcard Engine/*.c) $(wildcard App/*.m)
YFChess_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore Security
YFChess_CFLAGS = -fobjc-arc -IEngine -IApp -Wno-error -Werror=unguarded-availability -Werror=unguarded-availability-new -Werror=objc-method-access -Werror=incompatible-pointer-types

include $(THEOS_MAKE_PATH)/application.mk
