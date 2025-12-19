# Copyright (C) 2021 CZ.NIC
# GPLv2

include $(TOPDIR)/rules.mk

PKG_NAME:=tailscale
PKG_VERSION:=1.92.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/tailscale/tailscale/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=3d0b124ff79d9af4c11ae5853cd6b58c687c7445a2380ed89e7cdc8fa75dbca1

PKG_MAINTAINER:=Zephyr Lykos <self@mochaa.ws>
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DIR:=$(BUILD_DIR)/tailscale-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

include $(INCLUDE_DIR)/package.mk

GO := /builder/go/bin/go

GO_LDFLAGS := \
	-X tailscale.com/version.longStamp=$(PKG_VERSION)-$(PKG_RELEASE)\ (OpenWrt) \
	-X tailscale.com/version.shortStamp=$(PKG_VERSION)

GO_TAGS := ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_completion,ts_omit_kube,ts_omit_systray,ts_omit_taildrop,ts_omit_tap,ts_omit_tpm

# tags="ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_tap,ts_omit_kube,ts_omit_completion,ts_omit_ssh,ts_omit_wakeonlan,ts_omit_capture,ts_omit_relayserver,ts_omit_systray,ts_omit_taildrop,ts_omit_tpm,ts_omit_syspolicy,ts_omit_debugeventbus,ts_omit_webclient"

UPX_EXCLUDED_TARGETS := \
	mips64_mips64r2 \
	mips64_octeonplus \
	mips64el_mips64r2 \
	riscv64_riscv64
UPX_CUR_TARGET := $(ARCH)_$(SUBTARGET)

define Package/tailscale
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  TITLE:=Zero config VPN
  URL:=https://tailscale.com
  DEPENDS:=+ca-bundle
  RDEPENDS:=+kmod-tun
  PROVIDES:=tailscaled
endef

define Package/tailscale/description
  It creates a secure network between your servers, computers,
  and cloud instances, even when separated by firewalls or subnets.
endef

define Build/Compile
	cd $(PKG_BUILD_DIR) && \
	GOOS=$(GOOS) \
	GOARCH=$(GO_ARCH) \
	GO386=$(GO386) \
	GOAMD64=$(GOAMD64) \
	GOARM=$(GO_ARM) \
	GOMIPS=$(GO_MIPS) \
	GOMIPS64=$(GOMIPS64) \
	GOPPC64=$(GOPPC64) \
	CGO_ENABLED=$(CGO_ENABLED) \
	CC="$(TARGET_CC)" \
	CXX="$(TARGET_CXX)" \
	CGO_CFLAGS="$(TARGET_CFLAGS)" \
	CGO_CPPFLAGS="$(TARGET_CPPFLAGS)" \
	CGO_CXXFLAGS="$(TARGET_CXXFLAGS)" \
	CGO_LDFLAGS="$(TARGET_LDFLAGS)" \
	$(GO) build \
		-tags "$(GO_TAGS)" \
		-ldflags "$(GO_LDFLAGS)" \
		-o $(PKG_BUILD_DIR)/tailscaled \
		./cmd/tailscaled
endef

define Package/tailscale/install
	$(INSTALL_DIR) $(1)/usr/sbin \
		$(1)/etc/init.d \
		$(1)/etc/config

	$(INSTALL_BIN) \
		$(PKG_BUILD_DIR)/tailscaled \
		$(1)/usr/sbin/tailscaled

ifneq ($(filter $(UPX_CUR_TARGET),$(UPX_EXCLUDED_TARGETS)),)
	@echo "==> UPX disabled on target $(UPX_CUR_TARGET)"
else
	@echo "==> UPX enabled on target $(UPX_CUR_TARGET)"
	upx/upx --best --lzma \
		$(1)/usr/sbin/tailscaled
endif

	$(LN) tailscaled $(1)/usr/sbin/tailscale

	$(INSTALL_BIN) ./files/tailscale.init \
		$(1)/etc/init.d/tailscale

	$(INSTALL_DATA) ./files/tailscale.conf \
		$(1)/etc/config/tailscale
endef

$(eval $(call BuildPackage,tailscale))