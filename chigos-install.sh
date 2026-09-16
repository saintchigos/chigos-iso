#!/bin/bash
# =============================================================================
#  Chigos OS — ALL-IN-ONE installer (merged single file)
#  One file does the whole job:
#    * Repos + 32-bit arch        * ~140 security tools
#    * Metasploit / Burp / amass  * VS Code + dev toolchain
#    * OpenCode AI agent          * Steam / Wine / Proton gaming
#    * GPU (auto)                 * Chigos branding + lightweight tuning
#
#  Where to run:
#    1. Inside the Cubic chroot during ISO build:    bash chigos-install.sh
#    2. On an already-booted Ubuntu for tuning:      sudo bash chigos-install.sh live
#
#  Options (env vars):
#    CHIGOS_LITE=1    lighter build — skip the biggest tools (for 8 GB RAM)
#    KALI_CONTAINER=yes   bake in the full Kali Docker toolset (~2 GB)
#
#  Log: /root/chigos-build.log
# =============================================================================

set -o pipefail
export DEBIAN_FRONTEND=noninteractive

LOG=/root/chigos-build.log
SD="$(cd "$(dirname "$0")" && pwd)"          # folder that holds lists/ and branding/
MODE="${1:-chroot}"                            # 'chroot' (Cubic) or 'live'
LITE="${CHIGOS_LITE:-0}"
KALI_CONTAINER="${KALI_CONTAINER:-no}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[Chigos]${NC} $*" | tee -a "$LOG"; }
warn() { echo -e "${YELLOW}[WARN]${NC}   $*" | tee -a "$LOG"; }
fail() { echo -e "${RED}[FAIL]${NC}   $*" | tee -a "$LOG"; }

echo "Chigos build log - $(date -Iseconds)" > "$LOG"
[ "$(id -u)" -eq 0 ] || { fail "Run as root (sudo)."; exit 1; }
[ -d "$SD/lists" ] || warn "lists/ not found next to script; using inline package sets."

# ---- fix DNS in Cubic chroot ------------------------------------------------
if ! grep -q "8.8.8.8" /etc/resolv.conf 2>/dev/null; then
  rm -f /etc/resolv.conf
  printf "nameserver 8.8.8.8\nnameserver 1.1.1.1\n" > /etc/resolv.conf
fi

apt-get install -y -qq software-properties-common apt-transport-https ca-certificates curl wget gpg lsb-release 2>/dev/null || true

###############################################################################
# STEP 1 — REPOSITORIES + 32-BIT ARCHITECTURE
###############################################################################
step_repos() {
  log "Step 1/9  Repositories + i386"
  apt-get update -qq 2>/dev/null || true
  add-apt-repository -y universe > /dev/null 2>&1 || true
  add-apt-repository -y multiverse > /dev/null 2>&1 || true
  add-apt-repository -y restricted > /dev/null 2>&1 || true
  dpkg --add-architecture i386

  # Valve / Steam (official repo -> steam-launcher)
  mkdir -p /usr/share/keyrings
  curl -fsSLo /usr/share/keyrings/steam.gpg https://repo.steampowered.com/steam/steam.gpg 2>/dev/null || true
  printf '%s\n' \
    'Types: deb' 'URIs: https://repo.steampowered.com/steam/' 'Suites: stable' \
    'Components: steam' 'Architectures: amd64 i386' \
    'Signed-By: /usr/share/keyrings/steam.gpg' > /etc/apt/sources.list.d/steam.sources

  # WineHQ stable
  curl -fsSLo /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key 2>/dev/null || true
  CN="$(lsb_release -sc)"
  wget -qNP /etc/apt/sources.list.d/ "https://dl.winehq.org/wine-builds/ubuntu/dists/${CN}/winehq-${CN}.sources" 2>/dev/null || true

  # VS Code (Microsoft repo)
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg 2>/dev/null || true
  printf '%s\n' \
    'Types: deb' 'URIs: https://packages.microsoft.com/repos/code' 'Suites: stable' \
    'Components: main' "Signed-By: /usr/share/keyrings/microsoft.gpg" > /etc/apt/sources.list.d/vscode.sources

  # Flatpak/Flathub (Lutris + ProtonUp-Qt)
  apt-get install -y -qq flatpak 2>/dev/null || true
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

  apt-get update -qq 2>/dev/null || true
}

###############################################################################
# STEP 2 — SECURITY TOOLSET (apt, ~140 tools)
###############################################################################
SECURITY_PKGS=(
  nmap masscan netdiscover arp-scan arping fping hping3 nbtscan traceroute
  mtr-tiny tcpdump netcat-openbsd socat ncat dnsutils dnsenum dnsmap dnsrecon
  whois ike-scan amap unicornscan iproute2 ethtool iw wireless-tools
  bettercap iptables nftables fail2ban tshark wireshark ettercap-text-only
  ettercap-common dsniff tcpflow tcpreplay python3-scapy mitmproxy macchanger
  nikto nuclei lynis rkhunter chkrootkit ssh-audit sslscan sslyze sqlmap dirb
  dirbuster gobuster ffuf wfuzz recon-ng wapiti skipfish whatweb wafw00f
  exploitdb python3-impacket impacket-scripts john johnny hashcat hydra
  hydra-gtk medusa ncrack crunch cewl fcrackzip ophcrack hashid rsmangler
  pipal pdfcrack aircrack-ng aircrack-ng-gui kismet wifite reaver bully
  pixiewps hcxtools hcxdumptool cowpatty mdk3 fern-wifi-cracker hostapd
  bluez ubertooth autopsy sleuthkit foremost scalpel testdisk photorec
  dcfldd dc3dd ddrescue guymager ewf-tools safecopy bulk-extractor yara
  reglookup steghide libimage-exiftool-perl mat2 hashdeep ssdeep
  binwalk gdb radare2 rizin edb-debugger d2j-dex2jar smali binutils elfutils
  strace ltrace gdb-multiarch binutils-multiarch python3-capstone
  theharvester enum4linux smbclient smbmap ccrypt gpg tor torbrowser-launcher
  proxychains4 siege slowhttptest t50 htop neofetch bash-completion aria2
  testssl.sh gvm pandoc wkhtmltopdf net-tools tcpflow rtl-sdr
)
if [ "$LITE" = "1" ]; then
  LITE_PKGS=( ghidra wifite mdk3 fern-wifi-cracker autopsy bulk-extractor \
              reaver bully pixiewps ubertooth hcxdumptool  )
  for p in "${LITE_PKGS[@]}"; do
    SECURITY_PKGS=("${SECURITY_PKGS[@]/$p}")
  done
fi
# append extras list if present
[ -f "$SD/lists/security-extras.list" ] && while read -r pkg; do
  [ -z "$pkg" ] && continue; case "$pkg" in \#*) continue ;; esac
  SECURITY_PKGS+=("$pkg")
done < "$SD/lists/security-extras.list"

step_security() {
  log "Step 2/9  Security toolset (${#SECURITY_PKGS[@]} apt packages)"
  echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
  apt-get install -y -qq "${SECURITY_PKGS[@]}" 2>/dev/null || \
  apt-get install -y -qq "${SECURITY_PKGS[@]}" || \
  warn "Some security packages not available; continuing."

  if [ ! -d /usr/share/seclists ] && command -v git >/dev/null 2>&1; then
    log "    Cloning SecLists"
    git clone -q --depth 1 https://github.com/danielmiessler/SecLists.git /usr/share/seclists 2>/dev/null || true
    chmod -R a+rX /usr/share/seclists 2>/dev/null || true
  fi
  mkdir -p /usr/share/wordlists
}

###############################################################################
# STEP 3 — HEAVY / EXTERNAL SECURITY TOOLS
###############################################################################
step_heavy() {
  log "Step 3/9  Heavyweight tools (Metasploit, Burp, pipx, snap, go)"
  apt-get install -y -qq pipx python3-venv 2>/dev/null || true
  command -v pipx >/dev/null 2>&1 || pip3 install --break-system-packages --user pipx 2>/dev/null || true
  export PATH="$PATH:$HOME/.local/bin"

  for t in responder netexec impacket sherlock pwntools volatility3 arjun dalfox; do
    pipx install --system-site-packages "$t" > /dev/null 2>&1 || true
  done

  # amass / zaproxy / gh via snap (best-effort)
  if command -v snap >/dev/null 2>&1; then
    snap install amass --classic      > /dev/null 2>&1 || true
    snap install zaproxy --classic    > /dev/null 2>&1 || true
    snap install gh --classic         > /dev/null 2>&1 || true
  fi

  # Metasploit (official Rapid7 repo installer)
  if ! command -v msfconsole >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/rapid7/metasploit-framework/master/msfinstall -o /tmp/msfinstall 2>/dev/null || true
    chmod +x /tmp/msfinstall 2>/dev/null || true
    /tmp/msfinstall > /dev/null 2>&1 || true
  fi

  # Burp Suite Community
  if ! command -v burpsuite >/dev/null 2>&1; then
    curl -fsSL "https://portswigger-cdn.net/burp/releases/download?product=community&version=2025.5.4&type=Linux" -o /tmp/burpsuite.deb 2>/dev/null || true
    [ -s /tmp/burpsuite.deb ] && apt-get install -y -qq /tmp/burpsuite.deb > /dev/null 2>&1 || true
  fi

  # Go ProjectDiscovery tools
  if command -v go >/dev/null 2>&1; then
    export GOPATH=/root/go GOBIN=/usr/local/bin
    for g in "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest" \
             "github.com/projectdiscovery/httpx/cmd/httpx@latest" \
             "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" \
             "github.com/projectdiscovery/katana/cmd/katana@latest"; do
      go install -v "$g" > /dev/null 2>&1 || true
    done
    ln -sf /root/go/bin/* /usr/local/bin/ 2>/dev/null || true
  fi

  [ "$KALI_CONTAINER" = "yes" ] && {
    log "    Baking in Kali container (long step)"
    apt-get install -y -qq docker.io docker-compose-v2 2>/dev/null || true
    systemctl enable docker 2>/dev/null || true
    docker pull kalilinux/kali-rolling > /dev/null 2>&1 || true
  }

  # 'kali' runner
  if [ "$KALI_CONTAINER" = "yes" ]; then
    cat > /usr/local/bin/kali <<'EOF'
#!/bin/bash
[ $# -eq 0 ] && set -- bash
docker run --rm -it --network host -v "$PWD:/work" -w /work kalilinux/kali-rolling "$@"
EOF
  else
    cat > /usr/local/bin/kali <<'EOF'
#!/bin/bash
echo "Full Kali toolset: docker run --rm -it --network host kalilinux/kali-rolling <tool>"
echo "Or rebuild with KALI_CONTAINER=yes to bake it in permanently."
EOF
  fi
  chmod +x /usr/local/bin/kali
}

###############################################################################
# STEP 4 — DEVELOPER TOOLCHAIN + VS CODE
###############################################################################
DEV_PKGS=(
  build-essential gcc g++ make cmake python3 python3-pip python3-venv
  python-is-python3 git gitk curl wget jq ripgrep fd-find tmux neovim vim nano
  nodejs npm golang openjdk-21-jdk docker.io docker-compose-v2 code
  sqlite3 sqlitebrowser postgresql libpq-dev mysql-client sshfs openssh-client
  gnupg htop btop tree locate sshpass rsync zsh zsh-autosuggestions
  zsh-syntax-highlighting xclip xsel git-lfs jupyter-notebook valgrind
  httpie virt-manager qemu-system-x86 debootstrap fzf bat duf ncdu zoxide
  texlive-latex-base texlive-latex-extra systemd-container
)
[ -f "$SD/lists/dev-tools.list" ] && while read -r pkg; do
  [ -z "$pkg" ] && continue; case "$pkg" in \#*) continue ;; esac
  DEV_PKGS+=("$pkg")
done < "$SD/lists/dev-tools.list"

step_dev() {
  log "Step 4/9  Dev toolchain + VS Code (${#DEV_PKGS[@]} packages)"
  apt-get install -y -qq "${DEV_PKGS[@]}" 2>/dev/null || \
  apt-get install -y -qq "${DEV_PKGS[@]}" || \
  warn "Some dev packages failed; VS Code retried alone."
  apt-get install -y -qq code 2>/dev/null || true          # VS Code explicitly

  getent group docker >/dev/null 2>&1 || groupadd docker 2>/dev/null || true

  if command -v npm >/dev/null 2>&1; then
    npm install -g typescript yarn pnpm live-server 2>/dev/null | tail -1 || true
  fi
  if command -v pip3 >/dev/null 2>&1; then
    pip3 install --break-system-packages -q netaddr requests beautifulsoup4 flask django numpy pandas matplotlib 2>/dev/null || true
  fi
}

###############################################################################
# STEP 5 — OPENCODE AI AGENT
###############################################################################
step_opencode() {
  log "Step 5/9  OpenCode AI agent"
  apt-get install -y -qq kitty 2>/dev/null || true

  if ! command -v opencode >/dev/null 2>&1; then
    export OPENCODE_INSTALL_DIR=/usr/local/share/opencode
    curl -fsSL https://opencode.ai/install | bash > /dev/null 2>&1 || \
    npm install -g opencode-ai@latest > /dev/null 2>&1 || true
  fi
  for b in /usr/local/share/opencode/bin/opencode "$HOME"/.opencode/bin/opencode /root/.opencode/bin/opencode /usr/local/bin/opencode; do
    [ -n "$b" ] && [ -x "$b" ] && { ln -sf "$b" /usr/local/bin/opencode 2>/dev/null || true; break; }
  done
  hash -r 2>/dev/null || true
  command -v opencode >/dev/null 2>&1 \
    && log "    OpenCode ready" \
    || warn "OpenCode not found - install after boot with 'curl -fsSL https://opencode.ai/install | bash'"

  mkdir -p /etc/skel/.config/opencode
  cat > /etc/skel/.config/opencode/opencode.json <<'EOF'
{
  "$schema": "https://opencode.ai/config-schema.json",
  "theme": "dark",
  "autoupdate": false,
  "cache": true,
  "_comment": "Add your provider + API key here, or run 'opencode auth'."
}
EOF
  [ -f "$SD/branding/skel/AGENTS.md" ] && cp "$SD/branding/skel/AGENTS.md" /etc/skel/AGENTS.md 2>/dev/null || true
}

###############################################################################
# STEP 6 — GAMING (Steam / Wine / Proton)
###############################################################################
GAME_PKGS=(
  steam-installer wine winetricks gamemode libgamemode0 libgamemodeauto0
  mangohud gamescope libgl1-mesa-dri libgl1-mesa-dri:i386 libgl1-mesa-glx
  libgl1-mesa-glx:i386 libvulkan1 libvulkan1:i386 mesa-vulkan-drivers
  mesa-vulkan-drivers:i386 vulkan-tools libasound2-plugins:i386 libpulse0:i386
  libsdl2-2.0-0 libsdl2-2.0-0:i386 libx11-6:i386 libxrandr2:i386
  libxrender1:i386 libxi6:i386 libxtst6:i386 libxcursor1:i386
  libxinerama1:i386 libxext6:i386 libxfixes3:i386 libgtk-x11-2.0-0:i386
  libgdk-pixbuf-2.0-0:i386 libdbus-1-3:i386 libsqlite3-0:i386 libstdc++6:i386
  libc6:i386 libcurl4:i386 libpipewire-0.3-0:i386 libopenal1 libopenal1:i386
  libfreetype6:i386 zlib1g:i386 libnss3:i386 libxss1:i386 lib32gcc-s1
  mesa-va-drivers mesa-vdpau-drivers intel-media-va-driver
  gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
  gstreamer1.0-libav pipewire-pulse wireplumber linux-tools-common
  linux-tools-generic
)
[ -f "$SD/lists/gaming-libs.list" ] && while read -r pkg; do
  [ -z "$pkg" ] && continue; case "$pkg" in \#*) continue ;; esac
  GAME_PKGS+=("$pkg")
done < "$SD/lists/gaming-libs.list"

step_gaming() {
  log "Step 6/9  Gaming stack (Steam, Wine, Proton)"
  if [ "$LITE" = "1" ]; then
    GAME_PKGS=( steam-installer mangohud gamemode libgamemode0 libgamemodeauto0 \
                mesa-vulkan-drivers libvulkan1 libvulkan1:i386 wine winetricks )
  fi
  apt-get install -y -qq "${GAME_PKGS[@]}" 2>/dev/null || \
  apt-get install -y -qq "${GAME_PKGS[@]}" || \
  warn "Some gaming packages failed; continuing."
  # prefer official Valve steam-launcher if repo available
  apt-get install -y -qq steam-launcher 2>/dev/null || true

  if command -v flatpak >/dev/null 2>&1; then
    flatpak install -y --noninteractive flathub net.lutris.Lutris > /dev/null 2>&1 || true
    flatpak install -y --noninteractive flathub net.davidotek.pupgui2 > /dev/null 2>&1 || true
    flatpak override --user --filesystem=home net.lutris.Lutris 2>/dev/null || true
  fi
  getent group gamemode >/dev/null 2>&1 || groupadd gamemode 2>/dev/null || true

  cat > /usr/local/bin/chigos-run <<'EOF'
#!/bin/bash
# chigos-run "game command"  -> GameMode + MangoHud HUD
[ "$1" = "--plain" ] && { shift; exec "$@"; }
exec gamemoderun mangohud "$@"
EOF
  chmod +x /usr/local/bin/chigos-run
}

###############################################################################
# STEP 7 — GPU (universal Mesa + first-boot NVIDIA helper)
###############################################################################
step_gpu() {
  log "Step 7/9  GPU base (works for AMD & Intel; NVIDIA auto at first boot)"
  apt-get install -y -qq mesa-utils linux-firmware libgl1-mesa-dri \
    mesa-vulkan-drivers libvulkan1 vulkan-tools 2>/dev/null || true

  cat > /usr/local/sbin/chigos-gpu-setup <<'EOF'
#!/bin/bash
# sudo chigos-gpu-setup  -> installs the right NVIDIA driver if present
[ "$(id -u)" -ne 0 ] && { echo "Run as root: sudo chigos-gpu-setup"; exit 1; }
if lspci -nn 2>/dev/null | grep -qi NVIDIA; then
  echo "NVIDIA detected - installing proprietary driver..."
  apt-get update -qq 2>/dev/null || true
  ubuntu-drivers install 2>/dev/null || true
  VER=$(ubuntu-drivers devices 2>/dev/null | grep -oP 'nvidia-driver-\K[0-9]+' | head -1)
  [ -n "$VER" ] && apt-get install -y -qq "nvidia-driver-$VER" "libnvidia-gl-$VER:i386" >/dev/null 2>&1 || true
  echo "Done - REBOOT, then verify with: nvidia-smi"
elif lspci -nn 2>/dev/null | grep -qiE 'AMD|ATI'; then
  echo "AMD detected - Mesa/RADV already active. Nothing to do."
else
  echo "Intel/unknown - Mesa already active."
fi
EOF
  chmod +x /usr/local/sbin/chigos-gpu-setup
}

###############################################################################
# STEP 8 — CHIGOS BRANDING + LIGHTWEIGHT GNOME
###############################################################################
step_branding() {
  log "Step 8/9  Branding + lightweight GNOME"
  mkdir -p /usr/share/backgrounds/chigos /usr/share/icons/chigos
  [ -d "$SD/branding" ] && {
    cp -f "$SD"/branding/wallpaper-*.png /usr/share/backgrounds/chigos/ 2>/dev/null || true
    cp -f "$SD"/branding/logo-chigos.png /usr/share/icons/chigos/ 2>/dev/null || true
  }

  apt-get install -y -qq yaru-theme-gnome-shell papirus-icon-theme gnome-tweaks \
    gnome-shell-extensions epiphany-browser libreoffice-writer libreoffice-calc \
    2>/dev/null || true

  # default wallpaper + performance (write gschema override directly)
  mkdir -p /usr/share/glib-2.0/schemas
  cat > /usr/share/glib-2.0/schemas/50_chigos.gschema.override <<'O'
[org.gnome.desktop.background]
picture-uri='file:///usr/share/backgrounds/chigos/wallpaper-chigos-dark.png'
picture-uri-dark='file:///usr/share/backgrounds/chigos/wallpaper-chigos-dark.png'
picture-options='zoom'
[org.gnome.desktop.interface]
color-scheme='prefer-dark'
gtk-theme='Yaru-dark'
icon-theme='Papirus-Dark'
clock-show-date=true
[org.gnome.shell]
favorite-apps=['org.gnome.Nautilus.desktop','code.desktop','org.gnome.Terminal.desktop','steam.desktop','firefox.desktop','epiphany.desktop']
[org.gnome.desktop.wm.preferences]
button-layout='appmenu:minimize,maximize,close'
O
  glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true

  # /etc/skel shell extras + MOTD
  SKEL=/etc/skel
  mkdir -p "$SKEL/.config" "$SKEL/.local/bin"
  cat > "$SKEL/.bashrc-chigos" <<'EOF'
alias ll='ls -lAhF --color=auto'; alias la='ls -AlhF --color=auto'
alias ..='cd ..'; alias c='clear'; alias gs='git status'; alias gp='git push'
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'; alias search='apt search'
alias codex='code'; alias hack='chigos-tools'
chigos-tools(){ grep -A1 "  $1:" /usr/local/share/chigos/tools.txt 2>/dev/null || cat /usr/local/share/chigos/tools.txt; }
EOF
  # tools cheat-sheet
  mkdir -p /usr/local/share/chigos
  cat > /usr/local/share/chigos/tools.txt <<'EOF'
network : nmap masscan netdiscover arp-scan tcpdump wireshark hping3
web     : sqlmap ffuf gobuster nikto nuclei zaproxy burpsuite wpscan
exploit : msfconsole hydra john hashcat medusa netexec responder
osint   : theHarvester sherlock enum4linux whois dnsrecon amass
wireless: aircrack-ng wifite kismet hcxtools reaver pixiewps
forensic: autopsy sleuthkit foremost binwalk exiftool ghidra
reversing: gdb radare2 rizin strace ltrace objdump
EOF
  chmod -R a+rX /usr/local/share/chigos
  if ! grep -q "bashrc-chigos" "$SKEL/.bashrc" 2>/dev/null; then
    echo '[ -f "$HOME/.bashrc-chigos" ] && . "$HOME/.bashrc-chigos"' >> "$SKEL/.bashrc"
  fi

  cat > /etc/motd <<'EOF'


    ██████╗ ██╗  ██╗██╗ ██████╗  ██████╗ ███████╗
   ██╔════╝ ██║  ██║██║██╔════╝ ██╔═══██╗██╔════╝
   ██║      ███████║██║██║  ███╗██║   ██║███████╗
   ██║      ██╔══██║██║██║   ██║██║   ██║╚════██║
   ╚██████╗ ██║  ██║██║╚██████╔╝╚██████╔╝███████║
    ╚═════╝ ╚═╝  ╚═╝╚═╝ ╚═════╝  ╚═════╝ ╚══════╝

   Chigos OS - light Linux for CS students.
   opencode | chigos-tools | sudo chigos-gpu-setup | steam

EOF
  grep -q "cat /etc/motd" "$SKEL/.bashrc" 2>/dev/null || echo '[ -f /etc/motd ] && cat /etc/motd' >> "$SKEL/.bashrc"
  grep -q "cat /etc/motd" /etc/bash.bashrc 2>/dev/null || echo '[ -f /etc/motd ] && cat /etc/motd' >> /etc/bash.bashrc
}

###############################################################################
# STEP 9 — LIGHTWEIGHT TUNING + CLEANUP
###############################################################################
step_lean() {
  log "Step 9/9  Lightweight tuning + cleanup"
  # no background indexers on 8 GB RAM laptops
  for svc in localsearch-3.service localsearch.service tracker-miner-fs-3.service; do
    systemctl disable "$svc" 2>/dev/null || true
  done
  mkdir -p "${XDG_CONFIG_HOME:-/root/.config}"
  mkdir -p /etc/xdg/autostart
  printf 'vm.swappiness=10\nvm.vfs_cache_pressure=50\n' > /etc/sysctl.d/99-chigos.conf
  sysctl -w vm.swappiness=10 vm.vfs_cache_pressure=50 2>/dev/null || true

  apt-get autoremove -y -qq 2>/dev/null || true
  apt-get autoclean -y -qq 2>/dev/null || true
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb 2>/dev/null || true

  PKGS=$(dpkg-query -W -f='${binary:Package}\n' 2>/dev/null | wc -l)
  log "Done! ~$PKGS packages. ISO estimate: 6-9 GB (zstd), ~4 GB with CHIGOS_LITE=1."
  if [ "$MODE" = "chroot" ]; then
    log "In Cubic: click Next -> keep packages -> options (Volume ID 'Chigos 24.04 LTS amd64') -> zstd -> Generate."
  fi
  exit 0
}

###############################################################################
# RUN
###############################################################################
log "Chigos OS build started - $(date -Iseconds) (mode=$MODE lite=$LITE)"
step_repos
step_security
step_heavy
step_dev
step_opencode
step_gaming
step_gpu
step_branding
step_lean