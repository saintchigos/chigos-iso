# AGENTS.md — guidance for AI coding agents (OpenCode) on Chigos OS

You are operating inside **Chigos OS**, a Linux distribution for computer-science
students. The system ships a full security/hacking toolset, OpenCode, and gaming.

## Environment rules
- This is a **Linux (Debian/Ubuntu-based)** system. Use `bash`, not PowerShell.
- Prefer existing tools already installed. Huge lists of CTF/pentest tooling exist.
- Do not install new software without asking; the base system is deliberately lean-ish.

## Preferred tools by task
- Package management: `apt` (system), `snap` (classic, e.g. amass, zaproxy),
  `pipx` (Python CLIs), `go install` (Go CLIs).
- Network recon: `nmap`, `masscan`, `netdiscover`, `arp-scan`.
- Web testing: `sqlmap`, `ffuf`, `gobuster`, `nikto`, `nuclei`, `zaproxy`, `burpsuite`.
- Exploitation: `msfconsole` (Metasploit), `metasploit-framework`, `hydra`, `john`, `hashcat`.
- Forensics: `autopsy`, `sleuthkit`, `foremost`, `binwalk`, `strings`, `exiftool`.
- Reverse engineering: `gdb`, `radare2`, `rizin`, `ghidra`.
- CTF/scripting: `python3`, `pwntools`, `scapy`, `impacket`.
- Gaming debugging: `mangohud`, `gamescope`, `gamemoderun`.

## Conventions
- Return concise, actionable answers. Show commands when relevant.
- When you modify files, keep edits minimal and reversible (prefer git).
- Respect /etc/skel templates; user customizations live in `$HOME`.

## Safety
- If the user asks to hack a target, ensure they own it or have written permission.
- Prefer non-destructive audit commands over attacks by default.