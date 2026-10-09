# Glass Stats

Self-developed **macOS menu bar** system monitor. Native Swift / SwiftUI, Apple Silicon first, local only.

Liquid Glass–styled when you compile against the latest SDK (macOS 26 APIs). On older SDKs and runtimes it falls back to `.ultraThinMaterial` / vibrancy. No ads, no tracking, no network telemetry.

**Not affiliated with, endorsed by, or derived from [Stats](https://mac-stats.com/) (exelban).** Glass Stats is an independent project. It does not use Stats trademarks, assets, or source code.

## Status

V1 skeleton: live **CPU** + **RAM** in the menu bar and a glass popover with charts and top processes. Settings toggles show or hide modules. Disk, Network, and Battery are basic scaffolds. GPU / fans / sensors are **V1.1** (not implemented).

## Requirements

| | |
| --- | --- |
| Mac | Apple Silicon (arm64 only in this project) |
| OS to *run* | **macOS 14.0** Sonoma or later |
| OS for Liquid Glass | **macOS 26** (Tahoe) when built with Xcode 26 |
| Xcode | **16.0+** to open the checked-in project; **26** recommended so `.glassEffect` compiles in |
| Signing | Your Apple Development team (Signing & Capabilities) |

Intel Macs are out of scope for V1 (`ARCHS = arm64`).

## Open, build, and run (M4 Pro)

1. Clone this repo and open **`GlassStats.xcodeproj`** in Xcode. The shared **GlassStats** scheme should be selected.
2. Select the **GlassStats** target → **Signing & Capabilities** → choose your **Team**. The app is **not sandboxed** on purpose (see Permissions).
3. Destination: **My Mac** (Apple Silicon).
4. Press **Run** (⌘R). Glass Stats is an accessory app (`LSUIElement`): there is **no Dock icon**. Look in the **menu bar** for the CPU and memory percents, like `12% · 48%`. VoiceOver still hears “CPU” and “memory”.
5. Click the status item for the popover (charts, top processes, disk / network / battery). Open **Settings** from the gear, or **Glass Stats → Settings…** once the app is frontmost.
6. Quit from the popover power button, or **Activity Monitor**.

**macOS Tahoe** may need **System Settings → Menu Bar** to allow the app icon. If the status item does not appear, open that pane (sometimes under Desktop & Dock) and enable **Glass Stats**.

Sampling defaults to **1 second** (Settings: 1 / 2 / 5 s). The menu bar keeps **CPU and memory** on that timer. **Processes, disk, network, and battery pause while the popover is closed**, and a module that is turned off is not sampled. GPU / fans / sensors are V1.1 only — this app does not call private SMC APIs.

Optional: if you use [XcodeGen](https://github.com/yonaskolb/XcodeGen), `project.yml` can regenerate the project (`xcodegen generate`). A checked-in `.xcodeproj` is already present so you do not need XcodeGen to build.

**Deployment target:** macOS 14.0. **Bundle ID:** `com.hkclaw.GlassStats`. **Version:** 0.1.0.

## What is live vs scaffolded

| Module | V1 | Source of numbers |
| --- | --- | --- |
| CPU (menu bar + chart + per-core bars) | Live | Mach `host_statistics(HOST_CPU_LOAD_INFO)` for the total and `host_processor_info(PROCESSOR_CPU_LOAD_INFO)` for per-core bars. Load is the **delta** of `(user+system+nice) / (user+system+nice+idle)`. The menu-bar total is lightly smoothed so it tracks Activity Monitor’s overall CPU. |
| Memory (menu bar + chart) | Live | `host_statistics64(HOST_VM_INFO64)` + `ProcessInfo.physicalMemory` (`hw.memsize`). Used ≈ app (internal − purgeable) + wired + compressor. **File cache is excluded** so idle RAM does not read as ~100%. |
| Top processes | Live, popover only | `proc_listpids` + `proc_pidinfo(PROC_PIDTASKINFO)`. Names are resolved for the top 8 only. CPU% is one core, like Activity Monitor: user+system nanoseconds / elapsed time (not divided by core count). A process using one full core reads about 100%; a process using several cores can read above 100%, capped at the logical CPU count. |
| Disk | Basic | Boot volume via `URL` resource values (`volumeTotalCapacity`, `volumeAvailableCapacityForImportantUsage`). |
| Network | Basic | `getifaddrs` / `AF_LINK` `if_data` byte counters, shown as B/s. |
| Battery | Basic | IOKit `IOPSCopyPowerSourcesInfo`. Desktops show “no internal battery”. |
| GPU / fans / sensors | V1.1 | Documented only. |

Compare CPU and Memory Used with **Activity Monitor** after a second or two of samples. First ticks show “—” because utilization is a difference between two Mach snapshots. Process CPU uses the same one-core scale as Activity Monitor’s CPU column. Open the popover to start process, disk, network, and battery samples.

## Permissions

- **No** Accessibility, Screen Recording, Full Disk Access, or Location prompts for V1 CPU / RAM.
- **App Sandbox is off.** A sandboxed menu-bar monitor cannot enumerate other processes with `libproc` or read host-wide Mach stats the way Activity Monitor does. This matches a local utility, not a Mac App Store sandbox profile.
- Hardened Runtime is enabled. Use your Development team to sign locally.
- **Open at Login** uses `SMAppService`. macOS may require the built app to live in `/Applications` before the registration sticks.
- Nothing is uploaded. There is no analytics SDK and no network client.

## Project layout

```
GlassStats.xcodeproj/     Checked-in Xcode project (explicit file list; opens in Xcode 16+)
project.yml               Optional XcodeGen spec
GlassStats/
  GlassStatsApp.swift     MenuBarExtra (window) + Settings scene
  App/                    Store + persisted module toggles
  Models/                 Snapshots
  Sampling/               Mach / libproc / IOKit / getifaddrs
  UI/                     Liquid Glass theme, popover, charts, settings
  Assets.xcassets         Original app icon (not from Stats)
LICENSE                   MIT
```

## Disclaimer

Glass Stats is an independent, self-developed utility. It is **not** a fork of Stats, **not** affiliated with exelban, and **not** associated with [mac-stats.com](https://mac-stats.com/). “Stats” is used only to name the product this project is inspired by.

## License

[MIT](LICENSE) © 2026 hkclaw.
