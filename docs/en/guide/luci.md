---
title: LuCI Web UI
description: Graphical management of Tailscale via luci-app-tailscale-community
---

# LuCI Web UI

For a graphical interface to manage Tailscale, we recommend installing the LuCI app built by [@Tokisaki-Galaxy](https://github.com/Tokisaki-Galaxy).

## luci-app-tailscale-community

This is an open-source LuCI application that provides an easy-to-use web interface to configure and manage Tailscale directly from OpenWrt's LuCI dashboard.

- **Repository**: [Tokisaki-Galaxy/luci-app-tailscale-community](https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community)

## Features

- View Tailscale status and connection info
- Manage Tailscale settings through LuCI
- Start/stop/restart the Tailscale service
- Monitor connected peers
- Configure routes and exit nodes

## Installation

Follow the instructions in the [luci-app-tailscale-community repository](https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community) to install the LuCI app on your OpenWrt device.

::: tip
The LuCI app works with the smaller Tailscale package from this repository — they are fully compatible.
:::
