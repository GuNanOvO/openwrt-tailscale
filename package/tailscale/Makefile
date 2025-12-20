#
# Copyright (C) 2021 CZ.NIC, z. s. p. o. (https://www.nic.cz/)
# Copyright (C) 2025 GuNan <gunanovo@gmail.com>
#
# This is free software, licensed under the BSD 3-Clause License.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=tailscale
PKG_VERSION:=1.92.2
PKG_RELEASE:=1

PKG_STRIP:=0

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/tailscale/tailscale/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=3d0b124ff79d9af4c11ae5853cd6b58c687c7445a2380ed89e7cdc8fa75dbca1

PKG_MAINTAINER:=GuNan <gunanovo@gmail.com>
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_CPE_ID:=cpe:/a:tailscale:tailscale

PKG_BUILD_DIR:=$(BUILD_DIR)/tailscale-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=tailscale.com/cmd/tailscaled
GO_PKG_LDFLAGS:=-s -w -buildid= -X 'tailscale.com/version.longStamp=$(PKG_VERSION)-$(PKG_RELEASE) (OpenWrt-UPX)'
GO_PKG_LDFLAGS_X:=tailscale.com/version.shortStamp=$(PKG_VERSION)
GO_PKG_TAGS:=ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_completion,ts_omit_kube,ts_omit_systray,ts_omit_taildrop,ts_omit_tap,ts_omit_tpm,ts_omit_relayserver,ts_omit_capture,ts_omit_syspolicy,ts_omit_debugeventbus,ts_omit_webclient
GO_PKG_GCFLAGS:=-trimpath

UPX_EXCLUDED_TARGETS := \
	mips64_mips64r2 \
	mips64_octeonplus \
	mips64el_mips64r2 \
	riscv64_riscv64
	
UPX_CUR_TARGET := $(ARCH)_$(SUBTARGET)

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/tailscale
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  TITLE:=Zero config VPN (UPX Compressed)
  URL:=Original(https://tailscale.com), Smaller(https://github.com/GuNanOvO/openwrt-tailscale)
  DEPENDS:=$(GO_ARCH_DEPENDS) ca-bundle kmod-tun
  PROVIDES:=tailscale tailscaled
endef

define Package/tailscale/description
  A smaller version of Tailscale. Built for OpenWrt.
  It creates a secure network between your servers, computers,
  and cloud instances. Even when separated by firewalls or subnets.
endef

define Package/tailscale/conffiles
/etc/config/tailscale
/etc/tailscale/
endef

define Package/tailscale/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config
	$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/tailscaled $(1)/usr/sbin

ifneq ($(filter $(UPX_CUR_TARGET),$(UPX_EXCLUDED_TARGETS)),)
	echo "==> UPX disabled on target $(UPX_CUR_TARGET)"
else
	echo "==> UPX enabled on target $(UPX_CUR_TARGET)"
	$(TOPDIR)/upx/upx --best --lzma $(1)/usr/sbin/tailscaled
endif

	$(LN) tailscaled $(1)/usr/sbin/tailscale
	$(INSTALL_BIN) ./files/tailscale.init $(1)/etc/init.d/tailscale
	$(INSTALL_DATA) ./files/tailscale.conf $(1)/etc/config/tailscale
endef

$(eval $(call BuildPackage,tailscale))