---
title: 软件包
description: 浏览所有可用的 Tailscale 软件包
---

# 软件包

所有可用的 Tailscale 软件包列表。选择你的设备架构对应的软件包。

## 如何查看架构？

::: code-group
```sh [OpenWrt 25.12+ (APK)]
cat /etc/apk/arch
```

```sh [OpenWrt 24.10- (OPKG)]
opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1
```
:::

::: warning 重要提示
- OpenWrt 24.10 或更早版本请使用 `.ipk` 包
- OpenWrt 25.12 或更高版本请使用 `.apk` 包
:::

---

<script setup>
import { ref, onMounted } from 'vue'

const manifest = ref(null)
const loading = ref(true)
const error = ref(null)
const searchQuery = ref('')
const expandedAll = ref(false)

const base = import.meta.env.BASE_URL || '/openwrt-tailscale/'

onMounted(async () => {
  try {
    const resp = await fetch(`${base}package-manifest.json`)
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
    manifest.value = await resp.json()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
})

function toggleAll() {
  expandedAll.value = !expandedAll.value
  document.querySelectorAll('.arch-section').forEach(el => {
    el.open = expandedAll.value
  })
}

function filteredArchitectures() {
  if (!manifest.value) return []
  const q = searchQuery.value.toLowerCase().trim()
  if (!q) return Object.entries(manifest.value.architectures)
  return Object.entries(manifest.value.architectures).filter(([arch, data]) => {
    if (arch.toLowerCase().includes(q)) return true
    return data.files.some(f => f.name.toLowerCase().includes(q))
  })
}
</script>

<div v-if="loading" style="text-align:center;padding:3rem;">
  <p>正在加载软件包列表...</p>
</div>

<div v-else-if="error" style="text-align:center;padding:3rem;color:var(--vp-c-danger-1);">
  <p>加载失败: {{ error }}</p>
</div>

<div v-else>

<div style="display:flex;align-items:center;gap:1rem;margin-bottom:1.5rem;flex-wrap:wrap;">
  <div style="flex:1;min-width:200px;">
    <input
      v-model="searchQuery"
      type="text"
      placeholder="搜索架构或文件名..."
      style="width:100%;padding:8px 12px;border:1px solid var(--vp-c-divider);border-radius:6px;background:var(--vp-c-bg-soft);color:var(--vp-c-text-1);font-size:14px;"
    />
  </div>
  <button @click="toggleAll" style="padding:8px 16px;border:1px solid var(--vp-c-brand-1);border-radius:6px;background:transparent;color:var(--vp-c-brand-1);cursor:pointer;font-size:14px;white-space:nowrap;">
    {{ expandedAll ? '全部折叠' : '全部展开' }}
  </button>
  <span class="version-badge">v{{ manifest.version }}</span>
  <span style="font-size:13px;color:var(--vp-c-text-2);">{{ manifest.buildDate }}</span>
</div>

<div v-if="filteredArchitectures().length === 0" style="text-align:center;padding:2rem;color:var(--vp-c-text-2);">
  <p>没有匹配 "{{ searchQuery }}" 的架构</p>
</div>

<div v-for="[arch, data] in filteredArchitectures()" :key="arch">
  <details class="arch-section">
    <summary>{{ arch }} <span style="font-weight:400;font-size:0.85rem;color:var(--vp-c-text-2);margin-left:8px;">（{{ data.files.length }} 个文件）</span></summary>
    <div class="table-wrapper">
      <table>
        <thead>
          <tr>
            <th>文件</th>
            <th style="width:90px;">大小</th>
            <th>SHA256</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="file in data.files" :key="file.name">
            <td>
              <a :href="`${base}${arch}/${file.name}`" download style="font-family:monospace;font-size:0.9rem;">{{ file.name }}</a>
            </td>
            <td class="size-cell" style="text-align:right;white-space:nowrap;font-family:monospace;font-size:0.85rem;">{{ file.size }}</td>
            <td style="font-family:monospace;font-size:0.78rem;word-break:break-all;">{{ file.sha256 }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </details>
</div>

</div>

<style module>
.arch-section {
  margin-bottom: 12px;
  border: 1px solid var(--vp-c-divider);
  border-radius: 8px;
  overflow: hidden;
}
.arch-section summary {
  padding: 12px 16px;
  background: var(--vp-c-bg-soft);
  cursor: pointer;
  font-weight: 600;
  user-select: none;
  list-style: none;
  display: flex;
  align-items: center;
  gap: 8px;
}
.arch-section summary::-webkit-details-marker { display: none; }
.arch-section summary::before {
  content: '▸';
  display: inline-block;
  transition: transform 0.2s;
  font-size: 12px;
  flex-shrink: 0;
}
.arch-section[open] summary::before { transform: rotate(90deg); }
.arch-section summary:hover { background: var(--vp-c-bg-alt); }
.arch-section table { width: 100%; border-collapse: collapse; font-size: 14px; }
.arch-section th {
  text-align: left; background: var(--vp-c-bg-soft);
  padding: 10px 16px; border-bottom: 1px solid var(--vp-c-divider);
  color: var(--vp-c-text-2); font-size: 13px;
}
.arch-section td { padding: 8px 16px; border-bottom: 1px solid var(--vp-c-divider); }
.arch-section tr:hover td { background: var(--vp-c-bg-soft); }
.arch-section a { color: var(--vp-c-brand-1); text-decoration: none; }
.arch-section a:hover { text-decoration: underline; }
.table-wrapper { overflow-x: auto; }
.version-badge {
  display: inline-block; padding: 2px 10px; border-radius: 12px;
  font-size: 0.8rem; font-weight: 600;
  background: var(--vp-c-brand-soft); color: var(--vp-c-brand-1);
}
</style>

## 下一步

- [快速开始](/zh/guide/quick-start) — 在设备上安装 Tailscale
- [APK 配置指南](/zh/guide/apk-setup) — 适用于 OpenWrt 25.12+
- [OPKG 配置指南](/zh/guide/opkg-setup) — 适用于 OpenWrt 24.10-
