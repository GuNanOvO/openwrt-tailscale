---
layout: home

hero:
  name: "OpenWrt Tailscale"
  text: "Latest, Smaller Tailscale"
  tagline: Optimized Tailscale feed for OpenWrt — UPX compressed, smaller size, same functionality
  actions:
    - theme: brand
      text: Get Started
      link: /en/guide/quick-start
    - theme: alt
      text: View Packages
      link: /en/packages
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
