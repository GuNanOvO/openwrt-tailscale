# 关于 Fork 本仓库 `package` 目录自行编译的注意事项

# Notes on Forking the `package` Directory for Self-Building

部分用户会 fork 本仓库的 `package` 目录，并在 OpenWrt SDK 中自行编译。本文对 Makefile 中的关键配置进行说明，方便理解和按需调整。  
Some users fork the `package` directory from this repository and build it using the OpenWrt SDK. This document explains key parts of the Makefile for better understanding and customization.

---

## 1. 编译裁剪参数（减小体积）

## 1. Build Tags (Size Reduction)

```makefile
GO_PKG_TAGS:=ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_completion,ts_omit_kube,ts_omit_systray,ts_omit_taildrop,ts_omit_tap,ts_omit_tpm,ts_omit_relayserver,ts_omit_capture,ts_omit_syspolicy,ts_omit_debugeventbus,ts_omit_webclient
```

该配置用于裁剪 Tailscale 的功能模块，从而减小最终二进制体积。  
These `GO_PKG_TAGS` strip unnecessary modules from Tailscale to reduce binary size.

* `ts_include_cli`：保留 CLI 功能 / keep CLI support
* `ts_omit_*`：移除对应功能模块 / remove specific features (AWS, Kubernetes, Web UI, etc.)

说明：
Note:

* 若需要完整功能，可移除部分 `ts_omit_*` 参数  
  Remove some `ts_omit_*` flags if full functionality is required
* 功能越完整，体积越大  
  More features will significantly increase binary size

---

## 2. 禁用 UPX 的架构判断

## 2. Disable UPX on Unsupported Architectures

```makefile
ifneq ($(filter mips64% riscv64% loongarch64%,$(ARCH)),)
  DISABLE_UPX:=1
endif
```

该逻辑用于在以下架构上禁用 UPX：  
This disables UPX compression on the following architectures:

* mips64
* riscv64
* loongarch64

原因：这些架构上 UPX 兼容性较差，可能导致程序异常。  
Reason: UPX may be unstable or unsupported on these architectures.

---

## 3. UPX 压缩逻辑

## 3. UPX Compression Logic

```makefile
ifneq ($(DISABLE_UPX),1)
	if ! $(TOPDIR)/upx/upx -t $(GO_PKG_BUILD_BIN_DIR)/tailscaled >/dev/null 2>&1; then \
		echo "==> UPX enabling on ARCH $(ARCH)"; \
		$(TOPDIR)/upx/upx --best --lzma $(GO_PKG_BUILD_BIN_DIR)/tailscaled; \
	else \
		echo "==> UPX already compressed on ARCH $(ARCH)"; \
	fi
else
	echo "==> UPX disabled on ARCH $(ARCH)"
endif
```

该代码用于对 `tailscaled` 二进制进行压缩：  
This section compresses the `tailscaled` binary using UPX:

* 自动检测是否已压缩
  Detects whether the binary is already compressed
* 未压缩则执行压缩
  Compresses if not already compressed
* 已压缩则跳过
  Skips if already compressed

使用要求：  
Requirement:

```
$(TOPDIR)/upx/upx
```

路径下必须存在 UPX 可执行文件。  
The UPX binary must be placed at this path.

说明：
Note:

* 若不需要压缩，可移除此段代码  
  This block can be removed if compression is not needed

---

## 4. 额外导出二进制文件（可选）

## 4. Extra Binary Export (Optional)

```makefile
mkdir -p $(TOPDIR)/bin/packages/$(ARCH_PACKAGES)/base
$(CP) $(GO_PKG_BUILD_BIN_DIR)/tailscaled $(TOPDIR)/bin/packages/$(ARCH_PACKAGES)/base/tailscaled
```

该代码会在编译完成后额外复制一份 `tailscaled`：  
This copies the `tailscaled` binary after build:

* 输出路径：`bin/packages/.../base/`
* Output path: `bin/packages/.../base/`

用途：
Purpose:

* 方便直接获取二进制文件  
  Easy access to raw binary
* 用于调试或手动分发  
  Useful for debugging or manual distribution

说明：
Note:

* 如果只需要 `.ipk` 或 `.apk` 包，可以删除这两行  
  Can be safely removed if only `.ipk` or `.apk` packages are needed

---

## 总结建议

## Recommendations

* 需要更小体积 → 保留裁剪参数  
  Smaller size → keep `ts_omit_*` flags

* 需要完整功能 → 减少裁剪  
  Full features → remove some omit flags

* 遇到运行问题 → 尝试禁用 UPX  
  Runtime issues → try disabling UPX

* 仅用于标准打包 → 删除额外二进制导出  
  Standard packaging only → remove extra binary export

---

如有问题欢迎反馈。  
Feedback is welcome if you encounter any issues.
