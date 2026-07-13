---
layout: home

hero:
  name: "OpenWrt Tailscale"
  text: "最新的、更小的 Tailscale"
  tagline: 专为 OpenWrt 优化的 Tailscale 软件源 — 使用 UPX 压缩，体积更小，功能不变
  actions:
    - theme: brand
      text: 快速开始
      link: /zh/guide/quick-start
    - theme: alt
      text: 浏览软件包
      link: /zh/packages
    - theme: alt
      text: GitHub
      link: https://github.com/GuNanOvO/openwrt-tailscale

---

<script setup>
import { withBase } from 'vitepress'
</script>

<div style="text-align:center;margin-top:2rem;">
  <img :src="withBase('/banner.png')" alt="Tailscale for OpenWrt" style="max-width:100%;height:auto;border-radius:8px;">
</div>
