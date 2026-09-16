# Chigos OS — How to get your ISO

You have **two ways** to get a bootable **Chigos ISO**. The quickest is the
cloud build (no Linux needed on your machine). Both are below.

---

## FASTEST: Cloud build → download the ISO (Recommended)

Everything is scripted for free **GitHub Actions**. The result is a real
`chigos-live.iso` file you download and flash to a USB stick.

**Step 1 — Put the folder on GitHub (one time, ~5 min)**
1. Make a free account at <https://github.com>
2. Install **GitHub Desktop** from <https://desktop.github.com> and sign in.
3. GitHub Desktop → **File → Add local repository** → `C:\Users\chigo\chigos-build`
4. **Publish repository** → make it **Public**, name it `chigos-iso`.
5. Click **Publish/Push** to upload. (If it prompts for "origin", confirm.)

**Step 2 — Start the build**
1. On github.com open your `chigos-iso` repo.
2. Click the **Actions** tab → workflow **"Chigos ISO Build"** → **Run workflow**
   → Run. (Also triggers on push to `main`.)
3. Wait ~1–2 hours. You can close the page; it keeps running.

**Step 3 — Grab the ISO**
1. When the run finishes (green check), open it.
2. At the bottom, under **Artifacts**, download **chigos-iso**.
3. Unzip → you get **`chigos-live.iso`** (a few GB).

**Step 4 — Boot it**
1. Download **Rufus** from <https://rufus.ie>
2. Plug in a **16 GB+ USB stick** → Rufus → select `chigos-live.iso`
   → mode "ISO Image" → Start.
3. Reboot your laptop → boot menu (F12 / Esc / F2) → choose the USB.
4. Pick **"Try Chigos"** from the boot menu. Explore!
5. If you love it → reboot into the USB again → **"Install Chigos"** and
   wipe Windows from the installer's disk screen.

> Want it smaller/faster? Edit `.github/workflows/build-chigos-iso.yml` and
> change `CHIGOS_LITE` to `'1'`.

---

## Alternative: Build it yourself with Cubic

For full control (if you ever want to add your own stuff), the single merged
script also runs inside Cubic on Ubuntu 24.04.

```bash
# On Ubuntu 24.04 (desktop)
sudo add-apt-repository universe
sudo add-apt-repository ppa:cubic-wizard/release
sudo apt update && sudo apt install --no-install-recommends cubic
```

1. Download the base: <https://ubuntu.com/download/desktop>
2. Copy this whole `chigos-build` folder to that machine.
3. **Cubic → project folder → select the Ubuntu ISO** → wait for extraction.
4. In Cubic's terminal:
   ```bash
   rm -f /etc/resolv.conf; echo "nameserver 8.8.8.8" > /etc/resolv.conf
   cd /root && mkdir chigos && cp -r <path-to>/chigos-build/* chigos/
   cd chigos && bash chigos-install.sh
   ```
5. Next → keep packages → Options (Volume ID `Chigos 24.04 LTS amd64`)
   → Compression **zstd** → Generate (20–45 min) → flash with Rufus.

---

## What's inside (single merged script `chigos-install.sh`)

| Area | Contents |
|---|---|
| Repos | universe/multiverse/restricted, i386, Valve Steam, WineHQ, VS Code, Flatpak |
| Security (~140 tools) | nmap, masscan, wireshark, tshark, sqlmap, metasploit (msfconsole), burpsuite, john, hashcat, hydra, aircrack-ng, kismet, ghidra, radare2, gdb, sleuthkit/autopsy, theHarvester, amass, zaproxy, nuclei, ffuf, SecLists + pipx/go/snap tools |
| Dev + **VS Code** | VS Code preinstalled, Docker, Python/Node/Go/JDK, build-essential, git, tmux, neovim, LLDB/gdb, postgres, virt-manager |
| OpenCode | OpenCode AI agent preinstalled + config + AGENTS.md |
| Gaming | Steam (+Proton), Wine, winetricks, Lutris, ProtonUp-Qt, GameMode, MangoHud, Gamescope, all 32-bit libs, Vulkan |
| Desktop | Lightweight GNOME (dark theme, Papirus icons), Chigos wallpapers/logo |
| Lightweight | swappiness=10, background indexers off → leaves RAM for YOUR programs |

## Options you can change

- `CHIGOS_LITE=1` → smaller ISO, skips the biggest tools (8 GB RAM friendly).
- `KALI_CONTAINER=yes` → bakes in the full Kali Docker toolset (~2 GB).

## Troubleshooting

- **Rufus says ISO is fine but laptop won't boot** → try USB port 1 vs 3,
  disable Secure Boot in BIOS, or in Rufus use "DD Image" mode.
- **NVIDIA black screen** → boot with `nomodeset` (GRUB → "e" → add
  `nomodeset`), then run `sudo chigos-gpu-setup` after installing.
- **OpenCode needs a key** → run `opencode` once, it will guide you
  (`opencode auth`), or add a key in `~/.config/opencode/opencode.json`.