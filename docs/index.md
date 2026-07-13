---
layout: page
---

<script setup>
import { withBase } from 'vitepress'
import { onMounted } from 'vue'

onMounted(() => {
  const lang = navigator.language.toLowerCase()
  const target = lang.startsWith('zh') ? '/zh/' : '/en/'
  window.location.replace(withBase(target))
})
</script>

<div style="text-align:center;padding:3rem;">
  <p>Redirecting…</p>
  <p>
    <a :href="withBase('/en/')">English</a> | <a :href="withBase('/zh/')">简体中文</a>
  </p>
</div>
