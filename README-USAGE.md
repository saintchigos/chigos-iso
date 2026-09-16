# Chigos OS — User Guide

Welcome to **Chigos**, a Linux distribution for computer-science students:
a full hacking/CTF toolset, the OpenCode AI coding agent, and real gaming —
all on one GNOME desktop.

---

## Quick start

- **Desktop:** GNOME (Yaru-dark, Papirus icons). `Super` opens Activities.
- **OpenCode** (the AI agent): open a terminal and run:
  ```bash
  opencode
  ```
  First run: press it to authenticate (or edit `~/.config/opencode/opencode.json`).
  It understands your project's `AGENTS.md` (a starter one sits in your home folder).
- **Type a tool name** in a terminal, hit Tab-complete — most hacking tools are
  on the PATH. `chigos-tools` prints the category list.

---

## Security / hacking toolset

Everything is installed but some need root (`sudo`). Use responsibly, only on
systems you own or have written permission to test.

| Category | Tools |
|---|---|
| Network recon | `nmap`, `masscan`, `netdiscover`, `arp-scan`, `tcpdump`, `wireshark`, `hping3` |
| Web app testing | `sqlmap`, `ffuf`, `gobuster`, `nikto`, `nuclei`, `zaproxy`, `burpsuite` |
| Exploitation | `msfconsole` (Metasploit), `hydra`, `john`, `hashcat`, `medusa`, `netexec` |
| OSINT | `theHarvester`, `sherlock`, `enum4linux`, `whois`, `dnsrecon`, `amass` |
| Wireless | `aircrack-ng`, `wifite`, `reaver`, `kismet`, `hcxtools`, `pixiewps` |
| Forensics | `autopsy`, `sleuthkit`, `foremost`, `binwalk`, `dcfldd`, `exiftool` |
| Reverse engineering | `gdb`, `radare2`, `rizin`, `ghidra`, `apktool`, `strace` |
| Passwords | `john`, `hashcat`, `hydra`, `crunch`, `cewl`, `fcrackzip` |
| CTF scripting | `python3` (`pwntools`, `scapy`, `impacket`), `nc`, `socat` |

Wordlists live in `/usr/share/seclists` and `/usr/share/wordlists`.

### The `kali` container (optional)
If you enabled `KALI_CONTAINER=yes` at build time, the **full Kali toolset** is one
command away in an isolated container:
```bash
kali nmap -sV 10.0.0.5
kali hashcat ...
kali bash          # drop into a Kali shell
```
The base OS stays clean and the container stays up to date.

---

## OpenCode — the AI coding agent

```bash
opencode                # start the TUI in the current folder
opencode --session      # choose / resume a session
opencode --help         # all commands
```

- Config: `~/.config/opencode/opencode.json`
- Project rules: edit `AGENTS.md` in any project — OpenCode reads it.
- Needs an LLM **API key** or a local model (Ollama). `opencode auth` guides you.
- Works great in `kitty` (installed) or `gnome-terminal`.

---

## Gaming

### Your first game (Steam)
1. Launch **Steam**, log in.
2. **Steam → Settings → Compatibility**:
   - enable *Enable Steam Play for all other titles*,
   - pick *Proton Experimental* (or latest official Proton).
3. Install and play. Windows-only titles run through Proton automatically.

### Better compatibility (GE-Proton)
1. Open **ProtonUp-Qt** (Flatpak app).
2. Pick `GE-Proton`, install the latest.
3. In Steam, a game → Properties → Compatibility → force GE-Proton.

### Epic, GOG, Battle.net, Ubisoft
Use **Lutris** (Flatpak app, ships with runners). Add your store account, install
the game, play. Lutris manages Wine prefixes and DXVK for you.

### Raw Wine (non-store Windows apps)
```bash
winecfg                     # set up ~/.wine once
wine setup.exe              # run an installer
winetricks                   # install d3dx9/11, dotnet, etc.
```

### Built-in optimizations
- `chigos-run "game command"` — wraps a game in GameMode + MangoHud (FPS HUD).
- `gamemoderun %command%` in Steam launch options = same effect per game.
- `gamescope` is installed for micro-compositor tricks (FSR upscaling).

### Drivers
- **AMD / Intel:** already active (Mesa/RADV). `vulkaninfo --summary` to confirm.
- **NVIDIA:** run once: `sudo chigos-gpu-setup` → installs the proprietary
  driver + 32-bit libs, then reboot. Confirm with `nvidia-smi`.

---

## 8 GB RAM tips

- Swap tuned to `vm.swappiness=10` already (from the build).
- Close GNOME Software / Snap Store; they're only heavy when open.
- For CTF VMs prefer the `kali` container over a full GUI VM; for full VMs use
  under 4 GB RAM each (`virt-manager` is installed).
- GNOME file indexing is disabled to keep the disk (and RAM) quiet.

---

## Everyday tasks

| Task | Command / app |
|---|---|
| Install software | `sudo apt install <pkg>` or **Software** app |
| System update | `sudo apt update && sudo apt upgrade -y` |
| Files | **Files** (Nautilus) |
| Code editing | VS Code (Microsoft repo), `nvim`, `code` |
| Writing/reports | LibreOffice (preinstalled) — opens Word docs |
| Browser | Firefox (preinstalled) |
| Screen record | OBS Studio (Flagship repo) |
| Downloads | curl, wget, `aria2` |

---

## Keep it in shape

```bash
sudo apt update && sudo apt upgrade -y   # updates
sudo apt autoremove && sudo apt clean    # tidy
docker system prune -af                  # reclaim container space
```

Happy building. — the Chigos team