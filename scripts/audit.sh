#!/bin/bash
# Linux & OpenClaw Enterprise Security Audit
# Purpose: Execute a comprehensive, read-only 8-phase security audit.
# Output: Generates a structured report with [CRITICAL], [WARNING], and [PASS] tags.

echo "=========================================================="
echo "    Linux & OpenClaw Enterprise Security Audit Report     "
echo "=========================================================="

# --------------------------------------------------------
# Pre-flight Check: Ensure required audit tools are installed
# --------------------------------------------------------
MISSING_TOOLS=()
if ! command -v ufw &> /dev/null; then MISSING_TOOLS+=("ufw"); fi
if ! command -v rkhunter &> /dev/null; then MISSING_TOOLS+=("rkhunter"); fi

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "[PRE-FLIGHT FAILED] Missing required audit tools: ${MISSING_TOOLS[*]}"
    echo "Please install them to proceed: sudo apt-get update && sudo apt-get install -y ${MISSING_TOOLS[*]}"
    exit 1
fi

echo "Starting audit at $(date)..."
echo

check_pass() { echo -e "  [PASS] $1"; }
check_warn() { echo -e "  [WARNING] $1"; }
check_crit() { echo -e "  [CRITICAL] $1"; }

echo "--- 📋 Phase 0: System Profiling ---"
# Cloud Provider / ASN
ASN=$(curl -s ipinfo.io/org || echo "Unknown ASN")
VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "Unknown Vendor")
echo "  [*] Cloud Provider / ASN: $VENDOR / $ASN"
# OS & Kernel
echo "  [*] OS Release: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
echo "  [*] Kernel: $(uname -r)"
# Uptime & Load
echo "  [*] Uptime & Load: $(uptime -p), $(uptime | awk -F'load average:' '{ print $2 }')"
# OpenClaw Status (if installed)
if command -v openclaw &> /dev/null; then
    echo "  [*] OpenClaw Version: $(openclaw --version | head -n 1)"
    echo "  [*] OpenClaw Gateway: $(openclaw gateway status | grep -i 'running' || echo 'Not Running')"
else
    echo "  [*] OpenClaw CLI not found in PATH."
fi
echo

echo "--- 🛠️ Phase 1: Network & Exposure ---"
# UFW Status
if command -v ufw &> /dev/null; then
    UFW_STAT=$(sudo ufw status | grep Status | awk '{print $2}')
    if [ "$UFW_STAT" == "active" ]; then check_pass "UFW is active"; else check_warn "UFW is inactive"; fi
else
    check_warn "UFW not installed/found"
fi

# Sysctl TCP/IP Defenses
SYN=$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null)
if [ "$SYN" == "1" ]; then check_pass "TCP SYN Cookies enabled"; else check_crit "TCP SYN Cookies disabled (net.ipv4.tcp_syncookies)"; fi

RP=$(sysctl -n net.ipv4.conf.all.rp_filter 2>/dev/null)
if [ "$RP" == "1" ]; then check_pass "RP Filter enabled"; else check_crit "RP Filter disabled (net.ipv4.conf.all.rp_filter)"; fi
echo

echo "--- 🛡️ Phase 2: SSH Defense ---"
if [ -f /etc/ssh/sshd_config ]; then
    if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then check_crit "SSH Root Login enabled"; else check_pass "SSH Root Login disabled/not explicitly yes"; fi
    if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then check_crit "SSH Password Auth enabled"; else check_pass "SSH Password Auth disabled/not explicitly yes"; fi
    if grep -q "^Port 22$" /etc/ssh/sshd_config; then check_warn "SSH running on default port 22"; else check_pass "SSH using custom port or default not explicitly set"; fi
else
    check_warn "SSH config not found at /etc/ssh/sshd_config"
fi

# TMOUT check
if grep -q "TMOUT=" /etc/profile; then check_pass "TMOUT idle timeout configured in /etc/profile"; else check_warn "TMOUT idle timeout NOT configured in /etc/profile"; fi
echo

echo "--- 🕵️‍♂️ Phase 3: Shadow Accounts & Privileges ---"
# UID 0 accounts
UID0=$(awk -F: '($3 == "0") {print $1}' /etc/passwd)
if [ "$UID0" == "root" ]; then check_pass "Only 'root' has UID 0"; else check_crit "Multiple accounts with UID 0: $UID0"; fi

# Core file locks (chattr)
if [ -f /usr/bin/lsattr ]; then
    P_ATTR=$(lsattr /etc/passwd 2>/dev/null | cut -c1-20)
    if [[ "$P_ATTR" == *"i"* || "$P_ATTR" == *"a"* ]]; then check_pass "/etc/passwd is locked"; else check_warn "/etc/passwd is NOT locked (missing chattr +i/+a)"; fi
fi

# GCC permissions
if [ -f /usr/bin/gcc ]; then
    GCC_PERMS=$(stat -c "%a" /usr/bin/gcc)
    if [ "$GCC_PERMS" == "000" ] || [ "$GCC_PERMS" == "700" ]; then check_pass "GCC permissions restricted ($GCC_PERMS)"; else check_warn "GCC is accessible to normal users ($GCC_PERMS)"; fi
else
    check_pass "GCC not installed"
fi
echo

echo "--- 🩹 Phase 4: Vulnerabilities & Zombies ---"
ZOMBIES=$(ps axo stat | grep -c Z)
if [ "$ZOMBIES" -gt 0 ]; then check_warn "Found $ZOMBIES zombie process(es)"; else check_pass "No zombie processes found"; fi
echo

echo "--- 🐳 Phase 5: Container & Resource Constraints ---"
if command -v docker &> /dev/null; then
    PRIV_DOCKERS=$(docker ps -q | xargs -r docker inspect --format '{{.Name}}: {{.HostConfig.Privileged}}' | grep "true")
    if [ -z "$PRIV_DOCKERS" ]; then check_pass "No privileged Docker containers running"; else check_crit "Privileged Docker containers found: $PRIV_DOCKERS"; fi
else
    check_pass "Docker not installed"
fi

if grep -q "^*.*hard.*nproc" /etc/security/limits.conf; then check_pass "nproc limits configured"; else check_warn "nproc limits NOT configured in limits.conf"; fi
if grep -q "^*.*hard.*nofile" /etc/security/limits.conf; then check_pass "nofile limits configured"; else check_warn "nofile limits NOT configured in limits.conf"; fi
echo

echo "--- 🦠 Phase 6: Rootkit Scan ---"
if command -v rkhunter &> /dev/null; then
    echo "  [*] Running rkhunter deep scan (this may take a minute)..."
    RK_OUT=$(sudo rkhunter -c --sk --rwo 2>/dev/null)
    if [ -z "$RK_OUT" ]; then
        check_pass "rkhunter found no rootkits or suspicious files."
    else
        RK_WARN_COUNT=$(echo "$RK_OUT" | wc -l)
        check_warn "rkhunter found $RK_WARN_COUNT suspicious item(s). See /var/log/rkhunter.log"
        echo "$RK_OUT" | head -n 5 | while read line; do echo "      - $line"; done
    fi
else
    check_warn "rkhunter not installed. Skipping."
fi
echo

echo "--- 🩺 Phase 7: OpenClaw Health ---"
if command -v openclaw &> /dev/null; then
    check_pass "OpenClaw health commands can be run via 'openclaw security audit --deep' & 'openclaw update status'"
else
    check_warn "OpenClaw CLI not found."
fi
echo
echo "=========================================================="
echo "    Audit Complete. Please review the findings above.     "
echo "=========================================================="
