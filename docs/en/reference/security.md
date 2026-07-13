---
title: Security Statement
description: Security and trustworthiness of the Tailscale package feed — open-source, auditable, no manual uploads
---

# Security Statement

## Trustworthiness

All packages in this feed are built automatically via GitHub Actions. The entire process is open-source, auditable, and reproducible.

- **Source code** is taken directly from the [official Tailscale repository](https://github.com/tailscale/tailscale), with **no functional modifications**.
- Only **compiler flags** are added, and [UPX](https://upx.github.io/) is optionally used on most architectures to reduce package size.
- All **build scripts, workflows, compiler flags, and logs** are fully public in the repository's `.github/workflows` and [Actions history](https://github.com/GuNanOvO/openwrt-tailscale/actions).
- **No manual uploads, no dynamic backend** — all artifacts are generated automatically by CI and served statically via [GitHub Pages](https://pages.github.com/).

## Recommended Verification Steps

1. **Review the code** — Check the [repository](https://github.com/GuNanOvO/openwrt-tailscale) and [Actions scripts and build logs](https://github.com/GuNanOvO/openwrt-tailscale/actions)
2. **Reproduce the build** — Follow the instructions in [Build Guide](/en/build/) to verify reproducibility
3. **Verify checksums** — Check SHA256 checksums after downloading (available on the [Packages page](/en/packages))

## Disclaimer

This feed is provided **as-is**, without any warranties, express or implied. Users are solely responsible for reviewing the source code and build process before use.

For maximum security:
- Prefer official sources or trusted feeds
- Keep the repository watched for updates
- Verify builds independently when possible
