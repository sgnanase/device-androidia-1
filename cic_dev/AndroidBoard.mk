# ----------------- BEGIN MIX-IN DEFINITIONS -----------------
# Mix-In definitions are auto-generated by mixin-update
##############################################################
# Source: device/intel/mixins/groups/variants/default/AndroidBoard.mk
##############################################################
# flashfile_add_blob <blob_name> <path> <mandatory> <var_name>
# - Delete ::variant:: from <path>
# - If the result does not exists and <mandatory> is set, error
# - If <var_name> is set, put the result in <var_name>
# - Add the pair <result>:<blob_name> in BOARD_FLASHFILES_FIRMWARE
define flashfile_add_blob
$(eval blob := $(subst ::variant::,,$(2))) \
$(if $(wildcard $(blob)), \
    $(if $(4), $(eval $(4) := $(blob))) \
    $(eval BOARD_FLASHFILES_FIRMWARE += $(blob):$(1)) \
    , \
    $(if $(3), $(error $(blob) does not exist)))
endef

##############################################################
# Source: device/intel/mixins/groups/boot-arch/project-celadon/AndroidBoard.mk.1
##############################################################
##############################################################
# Source: device/intel/mixins/groups/boot-arch/project-celadon/AndroidBoard.mk
##############################################################
# Rules to create bootloader zip file, a precursor to the bootloader
# image that is stored in the target-files-package. There's also
# metadata file which indicates how large to make the VFAT filesystem
# image

ifeq ($(TARGET_UEFI_ARCH),i386)
efi_default_name := bootia32.efi
LOADER_TYPE := linux-x86
else
efi_default_name := bootx64.efi
LOADER_TYPE := linux-x86_64
endif

##############################################################
# Source: device/intel/mixins/groups/device-specific/cic_dev/AndroidBoard.mk
##############################################################
.PHONY: multidroid
multidroid: droid
	@echo Make multidroid image...
	$(hide) rm -rf $(PRODUCT_OUT)/docker
	$(hide) mkdir -p $(PRODUCT_OUT)/docker/android/root
	$(hide) cp -r $(TOP)/$(INTEL_PATH_VENDOR_CIC)/host/docker/aic-manager $(PRODUCT_OUT)/docker
	$(hide) cp -r $(TOP)/$(INTEL_PATH_KERNEL_MODULES_CIC)/ashmem $(PRODUCT_OUT)/docker/aic-manager/data/
	$(hide) cp -r $(TOP)/$(INTEL_PATH_KERNEL_MODULES_CIC)/binder $(PRODUCT_OUT)/docker/aic-manager/data/
	$(hide) cp -r $(TOP)/$(INTEL_PATH_KERNEL_MODULES_CIC)/mac80211_hwsim $(PRODUCT_OUT)/docker/aic-manager/data/
	$(hide) cp -r $(TOP)/$(INTEL_PATH_VENDOR_CIC)/host/docker/android $(PRODUCT_OUT)/docker
	$(hide) cp -r $(TOP)/$(INTEL_PATH_VENDOR_CIC)/host/docker/update $(PRODUCT_OUT)/docker
	$(hide) cp $(TOP)/$(INTEL_PATH_VENDOR_CIC)/host/docker/scripts/aic $(PRODUCT_OUT)
ifneq ($(TARGET_LOOP_MOUNT_SYSTEM_IMAGES), true)
	$(hide) cp -r $(PRODUCT_OUT)/system $(PRODUCT_OUT)/docker/android/root
	$(hide) cp -r $(PRODUCT_OUT)/root/* $(PRODUCT_OUT)/docker/android/root
	$(hide) rm -f $(PRODUCT_OUT)/docker/android/root/etc
	$(hide) cp -r $(PRODUCT_OUT)/system/etc $(PRODUCT_OUT)/docker/android/root
	$(hide) chmod -R g-w $(PRODUCT_OUT)/docker/android/root
else
	$(hide) zcat $(PRODUCT_OUT)/ramdisk.img | (cd $(PRODUCT_OUT)/docker/android/root && cpio -idm)
	$(hide) rm -rf $(PRODUCT_OUT)/docker/android/root/etc
	$(hide) cp -r $(PRODUCT_OUT)/system/etc $(PRODUCT_OUT)/docker/android/root
	$(hide) rm -rf $(PRODUCT_OUT)/docker/aic-manager/images
	$(hide) mkdir -p $(PRODUCT_OUT)/docker/aic-manager/images
	$(hide) ln -t $(PRODUCT_OUT)/docker/aic-manager/images $(PRODUCT_OUT)/system.img
endif

TARGET_AIC_FILE_NAME := $(TARGET_PRODUCT)-$(BUILD_NUMBER_FROM_FILE).tar.gz

.PHONY: aic
aic: .KATI_NINJA_POOL := console
aic: multidroid
	@echo Make AIC docker images...
ifneq ($(TARGET_LOOP_MOUNT_SYSTEM_IMAGES), true)
	$(HOST_OUT_EXECUTABLES)/aic-build -b $(BUILD_NUMBER_FROM_FILE)
else
	BUILD_VARIANT=loop_mount $(HOST_OUT_EXECUTABLES)/aic-build -b $(BUILD_NUMBER_FROM_FILE)
endif
	tar cvzf $(PRODUCT_OUT)/$(TARGET_AIC_FILE_NAME) -C $(PRODUCT_OUT) aic android.tar.gz aic-manager.tar.gz -C docker update

.PHONY: cic
cic: aic

.PHONY: publish_ci
publish_ci: aic
	@echo Publish CI AIC docker images...
	$(hide) mkdir -p $(TOP)/pub/$(TARGET_PRODUCT)/$(TARGET_BUILD_VARIANT)
	$(hide) cp $(PRODUCT_OUT)/$(TARGET_AIC_FILE_NAME) $(TOP)/pub/$(TARGET_PRODUCT)/$(TARGET_BUILD_VARIANT)

# Following 1A CI practice, "publish" is used by buildbot for "latest", "release", etc. Without this
# target, the build will fail on related buildbot.
# Currently, the "publish" and "publish_ci" are the same. But they may be different in the future.
.PHONY: publish
publish: aic
	@echo Publish AIC docker images...
	$(hide) mkdir -p $(TOP)/pub/$(TARGET_PRODUCT)/$(TARGET_BUILD_VARIANT)
	$(hide) cp $(PRODUCT_OUT)/$(TARGET_AIC_FILE_NAME) $(TOP)/pub/$(TARGET_PRODUCT)/$(TARGET_BUILD_VARIANT)
##############################################################
# Source: device/intel/mixins/groups/vndk/default/AndroidBoard.mk
##############################################################
define define-vndk-sp-lib
include $$(CLEAR_VARS)
LOCAL_MODULE := $1.vendor
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_PREBUILT_MODULE_FILE := $$(call intermediates-dir-for,SHARED_LIBRARIES,$1,,,,)/$1.so
LOCAL_STRIP_MODULE := false
LOCAL_MULTILIB := first
LOCAL_MODULE_TAGS := optional
LOCAL_INSTALLED_MODULE_STEM := $1.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_RELATIVE_PATH := vndk-sp
include $$(BUILD_PREBUILT)

ifneq ($$(TARGET_2ND_ARCH),)
ifneq ($$(TARGET_TRANSLATE_2ND_ARCH),true)
include $$(CLEAR_VARS)
LOCAL_MODULE := $1.vendor
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_PREBUILT_MODULE_FILE := $$(call intermediates-dir-for,SHARED_LIBRARIES,$1,,,$$(TARGET_2ND_ARCH_VAR_PREFIX),)/$1.so
LOCAL_STRIP_MODULE := false
LOCAL_MULTILIB := 32
LOCAL_MODULE_TAGS := optional
LOCAL_INSTALLED_MODULE_STEM := $1.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_RELATIVE_PATH := vndk-sp
include $$(BUILD_PREBUILT)
endif # TARGET_TRANSLATE_2ND_ARCH is not true
endif # TARGET_2ND_ARCH is not empty
endef

define define-vndk-lib
ifeq ($$(filter libstagefright_soft_%,$1),)
include $$(CLEAR_VARS)
LOCAL_MODULE := $1.vendor
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_PREBUILT_MODULE_FILE := $$(call intermediates-dir-for,SHARED_LIBRARIES,$1,,,,)/$1.so
LOCAL_STRIP_MODULE := false
LOCAL_MULTILIB := first
LOCAL_MODULE_TAGS := optional
LOCAL_INSTALLED_MODULE_STEM := $1.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_RELATIVE_PATH := vndk
include $$(BUILD_PREBUILT)
endif

ifneq ($$(TARGET_2ND_ARCH),)
ifneq ($$(TARGET_TRANSLATE_2ND_ARCH),true)
include $$(CLEAR_VARS)
LOCAL_MODULE := $1.vendor
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_PREBUILT_MODULE_FILE := $$(call intermediates-dir-for,SHARED_LIBRARIES,$1,,,$$(TARGET_2ND_ARCH_VAR_PREFIX),)/$1.so
LOCAL_STRIP_MODULE := false
LOCAL_MULTILIB := 32
LOCAL_MODULE_TAGS := optional
LOCAL_INSTALLED_MODULE_STEM := $1.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_RELATIVE_PATH := vndk
include $$(BUILD_PREBUILT)
endif # TARGET_TRANSLATE_2ND_ARCH is not true
endif # TARGET_2ND_ARCH is not empty
endef

$(foreach lib,$(VNDK_SAMEPROCESS_LIBRARIES),\
    $(eval $(call define-vndk-sp-lib,$(lib))))

$(foreach lib,$(VNDK_CORE_LIBRARIES),\
    $(eval $(call define-vndk-lib,$(lib))))

# ------------------ END MIX-IN DEFINITIONS ------------------
