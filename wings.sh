#!/usr/bin/env bash
# ==================================================
# PTERODACTYL WINGS AUTO INSTALLER
# UI: Clean / Theme: Cyan & Red / Feature: Safe Logging
# ==================================================

# ---------------- LOGGING SETUP ----------------
LOG_FILE="/root/wings.log"
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="./wings.log"

# ---------------- UI THEME ----------------
C_RESET="\e[0m"
C_RED="\e[1;31m"
C_GREEN="\e[1;32m"
C_YELLOW="\e[1;33m"
C_BLUE="\e[1;34m"
C_PURPLE="\e[1;35m"
C_CYAN="\e[1;36m"
C_WHITE="\e[1;37m"
C_GRAY="\e[1;90m"

line(){ echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"; }
step(){ echo -e "${C_BLUE}➜ $1${C_RESET}"; }
ok(){ echo -e "${C_GREEN}✔ $1${C_RESET}"; }
warn(){ echo -e "${C_YELLOW}⚠ $1${C_RESET}"; }

execute() {
    local msg="$1"
    local cmd="$2"
    
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] STARTING: $msg" >> "$LOG_FILE"
    echo -ne "${C_BLUE}⏳ ${msg}...${C_RESET}"
    
    eval "$cmd" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    tput civis
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 9); do
            echo -ne "${C_CYAN}${spin:$i:1}${C_RESET}\b"
            sleep 0.1
        done
    done
    tput cnorm
    
    wait $pid
    local status=$?
    
    if [ $status -eq 0 ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $msg" >> "$LOG_FILE"
        echo -e "\r${C_GREEN}✔ ${msg} Finished!${C_RESET}"
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] FAILED: $msg (Exit: $status)" >> "$LOG_FILE"
        echo -e "\r${C_RED}✘ ${msg} Failed! Check $LOG_FILE${C_RESET}"
        exit 1
    fi
}

banner(){
clear
echo -e "${C_CYAN}"
cat << "EOF"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ██╗    ██╗██╗███╗   ██╗ ██████╗ ███████╗
  ██║    ██║██║████╗  ██║██╔════╝ ██╔════╝
  ██║ █╗ ██║██║██╔██╗ ██║██║  ███╗███████╗
  ██║███╗██║██║██║╚██╗██║██║   ██║╚════██║
  ╚███╔███╔╝██║██║ ╚████║╚██████╔╝███████║
   ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝                                     
               WINGS INSTALLATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
echo -e "${C_RESET}"
}

# ---------------- PRE-CHECKS ----------------
if [[ $EUID -ne 0 ]]; then
   echo -e "${C_RED}Error: You must run this script as root.${C_RESET}"
   exit 1
fi

# ---------------- START ----------------
banner

step "Phase 1: Environment Setup"
execute "Installing Docker" "curl -sSL https://get.docker.com/ | CHANNEL=stable bash"
execute "Enabling Docker Service" "systemctl enable --now docker"

step "Phase 2: System Optimization"
GRUB_FILE="/etc/default/grub"
if [ -f "$GRUB_FILE" ]; then
    execute "Updating GRUB (Swap Support)" "sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"swapaccount=1\"/' $GRUB_FILE && update-grub"
fi

step "Phase 3: Wings Installation"
execute "Creating Directories" "mkdir -p /etc/pterodactyl"

ARCH=$(uname -m)
[ "$ARCH" == "x86_64" ] && W_ARCH="amd64" || W_ARCH="arm64"

execute "Downloading Wings Binary ($W_ARCH)" "curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$W_ARCH && chmod u+x /usr/local/bin/wings"

step "Phase 4: Service Configuration"
execute "Creating Systemd Service" "printf '[Unit]\nDescription=Pterodactyl Wings Daemon\nAfter=docker.service\nRequires=docker.service\nPartOf=docker.service\n\n[Service]\nUser=root\nWorkingDirectory=/etc/pterodactyl\nLimitNOFILE=4096\nPIDFile=/var/run/wings/daemon.pid\nExecStart=/usr/local/bin/wings\nRestart=on-failure\nStartLimitInterval=180\nStartLimitBurst=30\nRestartSec=5s\n\n[Install]\nWantedBy=multi-user.target' > /etc/systemd/system/wings.service && systemctl daemon-reload && systemctl enable wings"

step "Phase 5: SSL Generation"
execute "Generating SSL Certificates" "mkdir -p /etc/certs/wing && openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj '/C=NA/ST=NA/L=NA/O=NA/CN=Node' -keyout /etc/certs/wing/privkey.pem -out /etc/certs/wing/fullchain.pem"

step "Phase 6: Helper Commands"
execute "Creating 'wing' Helper" "printf '#!/bin/bash\necho -e \"\\\e[1;33mℹ️  Wings Helper Command\\\e[0m\"\necho -e \"\\\e[1;36mStart:\\\e[0m sudo systemctl start wings\"\necho -e \"\\\e[1;36mStatus:\\\e[0m sudo systemctl status wings\"\necho -e \"\\\e[1;36mLogs:\\\e[0m sudo journalctl -u wings -f\"' > /usr/local/bin/wing && chmod +x /usr/local/bin/wing"

# ---------------- AUTO CONFIG ----------------
line
echo -e "${C_YELLOW}🔧 AUTO-CONFIGURATION${C_RESET}"
read -p "Do you want to configure Wings now? (y/N): " AUTO_CONFIG

if [[ "$AUTO_CONFIG" =~ ^[Yy]$ ]]; then
    step "Configuration Gathering"
    read -p "Enter UUID: " UUID
    read -p "Enter Token ID: " TOKEN_ID
    read -p "Enter Token: " TOKEN
    read -p "Enter Panel URL (e.g., https://panel.example.com): " REMOTE

    execute "Writing Config File" "printf 'debug: false\nuuid: ${UUID}\ntoken_id: ${TOKEN_ID}\ntoken: ${TOKEN}\napi:\n  host: 0.0.0.0\n  port: 8080\n  ssl:\n    enabled: true\n    cert: /etc/certs/wing/fullchain.pem\n    key: /etc/certs/wing/privkey.pem\n  upload_limit: 100\nsystem:\n  data: /var/lib/pterodactyl/volumes\n  sftp:\n    bind_port: 2022\nallowed_mounts: []\nremote: \"${REMOTE}\"' > /etc/pterodactyl/config.yml"
    
    execute "Starting Wings" "systemctl start wings"
    ok "Wings is now configured and online!"
else
    warn "Auto-configuration skipped. Use 'wing' command for instructions."
fi

line
echo -e "${C_GREEN}🎉 WINGS INSTALLATION COMPLETE${C_RESET}"
echo -e "${C_GRAY}Log file: $LOG_FILE${C_RESET}"
line
