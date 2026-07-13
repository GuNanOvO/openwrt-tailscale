---
layout: page
---

<script setup>
import { onMounted } from 'vue'
import { useRouter } from 'vitepress'

const router = useRouter()

onMounted(() => {
  const lang = navigator.language.toLowerCase()
  if (lang.startsWith('zh')) {
    router.go('/zh/')
  } else {
    router.go('/en/')
  }
})
</script>

<div style="text-align:center;padding:3rem;">
  <p>Redirecting…</p>
  <p>
    <a href="/openwrt-tailscale/en/">English</a> | <a href="/openwrt-tailscale/zh/">简体中文</a>
  </p>
</div>
