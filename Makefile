TWEAK_NAME = DietBulletin
DietBulletin_FILES = Tweak.x
DietBulletin_FRAMEWORKS = UIKit

ADDITIONAL_CFLAGS = -std=c99

TARGET_IPHONEOS_DEPLOYMENT_VERSION := 3.0

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
