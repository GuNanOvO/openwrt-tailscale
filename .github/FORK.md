**Fork 指南 | Forking Guide**

如果您 fork 本项目，请按以下步骤修改配置，以使您的 fork 正常工作。  
If you fork this repository, please follow these steps to adapt the configuration to your own fork.

---

### 1. 修改 install 脚本 | Modify the install script

修改 `install.sh` 和 `install_en.sh` 脚本顶部变量区域中的 `REPO` 为您的 fork 仓库地址。  
Change the `REPO` variable at the top of `install.sh` and `install_en.sh` to point to your fork.

---

### 2. 修改 GitHub Actions 工作流文件 | Modify GitHub Actions workflow files

在以下两个文件中，将所有出现的 `GuNanOvO/openwrt-tailscale` 替换为您的 fork 项目名称（例如 `yourname/your-repo`）：
- `.github/workflows/build-tailscale.yml`
- `.github/workflows/check-version.yml`

通常只需修改 `env` 部分的 `REPO_OWNER/TARGET_REPO` 即可。  
In these two files, replace every occurrence of `GuNanOvO/openwrt-tailscale` with your fork's identifier (e.g., `yourname/your-repo`).  
Usually, only the `env` section needs updating.

---

### 3. 设置必要的 Secrets | Set up required Secrets

您需要在您的 GitHub 仓库的 **Settings → Security → Secrets and variables → Actions** 中添加以下 Repository secrets：

You must add the following repository secrets in your fork's **Settings → Security → Secrets and variables → Actions**:

| Secret Name | 说明 | Description |
|-------------|------|-------------|
| `USIGN_SECRET_KEY_B64` | 使用 usign 生成的私钥的 Base64 编码，用于签名 ipk 包。 | Base64-encoded usign private key, used for signing ipk packages. |
| `RSA_SECRET_KEY_B64`   | 使用 RSA 生成的私钥的 Base64 编码，用于签名 apk 索引。 | Base64-encoded RSA private key, used for signing apk indices. |
| `PAT_TOKEN`            | 具有 `repo` 权限的 GitHub 个人访问令牌，用于触发工作流。 | GitHub Personal Access Token with `repo` scope, used to trigger workflows. |
| `GHCR_READ_TOKEN`      | 具有 `read:packages` 权限的 GitHub 令牌（可选，用于检测上游 GHCR 发布版本）。如果您不使用此功能，可以忽略。 | GitHub token with `read:packages` scope (optional, for detecting upstream GHCR releases). You may omit it if not needed. |

> **注意**：`GHCR_READ_TOKEN` 为可选，默认构建不依赖它，可根据需要决定是否设置。  
> **Note**: `GHCR_READ_TOKEN` is optional. The default build does not require it; you can set it only if you need upstream release detection.

---

完成以上步骤后，您的 fork 即可独立运行自动化构建。  
After completing these steps, your fork will be ready to run the automated builds independently.