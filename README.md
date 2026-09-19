# Chigos OS

**Chigos OS** is a custom **Ubuntu 24.04 LTS**-based Linux distribution built for
computer-science students and CTF players — a full hacking/security toolset, the
OpenCode AI coding agent, a complete dev toolchain, and real Steam gaming, all on
one lightweight GNOME desktop. This repository is the build kit that produces the
bootable `chigos-live.iso`.

## What you get

| Area | Contents |
|---|---|
| Security (~140 tools) | nmap, Metasploit, Burp Suite, John, Hashcat, Ghidra, aircrack-ng, SecLists + more |
| Dev toolchain | VS Code, Docker, Python / Node / Go / JDK, git, tmux, neovim, gdb |
| AI | OpenCode agent preinstalled with config + starter `AGENTS.md` |
| Gaming | Steam (+Proton), Wine, Lutris, GameMode, MangoHud, Vulkan, 32-bit libs |
| Desktop | Lightweight GNOME, dark theme, Chigos wallpapers & logo |
| Lightweight | RAM-tuned (swappiness=10, indexers off) — leaves memory for your programs |

Plus an optional **Kali container** (`KALI_CONTAINER=yes`) with the full Kali
toolset in an isolated Docker container.

## Getting started

- **[README-BUILD.md](README-BUILD.md)** — how to get the ISO (free cloud build
  on GitHub Actions, or build it yourself with Cubic), build options, and
  troubleshooting.
- **[README-USAGE.md](README-USAGE.md)** — the user guide: security tools,
  OpenCode, gaming setup, drivers, and everyday tasks.

## Building

Everything is scripted for free **GitHub Actions** — push to `main` (or use the
workflow dispatch) and ~1–2 hours later you download `chigos-live.iso`. A single
merged installer (`chigos-install.sh`) also runs inside [Cubic](https://launchpad.net/cubic)
on Ubuntu 24.04. See [README-BUILD.md](README-BUILD.md) for full details.

### Build options (environment variables)

- `CHIGOS_LITE=1` — smaller ISO, skips the biggest tools (8 GB RAM friendly).
- `KALI_CONTAINER=yes` — bakes in the full Kali Docker toolset (~2 GB).

## Repository layout

```
chigos-install.sh              single all-in-one installer (9 steps)
.github/workflows/             free cloud ISO build (GitHub Actions)
lists/                         package lists (security, dev tools, gaming libs)
branding/                      wallpapers, logo, skel (starter AGENTS.md, bashrc)
make-branding.ps1              regenerates wallpapers + logo (PowerShell)
```

## Legal note

Security tools are for ethical use only — on systems you own or have explicit
permission to test.